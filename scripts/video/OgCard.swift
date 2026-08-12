import AppKit

// OGP 画像。
//
// タイムラインでは横 300px 程度まで縮む。その大きさで読めるのは 1〜2 行だけなので、
// 説明を並べず「何が起きるか」を1文と1枚の絵に絞る。
// 背景は暗くする。白い紙のままだと、白いタイムラインの中に埋もれて存在に気づかれない。

func drawOgCard(_ ctx: CGContext, w: CGFloat, h: CGFloat) {
    let s = w / 2400
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    // 下地
    let full = NSRect(x: 0, y: 0, width: w, height: h)
    Palette.dark.setFill()
    ctx.fill(full)
    if let g = NSGradient(colors: [
        NSColor(srgbRed: 0.152, green: 0.128, blue: 0.110, alpha: 1),
        NSColor(srgbRed: 0.055, green: 0.047, blue: 0.063, alpha: 1),
    ]) {
        g.draw(in: full, angle: -72)
    }

    // 名前。小さくてよい。主役は下の一文。
    let badge = NSRect(x: 132 * s, y: h - 210 * s, width: 96 * s, height: 96 * s)
    roundedRect(badge, radius: badge.width * 0.2237, fill: NSColor.white.withAlphaComponent(0.10))
    let ef = Face.emoji(58 * s)
    let eg = measure("🙉", ef)
    text("🙉", ef, .white, at: NSPoint(x: badge.midX - eg.width / 2,
                                      y: badge.midY - eg.height / 2 + 2 * s))
    text("Kikazaru", Face.bold(58 * s), Palette.paperOnDark,
         at: NSPoint(x: badge.maxX + 28 * s, y: badge.midY - 22 * s), kern: -1 * s)

    // 一文。ここだけは縮んでも読める大きさにする。
    text("話している間だけ、", Face.bold(150 * s), .white,
         at: NSPoint(x: 132 * s, y: h - 420 * s), kern: -4 * s)
    text("部屋のスピーカーが静かになる", Face.bold(150 * s), .white,
         at: NSPoint(x: 132 * s, y: h - 600 * s), kern: -4 * s)

    // 何が起きるかを、記号だけで1行。文字が読めなくてもここで伝わる。
    let rowY = h * 0.30
    let micF = Face.emoji(88 * s)
    let mg = measure("🎙", micF)
    text("🎙", micF, .white, at: NSPoint(x: 138 * s, y: rowY - mg.height / 2))
    text("マイク ON", Face.semi(52 * s), Palette.warn,
         at: NSPoint(x: 138 * s + mg.width + 20 * s, y: rowY - 20 * s))

    // 矢印
    let arrowX = 700 * s
    let arrow = NSBezierPath()
    arrow.move(to: NSPoint(x: arrowX, y: rowY))
    arrow.line(to: NSPoint(x: arrowX + 110 * s, y: rowY))
    NSColor.white.withAlphaComponent(0.45).setStroke()
    arrow.lineWidth = 6 * s
    arrow.lineCapStyle = .round
    arrow.stroke()
    let head = NSBezierPath()
    head.move(to: NSPoint(x: arrowX + 110 * s, y: rowY))
    head.line(to: NSPoint(x: arrowX + 78 * s, y: rowY + 22 * s))
    head.line(to: NSPoint(x: arrowX + 78 * s, y: rowY - 22 * s))
    head.close()
    NSColor.white.withAlphaComponent(0.45).setFill()
    head.fill()

    // 音量が落ちるところ
    let spF = Face.emoji(88 * s)
    let sg = measure("🔉", spF)
    let spX = arrowX + 168 * s
    text("🔉", spF, .white, at: NSPoint(x: spX, y: rowY - sg.height / 2))

    let bar = NSRect(x: spX + sg.width + 26 * s, y: rowY - 22 * s,
                     width: 560 * s, height: 44 * s)
    roundedRect(bar, radius: bar.height / 2, fill: NSColor.white.withAlphaComponent(0.14))
    // もとの高さを白枠で残し、いまの高さを橙で塗る
    roundedRect(NSRect(x: bar.minX, y: bar.minY, width: bar.width * 0.34, height: bar.height),
                radius: bar.height / 2, fill: nil,
                stroke: NSColor.white.withAlphaComponent(0.45), lineWidth: 3 * s)
    roundedRect(NSRect(x: bar.minX, y: bar.minY, width: bar.width * 0.10, height: bar.height),
                radius: bar.height / 2, fill: Palette.accent)
    text("20 → 6", Face.bold(52 * s), Palette.warn,
         at: NSPoint(x: bar.maxX + 30 * s, y: rowY - 22 * s))

    // 足元。読めなくても困らない情報だけ。
    text("Sonos / Google Home に対応　—　macOS・無料・オープンソース",
         Face.body(40 * s), NSColor.white.withAlphaComponent(0.5),
         at: NSPoint(x: 138 * s, y: 92 * s))
}
