import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var coordinator: Coordinator?
    private var statusItem: StatusItemController?
    private var model: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.terminateIfAlreadyRunning() else { return }
        var settings = Settings.load()

        // 資料用モード。実機を探さず架空の一覧を並べるので、
        // 公開する画像に自宅の部屋名が写り込まない。表示言語も固定できる。
        let isDemo = CommandLine.arguments.contains("--demo")
        if let i = CommandLine.arguments.firstIndex(of: "--lang"),
           i + 1 < CommandLine.arguments.count {
            settings.language = CommandLine.arguments[i + 1] == "en" ? .english : .japanese
            L10n.override = settings.language
        }

        let speakers = SpeakersAction()
        var actions: [DuckAction] = [speakers]
        if settings.systemVolumeEnabled {
            actions.append(SystemVolumeAction())
        }

        speakers.restoreSelection(disabled: settings.disabledSpeakerIDs,
                                  known: settings.knownSpeakerIDs)
        let model = AppModel(action: speakers)
        model.setSeenApps(settings.seenApps)
        model.onAppsChanged = { apps in
            var updated = Settings.load()
            updated.seenApps = apps
            updated.save()
        }
        model.onSelectionChange = { disabled, known in
            var updated = Settings.load()
            updated.disabledSpeakerIDs = disabled
            updated.knownSpeakerIDs = known
            updated.save()
        }
        let coordinator = Coordinator(actions: actions, settings: settings)
        self.model = model
        self.coordinator = coordinator
        statusItem = StatusItemController(coordinator: coordinator, model: model, settings: settings)

        // スピーカー探索より前に、マイクのゲインだけ先に守り始める
        coordinator.startGainLock()

        coordinator.onAppsSeen = { [weak model] apps in
            Task { @MainActor in model?.noteSeen(apps) }
        }

        Task {
            if isDemo {
                // 資料用の状態を実設定に書き戻さない。保存の口を閉じてから流し込む
                model.onSelectionChange = nil
                model.onAppsChanged = nil
                let list = DemoSpeaker.sample()
                model.loadSample(list)
                for speaker in list where speaker.kind == .googleCast {
                    model.setEnabled(false, for: speaker)
                }
                model.loadSample(list)
                model.setSeenApps(["aquavoice.macOSBridge", "com.google.Chrome", "us.zoom.xos"])
                // Settings.load() が走るたびに保存済みの言語へ戻るので、ここで指定を戻す
                L10n.override = settings.language
            } else {
                await model.refreshWithRetry()
            }
            await coordinator.start()
            statusItem?.rebuildMenu()
            // 資料用にウインドウを開いた状態で立ち上げるためのモード
            if CommandLine.arguments.contains("--show-settings") {
                statusItem?.showSettingsForCapture()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // 終了時に音量を戻す。非同期処理の完了を待つ必要があるので
        // セマフォで同期させる（ここでのブロックは終了直前の一瞬だけ）。
        guard let coordinator else { return }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await coordinator.shutdown()
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: .now() + 3)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    /// 同じアプリが既に動いていたら、こちらを終了する。
    /// メニューバーに 2 つ並ぶと、どちらが効いているのか分からなくなるため。
    private static func terminateIfAlreadyRunning() -> Bool {
        guard let id = Bundle.main.bundleIdentifier else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: id)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard !others.isEmpty else { return false }
        NSLog("Kikazaru はすでに起動しています。このプロセスを終了します。")
        NSApp.terminate(nil)
        return true
    }
}
