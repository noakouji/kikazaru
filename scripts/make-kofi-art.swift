#!/usr/bin/env swift
import AppKit

// Ko-fi ページに貼る画像を作る。
//
// 支援ページだけ別の見た目だと「本当にこの人のページか」が分からず手が止まる。
// 配布サイトと同じ紙の色・同じ書体・同じ 🙉 で揃える。
//
// 使い方: swift scripts/make-kofi-art.swift <出力ディレクトリ>

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/icons"
try? FileManager.default.createDirectory(
    atPath: outDir, withIntermediateDirectories: true)

let paper = NSColor(srgbRed: 0.969, green: 0.961, blue: 0.945, alpha: 1)   // #f7f5f1
let ink = NSColor(srgbRed: 0.106, green: 0.102, blue: 0.122, alpha: 1)     // #1b1a1f
let inkSoft = NSColor(srgbRed: 0.333, green: 0.322, blue: 0.361, alpha: 1) // #55525c

func save(_ image: NSImage, _ name: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("❌ \(name)"); return
    }
    try? png.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("✅ \(outDir)/\(name)")
}

/// サイトと同じ紙の質感。均一なベタ塗りを避けるための細かい点。
func drawPaper(_ rect: CGRect, _ ctx: CGContext) {
    paper.setFill()
    ctx.fill(rect)
    ctx.setFillColor(NSColor.black.withAlphaComponent(0.022).cgColor)
    var y = rect.minY
    while y < rect.maxY {
        var x = rect.minX
        while x < rect.maxX {
            ctx.fill(CGRect(x: x, y: y, width: 1.4, height: 1.4))
            x += 4
        }
        y += 4
    }
}

func font(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: weight)
}

// MARK: - カバー画像

// Ko-fi のカバーは横長で、上下がプロフィール画像とボタンに隠れる。
// 文字は縦の中央寄りに置く。
let coverSize = NSSize(width: 1600, height: 400)
let cover = NSImage(size: coverSize)
cover.lockFocus()
if let ctx = NSGraphicsContext.current?.cgContext {
    ctx.setShouldAntialias(true)
    let rect = CGRect(origin: .zero, size: coverSize)
    drawPaper(rect, ctx)

    let emoji = "🙉" as NSString
    let emojiFont = NSFont(name: "Apple Color Emoji", size: 150)
        ?? font(150, .regular)
    let emojiSize = emoji.size(withAttributes: [.font: emojiFont])
    emoji.draw(at: NSPoint(x: 120, y: coverSize.height / 2 - emojiSize.height / 2 + 6),
               withAttributes: [.font: emojiFont])

    let textX = 120 + emojiSize.width + 44

    let title = "Kikazaru" as NSString
    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: font(104, .heavy),
        .foregroundColor: ink,
        .kern: -2.0,
    ]
    let titleSize = title.size(withAttributes: titleAttrs)
    title.draw(at: NSPoint(x: textX, y: coverSize.height / 2 - 6),
               withAttributes: titleAttrs)

    let sub = "マイクがオンの間だけ、部屋のBGMを下げる Mac アプリ" as NSString
    let subAttrs: [NSAttributedString.Key: Any] = [
        .font: font(34, .medium),
        .foregroundColor: inkSoft,
    ]
    sub.draw(at: NSPoint(x: textX + 4, y: coverSize.height / 2 - 62),
             withAttributes: subAttrs)

    _ = titleSize
}
cover.unlockFocus()
save(cover, "kofi-cover.png")

// MARK: - プロフィール画像

// アプリアイコンと同じ絵にする。Dock で見た顔がそのまま出てくるほうが安心できる。
let avatarSize = NSSize(width: 800, height: 800)
let avatar = NSImage(size: avatarSize)
avatar.lockFocus()
if let ctx = NSGraphicsContext.current?.cgContext {
    ctx.setShouldAntialias(true)
    let rect = CGRect(origin: .zero, size: avatarSize)
    // Ko-fi は円形に切り抜く。角ではなく面全体を塗る。
    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.216, green: 0.184, blue: 0.157, alpha: 1),
        NSColor(srgbRed: 0.090, green: 0.078, blue: 0.098, alpha: 1),
    ])
    gradient?.draw(in: rect, angle: -90)

    let emoji = "🙉" as NSString
    let emojiFont = NSFont(name: "Apple Color Emoji", size: avatarSize.width * 0.56)
        ?? font(avatarSize.width * 0.56, .regular)
    let size = emoji.size(withAttributes: [.font: emojiFont])
    emoji.draw(at: NSPoint(x: rect.midX - size.width / 2,
                           y: rect.midY - size.height / 2 + 8),
               withAttributes: [.font: emojiFont])
}
avatar.unlockFocus()
save(avatar, "kofi-avatar.png")
