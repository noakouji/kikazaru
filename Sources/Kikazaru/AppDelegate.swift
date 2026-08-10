import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var coordinator: Coordinator?
    private var statusItem: StatusItemController?
    private var model: AppModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = Settings.load()

        let sonos = SonosAction()
        var actions: [DuckAction] = [sonos]
        if settings.systemVolumeEnabled {
            actions.append(SystemVolumeAction())
        }

        let model = AppModel(sonos: sonos)
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
}
