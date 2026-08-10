import AppKit
import SwiftUI

/// 設定画面。
///
/// 設定項目を並べるだけでなく、「なぜこのアプリが要るのか」を最初に説明する。
/// 仕組みを知らないと、どの項目をどう動かせばいいか判断できないため。
struct SettingsView: View {

    @State var settings: Settings
    @State private var hotkeyTrusted = HotkeyMonitor.isTrusted
    let onChange: (Settings) -> Void

    var body: some View {
        ScrollView { content }
            .frame(width: 460, height: 620)
            .onChange(of: settings) { _, newValue in onChange(newValue) }
    }

    /// スクロールの中身。
    /// ScrollView はオフスクリーン描画だと中身が出ないため、
    /// 見た目の確認用に単体で描けるよう分けてある。
    var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            about
            Divider()
            duckingSection
            targetSection
            hotkeySection
        }
        .padding(24)
        .frame(width: 460)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - ヘッダー

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: AppIcon.appIcon(size: 56))
                .resizable().frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text("Kikazaru").font(.title2).bold()
                Text("話している間だけ、部屋のスピーカーを黙らせます")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("なぜ必要か", systemImage: "questionmark.circle").font(.headline)
            Text("""
                Aqua Voice などのディクテーションアプリは、録音中に \
                **Mac につながったスピーカー** の音を自動で下げてくれます。

                ところが **Sonos のようなネットワークスピーカーには効きません**。\
                音を鳴らしているのが Mac ではなく Sonos 本体だからです。

                結果、音楽が流れたままマイクに回り込み、歌詞や BGM が文字起こしに混ざります。
                """)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Label("どう解決するか", systemImage: "checkmark.circle").font(.headline)
            Text("""
                マイクが使われ始めたことを検知して、**Sonos 側の音量を直接下げます**。\
                喋り終われば元の音量に戻ります。

                ヘッドホンに切り替えなくても、スピーカーで音楽を流したまま音声入力できます。
                """)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    // MARK: - 設定

    private var duckingSection: some View {
        section("下げ方", icon: "speaker.wave.2") {
            labeled("どれくらい下げるか",
                    detail: "元の音量の \(Int(settings.duckRatio * 100))% まで下げます") {
                HStack {
                    Text("静か").font(.caption2).foregroundStyle(.secondary)
                    Slider(value: $settings.duckRatio, in: 0.05...0.8, step: 0.05)
                    Text("控えめ").font(.caption2).foregroundStyle(.secondary)
                }
            }

            labeled("いつ戻すか",
                    detail: "喋り終わってから \(String(format: "%.1f", settings.releaseDelay)) 秒後に戻します") {
                Slider(value: $settings.releaseDelay, in: 0.1...2, step: 0.1)
            }

            Text("0 に近づけすぎると、発話の切れ目で音量が上下にばたつきます。0.4 秒前後が目安です。")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var targetSection: some View {
        section("何を下げるか", icon: "hifispeaker.2") {
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("Sonos（自動で見つけます）")
                Spacer()
            }
            Toggle("Mac 本体の音量も一緒に下げる", isOn: $settings.systemVolumeEnabled)
            Text("Aqua Voice 側で既に本体をミュートしている場合は、off のままで構いません。")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var hotkeySection: some View {
        section("戻りを速くする", icon: "bolt") {
            Toggle("ホットキーを離した瞬間に戻す", isOn: $settings.hotkeyEnabled)

            Text("""
                ディクテーションアプリは、喋り終わってからも数秒マイクを掴んだままにします。\
                最初と最後の単語を取りこぼさないための仕様です。

                そのためマイクの状態だけを見ていると、戻るのが数秒遅れます。\
                **Aqua Voice の `fn` キーを離した瞬間**を見れば、待たずに戻せます。
                """)
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if settings.hotkeyEnabled {
                Picker("監視するキー", selection: $settings.hotkeyKeyCode) {
                    Text("fn（Aqua Voice の既定）").tag(Int64(63))
                    Text("右 Command").tag(Int64(54))
                    Text("右 Option").tag(Int64(61))
                    Text("右 Control").tag(Int64(62))
                }
                .pickerStyle(.menu)

                if hotkeyTrusted {
                    Label("アクセシビリティ権限は許可済みです", systemImage: "checkmark.seal.fill")
                        .font(.caption).foregroundStyle(.green)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("アクセシビリティ権限が必要です").font(.caption)
                        Button("許可する") {
                            HotkeyMonitor.requestPermission()
                            hotkeyTrusted = HotkeyMonitor.isTrusted
                        }
                    }
                    Text("キー入力は監視するだけで、横取りも記録もしません。")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - 部品

    private func section<Content: View>(
        _ title: String, icon: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline)
            content()
        }
    }

    private func labeled<Content: View>(
        _ title: String, detail: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline)
            content()
            Text(detail).font(.caption).foregroundStyle(.secondary)
        }
    }
}

enum SettingsWindow {
    @MainActor
    static func make(settings: Settings, onChange: @escaping (Settings) -> Void) -> NSWindow {
        let controller = NSHostingController(
            rootView: SettingsView(settings: settings, onChange: onChange))
        let window = NSWindow(contentViewController: controller)
        window.title = "Kikazaru"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 460, height: 620))
        window.center()
        return window
    }
}
