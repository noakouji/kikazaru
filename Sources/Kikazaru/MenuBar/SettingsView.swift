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
            about
            Divider()
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
                Text(L10n.t("話している間だけ、部屋のBGMを下げます",
                            "Turns the room down while you talk"))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("なぜ必要か", "Why this exists"), systemImage: "questionmark.circle")
                .font(.headline)
            md(L10n.t("""
                Aqua Voice などの音声入力アプリは、録音中に **Mac につながったスピーカー** の音を \
                自動で下げてくれます。

                ところが **Sonos のようなネットワークスピーカーには効きません**。\
                音を鳴らしているのが Mac ではなく Sonos 本体だからです。

                結果、音楽が流れたままマイクに回り込み、歌詞や BGM が文字起こしに混ざります。
                """, """
                Dictation apps like Aqua Voice automatically lower **speakers connected to your Mac** \
                while recording.

                But this **does not work for network speakers like Sonos**, because the audio is \
                played by the speaker itself, not by your Mac.

                The music keeps playing, leaks into the microphone, and ends up in your transcript.
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)

            Divider()

            Label(L10n.t("どう解決するか", "How it works"), systemImage: "checkmark.circle")
                .font(.headline)
            md(L10n.t("""
                マイクが使われ始めたことを検知して、**スピーカー側の音量を直接下げます**。\
                話し終われば元の音量に戻ります。

                ヘッドホンに切り替えなくても、スピーカーで音楽を流したまま音声入力できます。
                """, """
                It detects when the microphone starts being used and **lowers the speaker's own \
                volume directly**. When you stop talking, the volume comes back.

                You can keep playing music on your speakers instead of switching to headphones.
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.08)))
    }

    // MARK: - スピーカー

    private var speakerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.t("どのスピーカーを下げるか", "Which speakers to turn down"),
                  systemImage: "hifispeaker.2").font(.headline)

            Text(L10n.t("同じネットワーク上の Sonos を自動で探します。設定は要りません。",
                        "Sonos speakers on your network are found automatically. No setup needed."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            speakerList

            HStack {
                Button(L10n.t("もう一度探す", "Search again")) {
                    Task { await model?.refresh() }
                }
                .disabled(model?.isSearching ?? true)
                if model?.isSearching == true {
                    ProgressView().controlSize(.small)
                }
            }

            Toggle(L10n.t("Mac 本体の音量も一緒に下げる", "Also lower this Mac's volume"),
                   isOn: $settings.systemVolumeEnabled)
            Text(L10n.t("音声入力アプリ側で本体を下げている場合は、off のままで構いません。",
                        "Leave this off if your dictation app already lowers the Mac's volume."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var speakerList: some View {
        let rooms = model?.rooms ?? []
        if !rooms.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rooms, id: \.ip) { room in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(room.roomName)
                        Text(room.ip).font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
        } else if model?.hasSearched == true {
            VStack(alignment: .leading, spacing: 6) {
                Label(L10n.t("見つかりませんでした", "No speakers found"),
                      systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                md(L10n.t("""
                    Sonos アプリで、アカウント → プライバシーとセキュリティ → **UPnP** が \
                    有効になっているか確認してください。Mac と Sonos が同じネットワークにいる必要もあります。
                    """, """
                    In the Sonos app, check that **UPnP** is enabled under \
                    Account → Privacy and Security. Your Mac and Sonos must also be on the same network.
                    """))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.10)))
        } else {
            Text(L10n.t("探しています…", "Searching…"))
                .font(.caption).foregroundStyle(.secondary)
        }
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

            Toggle(L10n.t("メニューバーに絵文字を使う（🐵 / 🙉）",
                          "Use emoji in the menu bar (🐵 / 🙉)"),
                   isOn: $settings.useEmojiIcon)
            Text(L10n.t("off にすると、macOS 標準の見た目に合わせた単色アイコンになります。",
                        "Turn off for a monochrome icon that matches the macOS menu bar."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

enum SettingsWindow {
    @MainActor
    static func make(settings: Settings, model: AppModel?,
                     onChange: @escaping (Settings) -> Void) -> NSWindow {
        let controller = NSHostingController(
            rootView: SettingsView(settings: settings, model: model, onChange: onChange))
        let window = NSWindow(contentViewController: controller)
        window.title = "Kikazaru"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 470, height: 640))
        window.center()
        return window
    }
}
