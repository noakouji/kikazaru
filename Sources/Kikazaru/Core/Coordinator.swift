import Foundation

/// トリガーとアクションをつなぐ状態機械。
///
///   マイクON        → 下げる
///   ホットキー解放   → 即座に戻す（温存時間を待たずに短絡させる）
///   マイクOFF       → 猶予後に戻す（保険。ホットキーが効かない場合もここで必ず戻る）
///
/// 猶予を挟むのは、発話の切れ目でマイクが一瞬閉じて即再オープンすることがあるため。
/// 猶予なしでは音量が上下にばたつく。
@MainActor
final class Coordinator {

    enum State { case idle, ducked }

    private(set) var state: State = .idle
    private(set) var isEnabled = true

    /// いま音量を変える原因になっているアプリ（表示用）
    private(set) var activeApp: String?
    /// いまミュートしているか（表示用）
    private(set) var isMuting = false

    /// マイクを使ったアプリを見つけたときに呼ばれる
    var onAppsSeen: (([String]) -> Void)?

    var onStateChange: ((State) -> Void)?

    /// メニュー表示のために外から参照する用
    var actionsForDisplay: [DuckAction] { actions }

    private let actions: [DuckAction]
    private let mic = MicMonitor()
    private var hotkey: HotkeyMonitor?

    private var releaseTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private var settings: Settings

    init(actions: [DuckAction], settings: Settings) {
        self.actions = actions
        self.settings = settings
    }

    // MARK: - 起動 / 停止

    func start() async {
        await recoverFromPreviousRun()
        await refreshTargets()

        mic.start { [weak self] active in
            Task { @MainActor in
                active ? self?.handleMicOn() : self?.handleMicOff()
            }
        }
        startPeriodicRefresh()
        applyHotkeySetting()
    }

    func shutdown() async {
        releaseTask?.cancel()
        refreshTask?.cancel()
        mic.stop()
        hotkey?.stop()
        await restoreNow()
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if !enabled {
            Task { await restoreNow() }
        }
    }

    /// 設定変更を反映する。ホットキーの有効・無効もここで切り替わる。
    func update(settings newValue: Settings) {
        settings = newValue
        applyHotkeySetting()
    }

    // MARK: - トリガー処理

    private func handleMicOn() {
        releaseTask?.cancel()
        releaseTask = nil
        guard isEnabled, state == .idle else { return }

        // 誰がマイクを使っているかで下げ方を変える。
        // 音声入力なら少し下げるだけ、会議なら完全に黙らせる。
        let users = MicUsers.active()
        if !users.isEmpty { onAppsSeen?(users) }
        let modes = users.map { settings.mode(for: $0) }
        isMuting = modes.contains(.mute)
        activeApp = users.first.map { AppPresets.name(for: $0) }

        state = .ducked
        onStateChange?(state)
        Task { await duckNow() }
    }

    private func handleMicOff() {
        guard state == .ducked else { return }
        scheduleRestore(after: settings.releaseDelay)
    }

    /// ホットキーが離された（またはトグルで終了した）ときの短絡。
    /// マイクがまだ開いていても、待たずに戻す。
    private func handleHotkeyRelease() {
        guard state == .ducked else { return }
        scheduleRestore(after: 0)
    }

    private func scheduleRestore(after delay: TimeInterval) {
        releaseTask?.cancel()
        releaseTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
            await self?.restoreNow()
        }
    }

    // MARK: - アクション実行

    private func duckNow() async {
        let ratio = isMuting ? 0 : settings.duckRatio
        await withTaskGroup(of: Void.self) { group in
            for action in actions {
                group.addTask { await action.duck(ratio: ratio) }
            }
        }
        persistSnapshots()
    }

    private func restoreNow() async {
        await withTaskGroup(of: Void.self) { group in
            for action in actions {
                group.addTask { await action.restore() }
            }
        }
        StateStore.clear()
        if state != .idle {
            state = .idle
            isMuting = false
            activeApp = nil
            onStateChange?(state)
        }
    }

    private func persistSnapshots() {
        var all: [String: [String: Int]] = [:]
        for action in actions where !action.snapshot().isEmpty {
            all[action.name] = action.snapshot()
        }
        StateStore.save(all)
    }

    // MARK: - 復旧と追従

    /// 前回が異常終了で、音量が下がったまま残っていれば戻す。
    ///
    /// 戻せなかった分の記録は消さない。消してしまうと下がった値が「元の音量」に化け、
    /// 次に下げたときにさらに下がる、という取り返しのつかない状態になる。
    private func recoverFromPreviousRun() async {
        guard let pending = StateStore.load() else { return }
        var unresolved: [String: [String: Int]] = [:]
        for action in actions {
            guard let snapshot = pending[action.name], !snapshot.isEmpty else { continue }
            if await !action.apply(snapshot: snapshot) {
                unresolved[action.name] = snapshot
            }
        }
        if unresolved.isEmpty {
            StateStore.clear()
        } else {
            StateStore.save(unresolved)
        }
    }

    private func refreshTargets() async {
        for action in actions {
            if let speakers = action as? SpeakersAction {
                await speakers.refresh()
            }
        }
    }

    /// グループの組み替えに追従する。下げていない間だけ実行して競合を避ける。
    private func startPeriodicRefresh() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000)  // 5分
                guard let self, await self.state == .idle else { continue }
                await self.refreshTargets()
            }
        }
    }

    private func applyHotkeySetting() {
        if settings.hotkeyEnabled {
            if hotkey == nil { hotkey = HotkeyMonitor() }
            hotkey?.stop()
            hotkey?.keyCode = settings.hotkeyKeyCode
            hotkey?.start { [weak self] in
                Task { @MainActor in self?.handleHotkeyRelease() }
            }
        } else {
            hotkey?.stop()
            hotkey = nil
        }
    }
}
