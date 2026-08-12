#!/usr/bin/env swift
import AppKit

// アプリアイコンを作る。
//
// 絵文字をそのまま焼き込む。メニューバーもサイトも 🙉 を使っているので、
// アイコンだけ別の絵にすると「同じアプリ」だと分からなくなる。
//
// 使い方: swift scripts/make-icon.swift <出力先.icns>

let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/Kikazaru.icns"

/// 1辺 size px のアイコンを描く。
func render(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return image }
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // macOS のアイコンは周囲に余白を取る。Dock で他のアプリと大きさが揃う。
    let inset = size * 0.094
    let box = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let radius = box.width * 0.2237      // Big Sur 以降の角丸比率

    let shape = NSBezierPath(roundedRect: box, xRadius: radius, yRadius: radius)
    shape.addClip()

    // 紙ではなく暗い面にする。🙉 が明るい肌色なので、暗い下地のほうが輪郭が立つ。
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.216, green: 0.184, blue: 0.157, alpha: 1),   // 温かみのある焦茶
        NSColor(srgbRed: 0.090, green: 0.078, blue: 0.098, alpha: 1),   // サイトの ink
    ])
    gradient?.draw(in: box, angle: -90)

    // 絵文字。ベースラインではなく見た目の中心で置く。
    let glyphSize = box.width * 0.62
    let font = NSFont(name: "Apple Color Emoji", size: glyphSize)
        ?? NSFont.systemFont(ofSize: glyphSize)
    let text = "🙉" as NSString
    let attrs: [NSAttributedString.Key: Any] = [.font: font]
    let measured = text.size(withAttributes: attrs)
    let origin = NSPoint(
        x: box.midX - measured.width / 2,
        y: box.midY - measured.height / 2 + size * 0.012)
    text.draw(at: origin, withAttributes: attrs)

    return image
}

func png(_ image: NSImage, _ size: CGFloat) -> Data? {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    rep.size = NSSize(width: size, height: size)
    return rep.representation(using: .png, properties: [:])
}

let fm = FileManager.default
let work = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("Kikazaru.iconset")
try? fm.removeItem(at: work)
try! fm.createDirectory(at: work, withIntermediateDirectories: true)

// icns に必要な組み合わせ。@2x は同じ見た目を倍の解像度で描き直す。
let variants: [(name: String, pixels: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for v in variants {
    guard let data = png(render(size: v.pixels), v.pixels) else {
        print("❌ \(v.name) を描けませんでした"); exit(1)
    }
    try! data.write(to: work.appendingPathComponent("\(v.name).png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", work.path, "-o", outPath]
try! task.run()
task.waitUntilExit()
guard task.terminationStatus == 0 else {
    print("❌ iconutil が失敗しました"); exit(1)
}

// 目視確認用に 1024 の PNG も残す
if let data = png(render(size: 1024), 1024) {
    let preview = (outPath as NSString).deletingPathExtension + "-preview.png"
    try? data.write(to: URL(fileURLWithPath: preview))
}

print("✅ \(outPath)")
