import AppKit

/// アイコンを PNG に書き出す。見た目を確認するためだけの補助。
enum IconExporter {

    static func run(into directory: String) {
        let base = URL(fileURLWithPath: directory)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)

        // メニューバー用はテンプレート画像なので、確認しやすいよう拡大して描き直す
        write(scaled(AppIcon.menuBar(ducked: false), to: 144),
              to: base.appendingPathComponent("menubar-idle.png"))
        write(scaled(AppIcon.menuBar(ducked: true), to: 144),
              to: base.appendingPathComponent("menubar-ducked.png"))
        write(AppIcon.appIcon(size: 256),
              to: base.appendingPathComponent("app-icon.png"))

        print("書き出しました: \(base.path)")
    }

    private static func scaled(_ image: NSImage, to side: CGFloat) -> NSImage {
        let size = NSSize(width: side, height: side)
        return NSImage(size: size, flipped: false) { rect in
            NSColor.white.setFill()
            rect.fill()
            image.draw(in: rect)
            return true
        }
    }

    private static func write(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else { return }
        try? png.write(to: url)
    }
}

import SwiftUI

/// 設定画面を PNG に書き出す。実際に開かずにレイアウトを確認するための補助。
enum SettingsExporter {

    @MainActor
    static func run(into path: String) {
        var settings = Settings()
        settings.hotkeyEnabled = true          // 隠れている項目も含めて確認する
        let view = SettingsView(settings: settings, model: nil) { _ in }

        let renderer = ImageRenderer(content: view.content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            print("書き出しに失敗しました")
            return
        }
        try? png.write(to: URL(fileURLWithPath: path))
        print("書き出しました: \(path)")
    }
}
