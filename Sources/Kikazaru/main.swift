import AppKit

// アイコンの見た目確認用。通常起動には影響しない。
//   Kikazaru --export-icons <出力先ディレクトリ>
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-icons" {
    IconExporter.run(into: CommandLine.arguments[2])
    exit(0)
}
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-settings" {
    let path = CommandLine.arguments[2]
    MainActor.assumeIsolated { SettingsExporter.run(into: path) }
    exit(0)
}

// メニューバーのみで動かすため .accessory を指定する。
// Dock にもアプリスイッチャーにも出ない。
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
