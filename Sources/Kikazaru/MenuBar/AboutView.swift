import SwiftUI

/// このアプリについて。設定画面のタブとして表示する。
///
/// 別ウインドウにするとモーダルが増えて煩雑になるので、設定と同じ窓に収める。
/// 抽象的に書くと伝わらないため、番号付きで一段ずつ、実際に起きることを示す。
struct AboutView {

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    /// ScrollView はオフスクリーン描画だと空になるため、中身を分けてある。
    var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            section(1, L10n.t("こんなことが起きます", "What goes wrong")) { problem }
            section(2, L10n.t("なぜ自動で止まらないのか", "Why it doesn't stop by itself")) { cause }
            section(3, L10n.t("Kikazaru が何をするか", "What Kikazaru does")) { solution }
            section(4, L10n.t("対応しているスピーカー", "Supported speakers")) { supported }
            section(5, L10n.t("使いはじめる", "Getting started")) { usage }
        }
        .padding(24)
        .frame(width: 500, alignment: .leading)
    }

    private func md(_ s: String) -> Text { Text(LocalizedStringKey(s)) }

    private func paragraph(_ text: String) -> some View {
        md(text).font(.callout).fixedSize(horizontal: false, vertical: true)
    }

    private func box<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { content() }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.10)))
    }

    // MARK: - ヘッダー

    private var header: some View {
        HStack(spacing: 14) {
            Text("🙉").font(.system(size: 46))
            VStack(alignment: .leading, spacing: 3) {
                Text("Kikazaru").font(.title).bold()
                Text(L10n.t("マイクがオンの間だけ、BGMを下げます",
                            "Lowers the music while your mic is on"))
                    .foregroundStyle(.secondary)
                Text(L10n.t("バージョン \(version)", "Version \(version)"))
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
        }
    }

    /// 番号付きの見出しで、読む順番を明示する。
    private func section<Content: View>(
        _ number: Int, _ title: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.subheadline).bold().foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.accentColor))
                Text(title).font(.title3).bold()
            }
            content().padding(.leading, 34)
        }
    }

    // MARK: - 1. 問題

    private var problem: some View {
        VStack(alignment: .leading, spacing: 10) {
            paragraph(L10n.t("スピーカーで音楽を流しながら、音声入力で文章を書いているとします。",
                             "Say you are dictating while music plays on your speakers."))
            box {
                quote(L10n.t("話した内容", "What you said"),
                      L10n.t("明日の定例は10時からです", "The meeting starts at ten"), .secondary)
                quote(L10n.t("入力された文字", "What actually got typed"),
                      L10n.t("明日の定例は10時からです 君と歩いた あの日の",
                             "The meeting starts at ten walking with you that day"), .orange)
            }
            paragraph(L10n.t("""
                マイクが自分の声と一緒に **スピーカーの音楽まで拾ってしまう** ため、\
                歌詞やナレーションが文章に紛れ込みます。オンライン会議でも同じことが起きます。
                """, """
                The microphone picks up **the music along with your voice**, so lyrics and \
                narration end up in your text. The same happens in online meetings.
                """))
        }
    }

    private func quote(_ label: String, _ text: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.tertiary)
            Text("「\(text)」").font(.callout).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 2. 原因

    private var cause: some View {
        VStack(alignment: .leading, spacing: 10) {
            paragraph(L10n.t("""
                Aqua Voice などの音声入力アプリは、録音を始めると音を下げてくれます。\
                ただし止められるのは **Mac につながったスピーカー** だけです。
                """, """
                Dictation apps do lower the volume when recording starts — but only for \
                **speakers connected to your Mac**.
                """))
            box {
                compareRow("✅", L10n.t("Mac につないだスピーカー", "Speakers plugged into the Mac"),
                           L10n.t("自動で下がる", "Lowered automatically"), .green)
                compareRow("❌", L10n.t("Sonos / Google Home", "Sonos / Google Home"),
                           L10n.t("下がらない", "Not lowered"), .orange)
            }
            paragraph(L10n.t("""
                Sonos や Google Home は **スピーカー自身が再生** しているので、\
                Mac はその音を握っていません。だから止めようがないのです。
                """, """
                Sonos and Google Home **play the audio themselves**, so your Mac never touches \
                that sound. It simply cannot turn it down.
                """))
        }
    }

    private func compareRow(_ mark: String, _ name: String,
                            _ result: String, _ color: Color) -> some View {
        HStack(spacing: 10) {
            Text(mark)
            Text(name).font(.callout)
            Spacer()
            Text(result).font(.caption).foregroundStyle(color)
        }
    }

    // MARK: - 3. 解決

    private var solution: some View {
        VStack(alignment: .leading, spacing: 10) {
            paragraph(L10n.t("Kikazaru はスピーカー本体に直接命令を送り、音量を変えます。",
                             "Kikazaru talks to the speaker directly and changes its volume."))
            box {
                step("🎙", L10n.t("話し始める", "You start talking"),
                     L10n.t("マイクがオンになったことを検知します",
                            "It notices the microphone turned on"))
                step("🙉", L10n.t("BGMが下がる", "The music drops"),
                     L10n.t("約0.1秒で下げます。メニューバーも 🙉 に変わります",
                            "Drops in about 0.1 seconds. The menu bar turns 🙉"))
                step("🐵", L10n.t("話し終わる", "You stop talking"),
                     L10n.t("元の音量にそのまま戻します", "The original volume comes right back"))
            }
            paragraph(L10n.t("**ヘッドホンに切り替えなくても、音楽を流したまま音声入力できます。**",
                             "**You can keep the music playing instead of switching to headphones.**"))
        }
    }

    private func step(_ emoji: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout).bold()
                Text(detail).font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - 4. 対応機種

    private var supported: some View {
        VStack(alignment: .leading, spacing: 8) {
            supportRow("Sonos", L10n.t("推奨。動作確認済み", "Recommended — verified"), .green)
            supportRow("Google Home / Chromecast", L10n.t("動作確認済み", "Verified"), .green)
            supportRow("Bose SoundTouch", L10n.t("実機未確認", "Not tested on hardware"), .orange)
            supportRow(L10n.t("Mac から鳴らしているもの", "Anything played by the Mac"),
                       L10n.t("設定で有効にできます", "Enable it in Settings"), .secondary)
            paragraph(L10n.t("Sonos 以外は、うっかりテレビを下げないよう **初期状態ではオフ** です。",
                             "Everything except Sonos is **off by default**, so your TV is safe."))
                .padding(.top, 4)
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

    // MARK: - 5. 使い方

    private var usage: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(usageSteps.enumerated()), id: \.offset) { index, text in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1).").font(.callout).foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .trailing)
                    md(text).font(.callout).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var usageSteps: [String] {
        L10n.isJapanese ? [
            "この窓の **設定** タブを開く",
            "見つかったスピーカーのうち、下げたいものに **チェック** を入れる",
            "あとは普通に話すだけ。話している間だけ 🙉 に変わります",
        ] : [
            "Open the **Settings** tab in this window",
            "**Check** the speakers you want turned down",
            "That's it — the icon turns 🙉 while you talk",
        ]
    }
}
