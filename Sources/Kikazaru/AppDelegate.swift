import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var coordinator: Coordinator?
    private var statusItem: StatusItemController?
    private var model: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.terminateIfAlreadyRunning() else { return }
        let settings = Settings.load()

        let speakers = SpeakersAction()
        var actions: [DuckAction] = [speakers]
        if settings.systemVolumeEnabled {
            actions.append(SystemVolumeAction())
        }

        speakers.restoreSelection(disabled: settings.disabledSpeakerIDs,
                                  known: settings.knownSpeakerIDs)
        let model = AppModel(action: speakers)
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

        Task {
            await model.refresh()
            await coordinator.start()
            statusItem?.rebuildMenu()
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
