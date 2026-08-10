import AppKit
import SwiftUI

/// このアプリについて。
///
/// 設定画面は設定に専念させ、「何のためのアプリか」はここで説明する。
/// 抽象的に書くと伝わらないので、実際に起きることを具体例で示す。
struct AboutView: View {

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        ScrollView { content }
            .frame(width: 520, height: 660)
    }

    /// スクロールの中身。ScrollView はオフスクリーン描画だと空になるため分けてある。
    var content: some View {
        VStack(alignment: .leading, spacing: 22) {
            header
            problem
            cause
            solution
            supported
            usage
        }
        .padding(26)
        .frame(width: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func md(_ s: String) -> Text { Text(LocalizedStringKey(s)) }

    // MARK: - ヘッダー

    private var header: some View {
        HStack(spacing: 16) {
            Text("🙉").font(.system(size: 52))
            VStack(alignment: .leading, spacing: 4) {
                Text("Kikazaru").font(.largeTitle).bold()
                Text(L10n.t("話している間だけ、部屋のBGMを下げます",
                            "Turns the room down while you talk"))
                    .foregroundStyle(.secondary)
                Text(L10n.t("バージョン \(version)", "Version \(version)"))
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    // MARK: - 具体例

    private var problem: some View {
        card(icon: "exclamationmark.bubble", title: L10n.t("こんなことが起きます", "The problem"),
             tint: .orange) {
            md(L10n.t("""
                スピーカーで音楽を流しながら、音声入力で文章を書いているとします。
                """, """
                Say you are dictating while music plays on your speakers.
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)

            example(
                spoken: L10n.t("明日の定例は10時からです", "The meeting starts at ten"),
                got: L10n.t("明日の定例は10時からです 君と歩いた あの日の",
                            "The meeting starts at ten walking with you that day"))

            md(L10n.t("""
                マイクが自分の声と一緒に **スピーカーの音楽まで拾ってしまう** ため、\
                歌詞やナレーションが文章に紛れ込みます。
                """, """
                The microphone picks up **the music along with your voice**, \
                so lyrics and narration end up in your text.
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func example(spoken: String, got: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            row(label: L10n.t("話した内容", "What you said"), text: spoken, color: .secondary)
            row(label: L10n.t("入力された文字", "What you got"), text: got, color: .orange)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.10)))
    }

    private func row(label: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.tertiary)
            Text("「\(text)」").font(.callout).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 原因

    private var cause: some View {
        card(icon: "questionmark.circle", title: L10n.t("なぜ自動で止まらないのか", "Why it doesn't stop on its own"),
             tint: .secondary) {
            md(L10n.t("""
                Aqua Voice などの音声入力アプリは、録音を始めると音を下げてくれます。\
                ただし止められるのは **Mac につながったスピーカー** だけです。

                Sonos や Google Home は、Mac ではなく **スピーカー自身が再生** しています。\
                Mac はその音を握っていないので、止めようがありません。
                """, """
                Dictation apps do lower the volume when recording starts — but only for \
                **speakers connected to your Mac**.

                Sonos and Google Home **play the audio themselves**. Your Mac never touches \
                that sound, so it cannot turn it down.
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var solution: some View {
        card(icon: "checkmark.circle", title: L10n.t("Kikazaru がすること", "What Kikazaru does"),
             tint: .green) {
            timeline
            md(L10n.t("""
                スピーカー本体に直接命令を送って音量を変えます。\
                **ヘッドホンに切り替えなくても、音楽を流したまま音声入力できます。**
                """, """
                It talks to the speaker directly and changes its volume. \
                **You can keep the music playing instead of switching to headphones.**
                """))
                .font(.callout).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 10) {
            step("🎙", L10n.t("話し始める", "You start talking"),
                 L10n.t("マイクが使われたことを検知します", "It notices the microphone turned on"))
            step("🙉", L10n.t("BGMが下がる", "The room gets quiet"),
                 L10n.t("スピーカーの音量を約0.1秒で下げます", "Speaker volume drops in about 0.1 seconds"))
            step("🐵", L10n.t("話し終わる", "You stop talking"),
                 L10n.t("元の音量にそのまま戻します", "The original volume comes right back"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.10)))
    }

    private func step(_ emoji: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.callout).bold()
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - 対応機種と使い方

    private var supported: some View {
        card(icon: "hifispeaker.2", title: L10n.t("対応スピーカー", "Supported speakers"),
             tint: .secondary) {
            VStack(alignment: .leading, spacing: 6) {
                supportRow("Sonos", L10n.t("推奨。動作確認済み", "Recommended — verified"), .green)
                supportRow("Google Home / Chromecast",
                           L10n.t("動作確認済み", "Verified"), .green)
                supportRow("Bose SoundTouch",
                           L10n.t("実機未確認", "Not tested on hardware"), .orange)
                supportRow(L10n.t("Mac から鳴らしているもの", "Anything played by the Mac"),
                           L10n.t("設定で有効にできます", "Enable it in Settings"), .secondary)
            }
        }
    }

    private func supportRow(_ name: String, _ note: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(name).font(.callout)
            Text(note).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var usage: some View {
        card(icon: "sparkles", title: L10n.t("使い方", "Getting started"), tint: .secondary) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).").font(.callout).foregroundStyle(.secondary)
                        md(text).font(.callout).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var steps: [String] {
        L10n.isJapanese ? [
            "メニューバーの 🐵 をクリックして **設定** を開く",
            "見つかったスピーカーのうち、下げたいものに **チェック** を入れる",
            "あとは普通に話すだけ。話している間だけ 🙉 に変わります",
        ] : [
            "Click 🐵 in the menu bar and open **Settings**",
            "**Check** the speakers you want turned down",
            "That's it — the icon turns 🙉 while you talk",
        ]
    }

    // MARK: - 部品

    private func card<Content: View>(
        icon: String, title: String, tint: Color, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(tint == .secondary ? .primary : tint)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum AboutWindow {
    @MainActor
    static func make() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
        window.title = L10n.t("Kikazaru について", "About Kikazaru")
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 660))
        window.center()
        return window
    }
}
