import AppKit

// メニューバーのみで動かすため .accessory を指定する。
// Dock にもアプリスイッチャーにも出ない。
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
