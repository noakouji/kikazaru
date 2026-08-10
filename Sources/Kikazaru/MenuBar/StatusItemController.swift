import AppKit

/// メニューバーのアイコンとメニュー。
///
/// アイコンで待機中・ダッキング中が一目で分かるようにする。
@MainActor
final class StatusItemController {

    private let statusItem: NSStatusItem
    private let coordinator: Coordinator
    private var settings: Settings
    private var settingsWindow: NSWindow?

    init(coordinator: Coordinator, settings: Settings) {
        self.coordinator = coordinator
        self.settings = settings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        rebuildMenu()

        coordinator.onStateChange = { [weak self] state in
            self?.updateIcon(for: state)
            self?.rebuildMenu()
        }
    }

    // MARK: - 表示

    private func configureButton() {
        updateIcon(for: .idle)
        statusItem.button?.toolTip = "Kikazaru — 話している間だけ部屋のスピーカーを黙らせます"
    }

    private func updateIcon(for state: Coordinator.State) {
        statusItem.button?.image = AppIcon.menuBar(ducked: state == .ducked)
    }

    // MARK: - メニュー

    func rebuildMenu() {
        let menu = NSMenu()

        let status = coordinator.state == .ducked ? "🔉 ダッキング中" : "⚪️ 待機中"
        menu.addItem(disabled(coordinator.isEnabled ? status : "⏸ 停止中"))
        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: coordinator.isEnabled ? "一時停止" : "再開",
            action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())
        menu.addItem(disabled("対象のスピーカー"))
        let rooms = sonosAction?.currentRooms ?? []
        if rooms.isEmpty {
            menu.addItem(disabled("　　見つかりません"))
        } else {
            for room in rooms {
                menu.addItem(disabled("　　\(room.roomName)"))
            }
        }

        let refresh = NSMenuItem(
            title: "スピーカーを再検出", action: #selector(refreshRooms), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)

        menu.addItem(.separator())
        let prefs = NSMenuItem(title: "設定…", action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let quit = NSMenuItem(title: "Kikazaru を終了", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private var sonosAction: SonosAction? {
        coordinator.actionsForDisplay.compactMap { $0 as? SonosAction }.first
    }

    // MARK: - 操作

    @objc private func toggleEnabled() {
        coordinator.setEnabled(!coordinator.isEnabled)
        rebuildMenu()
    }

    @objc private func refreshRooms() {
        Task { @MainActor in
            await sonosAction?.refreshRooms()
            rebuildMenu()
        }
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow.make(settings: settings) { [weak self] updated in
                guard let self else { return }
                self.settings = updated
                updated.save()
                self.coordinator.update(settings: updated)
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
