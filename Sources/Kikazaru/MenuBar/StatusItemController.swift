import AppKit

/// メニューバーのアイコンとメニュー。
///
/// 状態は絵文字で表す。🐵 が待機、🙉（聞かざる）が音量を下げている状態。
/// 「ダッキング」のような専門語は使わず、何が起きているかをそのまま書く。
@MainActor
final class StatusItemController {

    private let statusItem: NSStatusItem
    private let coordinator: Coordinator
    private let model: AppModel
    private var settings: Settings
    private var settingsWindow: NSWindow?

    init(coordinator: Coordinator, model: AppModel, settings: Settings) {
        self.coordinator = coordinator
        self.model = model
        self.settings = settings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        applyAppearance(for: .idle)
        rebuildMenu()

        coordinator.onStateChange = { [weak self] state in
            self?.applyAppearance(for: state)
            self?.rebuildMenu()
        }
    }

    // MARK: - 表示

    private func applyAppearance(for state: Coordinator.State) {
        guard let button = statusItem.button else { return }
        if settings.useEmojiIcon {
            button.image = nil
            button.title = state == .ducked ? "🙉" : "🐵"
        } else {
            button.title = ""
            button.image = AppIcon.menuBar(ducked: state == .ducked)
        }
        button.toolTip = L10n.t("Kikazaru — 話している間だけ部屋のBGMを下げます",
                                "Kikazaru — turns the room down while you talk")
    }

    // MARK: - メニュー

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(disabled(statusLine))
        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: coordinator.isEnabled
                ? L10n.t("一時停止", "Pause")
                : L10n.t("再開", "Resume"),
            action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())
        menu.addItem(disabled(L10n.t("見つかったスピーカー", "Speakers found")))
        if model.rooms.isEmpty {
            menu.addItem(disabled(L10n.t("　　まだ見つかっていません", "　　None yet")))
        } else {
            for room in model.rooms {
                menu.addItem(disabled("　　\(room.roomName)"))
            }
        }

        let refresh = NSMenuItem(
            title: L10n.t("もう一度探す", "Search again"),
            action: #selector(refreshRooms), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        menu.addItem(.separator())
        let prefs = NSMenuItem(title: L10n.t("設定…", "Settings…"),
                               action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let quit = NSMenuItem(title: L10n.t("Kikazaru を終了", "Quit Kikazaru"),
                              action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    /// 何が起きているかをそのまま書く。専門語は使わない。
    private var statusLine: String {
        guard coordinator.isEnabled else {
            return L10n.t("⏸ 停止中", "⏸ Paused")
        }
        return coordinator.state == .ducked
            ? L10n.t("🙉 部屋のBGMを下げています", "🙉 Turning the room down")
            : L10n.t("🐵 待機中（BGMはそのまま）", "🐵 Idle — room untouched")
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    // MARK: - 操作

    @objc private func toggleEnabled() {
        coordinator.setEnabled(!coordinator.isEnabled)
        applyAppearance(for: coordinator.state)
        rebuildMenu()
    }

    @objc private func refreshRooms() {
        Task { @MainActor in
            await model.refresh()
            rebuildMenu()
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow.make(settings: settings, model: model) { [weak self] updated in
                guard let self else { return }
                self.settings = updated
                updated.save()
                self.coordinator.update(settings: updated)
                self.applyAppearance(for: self.coordinator.state)
                self.rebuildMenu()
            }
            settingsWindow?.isReleasedWhenClosed = false
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        Task { @MainActor in
            await coordinator.shutdown()
            NSApp.terminate(nil)
        }
    }
}
