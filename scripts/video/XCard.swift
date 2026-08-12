import AppKit

// X に貼る1枚。2400x1350（16:9）で描いて、必要なら縮めて使う。
//
// タイムラインは指が止まらない場所なので、1枚で「何のアプリか」「何が起きるか」まで
// 伝わらないと素通りされる。動画と同じ絵作りにして、続けて見たときに同じものだと分かるようにする。

func drawXCard(_ ctx: CGContext, w: CGFloat, h: CGFloat) {
    let s = w / 2400   // 基準サイズからの倍率
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let full = NSRect(x: 0, y: 0, width: w, height: h)
    Palette.paper.setFill()
    ctx.fill(full)
    paperTexture(full, ctx, strength: 0.02)

    // 左上：どのアプリの話か
    let badge = NSRect(x: 150 * s, y: h - 300 * s, width: 150 * s, height: 150 * s)
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.2)
    sh.shadowOffset = NSSize(width: 0, height: -8 * s)
    sh.shadowBlurRadius = 26 * s
    sh.set()
    roundedRect(badge, radius: badge.width * 0.2237, fill: Palette.dark)
    NSGraphicsContext.restoreGraphicsState()
    let ef = Face.emoji(84 * s)
    let eg = measure("🙉", ef)
    text("🙉", ef, .white, at: NSPoint(x: badge.midX - eg.width / 2,
                                      y: badge.midY - eg.height / 2 + 3 * s))
    text("Kikazaru", Face.bold(92 * s), Palette.ink,
         at: NSPoint(x: badge.maxX + 42 * s, y: badge.midY - 36 * s), kern: -2 * s)

    // 見出し。1枚で意味が通る一文だけを大きく置く。
    text("マイクがオンの間だけ、", Face.bold(118 * s), Palette.ink,
         at: NSPoint(x: 150 * s, y: h - 500 * s), kern: -2 * s)
    text("部屋のBGMを下げる", Face.bold(118 * s), Palette.ink,
         at: NSPoint(x: 150 * s, y: h - 650 * s), kern: -2 * s)
    text("Sonos / Google Home を、喋っている間だけ自動で静かにする macOS アプリ",
         Face.body(44 * s), Palette.inkSoft, at: NSPoint(x: 156 * s, y: h - 740 * s))

    // 起きることを、そのまま図で見せる
    let panel = NSRect(x: 150 * s, y: 210 * s, width: w - 300 * s, height: 330 * s)
    card(panel, radius: 26 * s, shadow: 0.12)

    let micF = Face.emoji(54 * s)
    let micG = measure("🎙", micF)
    text("🎙", micF, .white, at: NSPoint(x: panel.minX + 54 * s,
                                         y: panel.maxY - 96 * s - micG.height / 2))
    text("マイク ON", Face.semi(46 * s), Palette.accent,
         at: NSPoint(x: panel.minX + 54 * s + micG.width + 18 * s, y: panel.maxY - 118 * s))

    // 音量バー：もとの位置を残して、落ちた差を見せる
    let bar = NSRect(x: panel.minX + 54 * s, y: panel.minY + 118 * s,
                     width: panel.width - 250 * s, height: 40 * s)
    roundedRect(bar, radius: bar.height / 2, fill: Palette.line.withAlphaComponent(0.75))
    let originX = bar.minX + bar.width * 0.20
    roundedRect(NSRect(x: bar.minX, y: bar.minY, width: originX - bar.minX, height: bar.height),
                radius: bar.height / 2, fill: nil, stroke: Palette.inkFaint,
                lineWidth: 2 * s, alpha: 0.55)
    let mark = NSBezierPath()
    mark.move(to: NSPoint(x: originX, y: bar.minY - 20 * s))
    mark.line(to: NSPoint(x: originX, y: bar.maxY + 6 * s))
    Palette.inkFaint.withAlphaComponent(0.6).setStroke()
    mark.lineWidth = 2 * s
    mark.setLineDash([7 * s, 7 * s], count: 2, phase: 0)
    mark.stroke()
    textCentered("もとの音量 20", Face.body(28 * s), Palette.inkFaint,
                 centerX: originX, y: bar.minY - 62 * s, alpha: 0.85)
    roundedRect(NSRect(x: bar.minX, y: bar.minY, width: bar.width * 0.06, height: bar.height),
                radius: bar.height / 2, fill: Palette.accent)
    text("6", Face.mono(52 * s), Palette.accent,
         at: NSPoint(x: bar.maxX + 28 * s, y: bar.minY - 6 * s))

    // 足元：入手に必要な情報だけ
    let meta = "macOS 14 以降　/　無料　/　オープンソース"
    text(meta, Face.body(38 * s), Palette.inkFaint, at: NSPoint(x: 150 * s, y: 100 * s))
    let url = "kikazaru.koji-okada.workers.dev"
    let uf = Face.semi(40 * s)
    let us = measure(url, uf)
    roundedRect(NSRect(x: w - 150 * s - us.width - 64 * s, y: 78 * s,
                       width: us.width + 64 * s, height: 84 * s),
                radius: 42 * s, fill: Palette.accent)
    text(url, uf, .white, at: NSPoint(x: w - 150 * s - us.width - 32 * s, y: 106 * s))
}
