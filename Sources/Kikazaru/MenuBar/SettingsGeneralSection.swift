import AppKit
import SwiftUI

/// 設定画面のうち「起動とフィードバック」の部分。
///
/// 配布された人はインストールスクリプトを使えないので、
/// 自動起動の登録はアプリ自身が行えるようにしてある。
extension SettingsView {

    var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("起動", "Startup"), systemImage: "power").font(.headline)

            Toggle(L10n.t("Mac にログインしたら自動で起動する",
                          "Start automatically when I log in"),
                   isOn: Binding(
                    get: { launchAtLogin },
                    set: { launchAtLogin = $0 }))

            if LoginItem.isBlockedByUser {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(L10n.t("システム設定で許可が必要です", "Approval needed in System Settings"))
                        .font(.caption)
                    Button(L10n.t("開く", "Open")) {
                        SettingsView.openLoginItemsSettings()
                    }
                }
            }
            if let error = loginItemError {
                Text(error).font(.caption).foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider().padding(.vertical, 4)

            Label(L10n.t("困ったとき・要望", "Feedback"), systemImage: "envelope").font(.headline)
            Text(L10n.t(
                "うまく動かない、こういう機器にも対応してほしい、といったご連絡はこちらへどうぞ。使っている機器や macOS のバージョンを書いていただけると助かります。",
                "Let me know if something does not work, or if you want another device supported. Mentioning your hardware and macOS version helps a lot."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.t("要望・バグ報告を送る", "Send feedback")) {
                if let url = URL(string: Links.feedbackForm) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    static func openLoginItemsSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")
        if let url { NSWorkspace.shared.open(url) }
    }
}

/// 外部リンクの置き場。差し替えが1か所で済むようにまとめる。
enum Links {
    /// 要望・バグ報告の受け口
    static let feedbackForm =
        "https://docs.google.com/forms/d/e/1FAIpQLSefXhorrRPZcoxn_hRgREMqL48qcicouq6lu3wExYi97xUYjQ/viewform"
    /// 配布サイト
    static let website = "https://kikazaru.koji-okada.workers.dev"
}
