import AppKit
import SwiftUI

/// 設定画面。変更は即座に Coordinator へ反映される。
struct SettingsView: View {

    @State var settings: Settings
    @State private var hotkeyTrusted = HotkeyMonitor.isTrusted
    let onChange: (Settings) -> Void

    var body: some View {
        Form {
            Section("ダッキング") {
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $settings.duckRatio, in: 0.05...0.8, step: 0.05)
                    Text("元の音量の \(Int(settings.duckRatio * 100))% まで下げる")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Slider(value: $settings.releaseDelay, in: 0...2, step: 0.1)
                    Text("発話が途切れてから \(settings.releaseDelay, specifier: "%.1f") 秒で戻す")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("対象") {
                Toggle("Sonos", isOn: .constant(true)).disabled(true)
                Toggle("Mac 本体の音量も下げる", isOn: $settings.systemVolumeEnabled)
            }

            Section("高速レスポンス") {
                Toggle("ホットキーの解放で即座に戻す", isOn: $settings.hotkeyEnabled)
                Text("""
                    ディクテーションアプリは発話後もマイクを数秒保持するため、\
                    マイクの状態だけを見ていると戻りが遅れます。\
                    ホットキーの解放を見れば待たずに戻せます。
                    """)
                    .font(.caption).foregroundStyle(.secondary)

                if settings.hotkeyEnabled && !hotkeyTrusted {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("アクセシビリティ権限が必要です").font(.caption)
                        Button("許可する") {
                            HotkeyMonitor.requestPermission()
                            hotkeyTrusted = HotkeyMonitor.isTrusted
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .onChange(of: settings) { _, newValue in onChange(newValue) }
    }
}

enum SettingsWindow {
    @MainActor
    static func make(settings: Settings, onChange: @escaping (Settings) -> Void) -> NSWindow {
        let view = SettingsView(settings: settings, onChange: onChange)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        window.title = "SoundDuck 設定"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 420, height: 460))
        window.center()
        return window
    }
}
