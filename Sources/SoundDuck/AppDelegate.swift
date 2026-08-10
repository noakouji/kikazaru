import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var coordinator: Coordinator?
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.load()

        var actions: [DuckAction] = [SonosAction()]
        if settings.systemVolumeEnabled {
            actions.append(SystemVolumeAction())
        }

        let coordinator = Coordinator(actions: actions, settings: settings)
        self.coordinator = coordinator
        statusItem = StatusItemController(coordinator: coordinator, settings: settings)

        Task {
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
}
