import AppKit
import SwiftUI

/// 設定画面。
///
/// 項目を並べるだけでなく、「なぜ必要か」と「いま何が見つかっているか」を先に見せる。
/// 仕組みと現状が分からないと、どの項目をどう動かせばいいか判断できないため。
struct SettingsView: View {

    @State var settings: Settings
    @State private var hotkeyTrusted = HotkeyMonitor.isTrusted
    var model: AppModel?
    var onShowAbout: (() -> Void)?
    let onChange: (Settings) -> Void

    var body: some View {
        ScrollView { content }
            .frame(width: 470, height: 640)
            .onChange(of: settings) { _, newValue in
                L10n.override = newValue.language
                onChange(newValue)
            }
    }

    /// スクロールの中身。
    /// ScrollView はオフスクリーン描画だと中身が出ないため、確認用に分けてある。
    var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            speakerSection
            duckingSection
            hotkeySection
            Divider()
            appearanceSection
        }
        .padding(24)
        .frame(width: 470)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    /// 実行時に組み立てた文字列でも Markdown（**太字** など）を解釈させる。
    /// Text は文字列リテラルのときしか Markdown を見ないため、明示的に包む。
    private func md(_ s: String) -> Text { Text(LocalizedStringKey(s)) }

    // MARK: - ヘッダーと説明

    private var header: some View {
        HStack(spacing: 14) {
            Text("🙉").font(.system(size: 44))
            VStack(alignment: .leading, spacing: 3) {
                Text("Kikazaru").font(.title2).bold()
                Text(L10n.t("マイクがオンの間だけ、BGMを下げます",
                            "Lowers the music while your mic is on"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            Button(L10n.t("このアプリについて", "About")) { onShowAbout?() }
        }
    }

    // MARK: - スピーカー

    private var speakerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("どのスピーカーを下げるか", "Which speakers to turn down"),
                  systemImage: "hifispeaker.2").font(.headline)

            Text(L10n.t("同じネットワーク上のスピーカーを自動で探します。IP アドレスの入力は要りません。",
                        "Speakers on your network are found automatically. No IP addresses needed."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(SpeakerKind.allCases, id: \.self) { kind in
                speakerGroup(kind)
            }

            HStack(spacing: 10) {
                Button(L10n.t("もう一度探す", "Search again")) {
                    Task { await model?.refresh() }
                }
                .disabled(model?.isSearching ?? true)
                if model?.isSearching == true {
                    ProgressView().controlSize(.small)
                    Text(L10n.t("探しています…", "Searching…"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            sonosHelp

            Toggle(L10n.t("この Mac 本体の音量も一緒に下げる", "Also lower this Mac's volume"),
                   isOn: $settings.systemVolumeEnabled)
            Text(L10n.t("Bluetooth や AirPlay など、Mac から鳴らしているスピーカーはこれで下がります。",
                        "This covers anything played through the Mac, such as Bluetooth or AirPlay."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// メーカーごとのまとまり。見つかっていれば一覧、いなければその旨を出す。
    @ViewBuilder
    private func speakerGroup(_ kind: SpeakerKind) -> some View {
        let found = model?.speakers(of: kind) ?? []
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(kind.label).font(.subheadline).bold()
                if kind == .sonos {
                    badge(L10n.t("推奨", "Recommended"), color: .green)
                }
                if !kind.isVerified {
                    badge(L10n.t("実機未確認", "Untested"), color: .orange)
                }
                Spacer()
            }

            if found.isEmpty {
                Text(model?.hasSearched == true
                     ? L10n.t("見つかりませんでした", "Not found")
                     : L10n.t("探しています…", "Searching…"))
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text(L10n.t("チェックを入れたスピーカーだけ音量を下げます",
                            "Only checked speakers will be turned down"))
                    .font(.caption2).foregroundStyle(.secondary)
                ForEach(found, id: \.id) { speaker in
                    let on = model?.isEnabled(speaker) ?? true
                    HStack(spacing: 6) {
                        Toggle(isOn: Binding(
                            get: { on },
                            set: { model?.setEnabled($0, for: speaker) })
                        ) {
                            Text(speaker.name)
                        }
                        .toggleStyle(.checkbox)
                        Spacer()
                        Text(on ? L10n.t("下げる", "Will lower")
                                : L10n.t("そのまま", "Left alone"))
                            .font(.caption2)
                            .foregroundStyle(on ? Color.green : Color.secondary)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.07)))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.18)))
            .foregroundStyle(color)
    }

    /// Sonos が見つからないときの手順。専門知識なしでたどれるように番号で書く。
    private var sonosHelp: some View {
        DisclosureGroup(L10n.t("Sonos が見つからないときは", "If your Sonos is not found")) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(sonosSteps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).").font(.caption).foregroundStyle(.secondary)
                        md(step).font(.caption).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.top, 6)
        }
        .font(.caption)
    }

    private var sonosSteps: [String] {
        L10n.isJapanese ? [
            "iPhone か Android で **Sonos アプリ** を開く",
            "右下の **設定** をタップ",
            "**アカウント** → **プライバシーとセキュリティ** を開く",
            "**UPnP** をオンにする",
            "Mac と Sonos が **同じ Wi-Fi** につながっているか確認する",
            "この画面の **もう一度探す** を押す",
        ] : [
            "Open the **Sonos app** on your phone",
            "Tap **Settings**",
            "Go to **Account** → **Privacy and Security**",
            "Turn on **UPnP**",
            "Make sure your Mac and Sonos are on the **same Wi-Fi**",
            "Press **Search again** above",
        ]
    }

    // MARK: - 下げ方

    private var duckingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("下げ方", "How much, how fast"), systemImage: "speaker.wave.2")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("どれくらい下げるか", "How far to lower")).font(.subheadline)
                Slider(value: $settings.duckRatio, in: 0.05...0.8, step: 0.05)
                Text(L10n.t("元の音量の \(Int(settings.duckRatio * 100))% まで下げます",
                            "Lowers to \(Int(settings.duckRatio * 100))% of the original volume"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("いつ戻すか", "When to bring it back")).font(.subheadline)
                Slider(value: $settings.releaseDelay, in: 0.1...2, step: 0.1)
                Text(L10n.t(
                    "話し終わってから \(String(format: "%.1f", settings.releaseDelay)) 秒後に戻します",
                    "Restores \(String(format: "%.1f", settings.releaseDelay))s after you stop talking"))
                    .font(.caption).foregroundStyle(.secondary)
            }

            Text(L10n.t("短くしすぎると、話の切れ目で音量が上下にばたつきます。0.4 秒前後が目安です。",
                        "Too short and the volume flickers between phrases. Around 0.4s works well."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 高速復帰

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.t("戻りを速くする", "Bring it back faster"), systemImage: "bolt")
                .font(.headline)
            Toggle(L10n.t("ホットキーを離した瞬間に戻す", "Restore the moment you release the hotkey"),
                   isOn: $settings.hotkeyEnabled)

            md(L10n.t("""
                音声入力アプリは、話し終わってからも数秒マイクを掴んだままにします。\
                最初と最後の単語を取りこぼさないための仕様です。

                そのためマイクの状態だけを見ていると、戻るのが数秒遅れます。\
                **Aqua Voice の `fn` キーを離した瞬間**を見れば、待たずに戻せます。
                """, """
                Dictation apps keep the microphone open for a few seconds after you stop talking, \
                so the first and last words are not lost.

                Watching only the microphone therefore delays the restore. \
                Watching **the moment you release Aqua Voice's `fn` key** avoids that wait.
                """))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.hotkeyEnabled {
                Picker(L10n.t("監視するキー", "Key to watch"), selection: $settings.hotkeyKeyCode) {
                    Text(L10n.t("fn（Aqua Voice の既定）", "fn (Aqua Voice default)")).tag(Int64(63))
                    Text(L10n.t("右 Command", "Right Command")).tag(Int64(54))
                    Text(L10n.t("右 Option", "Right Option")).tag(Int64(61))
                    Text(L10n.t("右 Control", "Right Control")).tag(Int64(62))
                }
                .pickerStyle(.menu)

                if hotkeyTrusted {
                    Label(L10n.t("アクセシビリティ権限は許可済みです", "Accessibility access granted"),
                          systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text(L10n.t("アクセシビリティ権限が必要です", "Accessibility access required"))
                            .font(.caption)
                        Button(L10n.t("許可する", "Grant")) {
                            HotkeyMonitor.requestPermission()
                            hotkeyTrusted = HotkeyMonitor.isTrusted
                        }
                    }
                    Text(L10n.t("キー入力は監視するだけで、横取りも記録もしません。",
                                "Keystrokes are only observed — never intercepted or recorded."))
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 表示

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.t("表示", "Appearance"), systemImage: "gearshape").font(.headline)

            Picker(L10n.t("言語", "Language"), selection: $settings.language) {
                ForEach(L10n.Language.allCases, id: \.self) { lang in
                    Text(lang.label).tag(lang)
                }
            }
            .pickerStyle(.menu)

        }
    }
}

enum SettingsWindow {
    @MainActor
    static func make(settings: Settings, model: AppModel?,
                     onShowAbout: @escaping () -> Void,
                     onChange: @escaping (Settings) -> Void) -> NSWindow {
        let controller = NSHostingController(
            rootView: SettingsView(settings: settings, model: model,
                                   onShowAbout: onShowAbout, onChange: onChange))
        let window = NSWindow(contentViewController: controller)
        window.title = "Kikazaru"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 470, height: 640))
        window.center()
        return window
    }
}
