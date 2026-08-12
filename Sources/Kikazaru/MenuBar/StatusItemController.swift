import AppKit

/// メニューバーのアイコンとメニュー。
///
/// 状態は絵文字で表す。🐵 が待機、🙉（聞かざる）が音量を下げている状態。
/// メニューには「いま何が起きているか」と「止める・再開する」だけを置き、
/// 設定の中身は設定画面へ寄せる。項目が並ぶほど、どれを押せばいいか分からなくなるため。
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
        button.image = nil
        button.title = coordinator.isEnabled ? (state == .ducked ? "🙉" : "🐵") : "😴"
        button.toolTip = L10n.t("Kikazaru — マイクがオンの間だけBGMを下げます",
                                "Kikazaru — lowers the music while your mic is on")
    }

    // MARK: - メニュー

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(disabled(statusLine))
        menu.addItem(.separator())

        let toggle = NSMenuItem(
            title: coordinator.isEnabled
                ? L10n.t("BGMを下げるのをやめる", "Stop lowering the music")
                : L10n.t("BGMを下げるのを再開する", "Resume lowering the music"),
            action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())

        let prefs = NSMenuItem(title: L10n.t("設定…", "Settings…"),
                               action: #selector(openSettings), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        let about = NSMenuItem(title: L10n.t("このアプリについて", "About this app"),
                               action: #selector(openAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: L10n.t("Kikazaru を終了", "Quit Kikazaru"),
                              action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    /// 何が起きているかをそのまま書く。専門語は使わない。
    private var statusLine: String {
        guard coordinator.isEnabled else {
            return L10n.t("😴 いまは何もしません", "😴 Doing nothing right now")
        }
        if coordinator.state == .ducked {
            let what = coordinator.isMuting
                ? L10n.t("BGMをミュート中", "Music muted")
                : L10n.t("BGMを下げています", "Music turned down")
            if let app = coordinator.activeApp {
                return "🙉 \(what)（\(app)）"
            }
            return "🙉 \(what)"
        }
        let count = model.enabledCount
        return count > 0
            ? L10n.t("🐵 待機中・スピーカー\(count)台を見ています",
                     "🐵 Watching \(count) speaker(s)")
            : L10n.t("🐵 待機中・対象のスピーカーがありません",
                     "🐵 Watching — no speakers selected")
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

    /// 別ウインドウは増やさず、設定画面のタブを切り替えて見せる。
    @objc private func openAbout() {
        model.settingsTab = .about
        openSettings()
    }

    /// 資料用に設定ウインドウを開く。通常の操作からは呼ばれない。
    func showSettingsForCapture() {
        openSettings()
    }

    @objc private func quit() {
        Task { @MainActor in
            await coordinator.shutdown()
            NSApp.terminate(nil)
        }
    }
}
