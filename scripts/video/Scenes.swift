import AppKit

// 紹介動画の絵コンテ。1920x1080 / 30fps。
// 時間 t（秒）を渡すと、その瞬間の1枚が決まる。動画は同じ入力から必ず同じ絵になる。

let W: CGFloat = 1920
let H: CGFloat = 1080

enum Cut {
    static let logo = 0.0 ..< 4.0
    static let problem = 4.0 ..< 11.0
    static let why = 11.0 ..< 17.5
    static let fix = 17.5 ..< 26.5
    static let setup = 26.5 ..< 30.0
    static let cta = 30.0 ..< 33.5
    static let total = 33.5
}

/// 設定画面の実物。手元の画像を読み込んで最後のカットで使う。
let settingsShot: NSImage? = {
    let p = "site/public/app-settings.png"
    return FileManager.default.fileExists(atPath: p) ? NSImage(contentsOfFile: p) : nil
}()

// MARK: - 背景

/// カットの切り替わりで紙と暗幕を混ぜる。境目を作らないため。
private func background(_ t: Double, _ ctx: CGContext) {
    let full = NSRect(x: 0, y: 0, width: W, height: H)
    Palette.paper.setFill()
    ctx.fill(full)
    paperTexture(full, ctx)

    // 暗くする区間（問題提起と締め）を、前後 0.45 秒かけて重ねる
    var darkness = 0.0
    darkness = max(darkness, fadeInOut(t, in: 3.55, hold: 4.05, out: 10.45, gone: 10.95))
    darkness = max(darkness, fadeInOut(t, in: 29.5, hold: 30.0, out: 33.6, gone: 33.7))
    if darkness > 0.001 {
        Palette.dark.withAlphaComponent(darkness).setFill()
        ctx.fill(full)
    }
    // 設定カットだけ、わずかに沈ませて実物写真を浮かせる
    let deep = fadeInOut(t, in: 26.1, hold: 26.6, out: 29.45, gone: 29.85)
    if deep > 0.001 {
        Palette.paperDeep.withAlphaComponent(deep * 0.9).setFill()
        ctx.fill(full)
    }
}

// MARK: - 共通の部品

/// 画面下に置く一言。動画は音を切って見られるので、字が主役になる。
private func caption(_ s: String, _ t: Double, _ span: (Double, Double, Double, Double),
                     onDark: Bool = false, y: CGFloat = 118) {
    let a = fadeInOut(t, in: span.0, hold: span.1, out: span.2, gone: span.3)
    guard a > 0.001 else { return }
    let rise = lerp(14, 0, easeOut(progress(t, span.0, span.1)))
    textCentered(s, Face.bold(52), onDark ? Palette.paperOnDark : Palette.ink,
                 centerX: W / 2, y: y - rise, alpha: a)
}

/// 🙉 を載せた角丸。アプリアイコンと同じ見た目にして、どのアプリの話か迷わせない。
private func appBadge(center: NSPoint, side: CGFloat, alpha: Double, glyph: String = "🙉",
                      onDark: Bool = false) {
    guard alpha > 0.001 else { return }
    // 暗い背景に暗い角丸を置くと沈んで見えなくなる。絵文字だけを大きく出す。
    if onDark {
        let f = Face.emoji(side * 0.86)
        let g = measure(glyph, f)
        text(glyph, f, .white,
             at: NSPoint(x: center.x - g.width / 2, y: center.y - g.height / 2), alpha: alpha)
        return
    }
    let r = NSRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowColor = NSColor.black.withAlphaComponent(0.22 * alpha)
    sh.shadowOffset = NSSize(width: 0, height: -10)
    sh.shadowBlurRadius = 30
    sh.set()
    roundedRect(r, radius: side * 0.2237, fill: Palette.dark, alpha: alpha)
    NSGraphicsContext.restoreGraphicsState()
    let f = Face.emoji(side * 0.56)
    let g = measure(glyph, f)
    text(glyph, f, .white, at: NSPoint(x: center.x - g.width / 2,
                                       y: center.y - g.height / 2 + side * 0.02), alpha: alpha)
}

/// 音の大きさを表す弧。level（0〜1）で本数と濃さが変わる。
private func soundWaves(from p: NSPoint, level: Double, phase: Double, alpha: Double,
                        color: NSColor) {
    guard alpha > 0.001, level > 0.01 else { return }
    for i in 0..<3 {
        let step = Double(i)
        let visible = min(max(level * 3 - step, 0), 1)
        guard visible > 0.01 else { continue }
        let pulse = 1 + 0.06 * sin((phase - step * 0.35) * 3.4)
        let radius = (58 + step * 40) * pulse
        let path = NSBezierPath()
        path.appendArc(withCenter: p, radius: radius, startAngle: -46, endAngle: 46)
        color.withAlphaComponent(alpha * visible * (0.85 - step * 0.2)).setStroke()
        path.lineWidth = 9 - CGFloat(step) * 1.6
        path.lineCapStyle = .round
        path.stroke()
    }
}

/// 文字起こしの窓。汚れた文字を差し込めるようにしてある。
private func transcriptCard(_ rect: NSRect, alpha: Double, clean: String,
                            dirty: String? = nil, dirtyAlpha: Double = 0,
                            typed: Double = 1) {
    guard alpha > 0.001 else { return }
    card(rect, radius: 20, alpha: alpha, shadow: 0.16)
    text("文字起こし", Face.body(26), Palette.inkFaint,
         at: NSPoint(x: rect.minX + 34, y: rect.maxY - 58), alpha: alpha)

    let font = Face.semi(40)
    let shown = String(clean.prefix(Int((Double(clean.count) * typed).rounded())))
    let baseY = rect.minY + 46
    let size = text(shown, font, Palette.ink, at: NSPoint(x: rect.minX + 34, y: baseY), alpha: alpha)

    if let dirty, dirtyAlpha > 0.001 {
        let x = rect.minX + 34 + size.width + 14
        let d = measure(dirty, font)
        roundedRect(NSRect(x: x - 8, y: baseY - 6, width: d.width + 16, height: d.height + 8),
                    radius: 8, fill: Palette.warn.withAlphaComponent(0.22),
                    alpha: alpha * dirtyAlpha)
        text(dirty, font, Palette.warn, at: NSPoint(x: x, y: baseY), alpha: alpha * dirtyAlpha)
    }
}

/// 音量のバー。
/// 数字だけだと「下がった」ことが伝わらないので、元の位置に印を残して差を見せる。
private func volumeBar(_ rect: NSRect, value: Double, origin: Double,
                       alpha: Double, label: String) {
    guard alpha > 0.001 else { return }
    text(label, Face.body(30), Palette.inkSoft,
         at: NSPoint(x: rect.minX, y: rect.maxY + 22), alpha: alpha)

    roundedRect(rect, radius: rect.height / 2, fill: Palette.line.withAlphaComponent(0.75), alpha: alpha)

    let originX = rect.minX + rect.width * CGFloat(origin / 100)
    let dropped = value < origin - 0.5
    if dropped {
        // もとの高さ。ここから落ちた、という差分を目に見えるようにする。
        let ghost = NSRect(x: rect.minX, y: rect.minY, width: originX - rect.minX, height: rect.height)
        roundedRect(ghost, radius: rect.height / 2, fill: nil,
                    stroke: Palette.inkFaint, lineWidth: 2, alpha: alpha * 0.55)
        // 印は下へ逃がす。バーの上には項目名が乗っているので重なる。
        let mark = NSBezierPath()
        mark.move(to: NSPoint(x: originX, y: rect.minY - 22))
        mark.line(to: NSPoint(x: originX, y: rect.maxY + 6))
        Palette.inkFaint.withAlphaComponent(alpha * 0.6).setStroke()
        mark.lineWidth = 2
        mark.setLineDash([7, 7], count: 2, phase: 0)
        mark.stroke()
        textCentered("もとの音量 \(Int(origin))", Face.body(26), Palette.inkFaint,
                     centerX: originX, y: rect.minY - 62, alpha: alpha * 0.85)
    }

    let w = max(rect.height, rect.width * CGFloat(value / 100))
    let filled = NSRect(x: rect.minX, y: rect.minY, width: w, height: rect.height)
    let color = dropped ? Palette.accent : Palette.ink
    roundedRect(filled, radius: rect.height / 2, fill: color, alpha: alpha)

    let n = "\(Int(value.rounded()))"
    text(n, Face.mono(46), color, at: NSPoint(x: rect.maxX + 26, y: rect.minY - 6), alpha: alpha)
}

/// いまの状態を示す札。🐵 待機中 / 🙉 下げています。
private func stateChip(center: NSPoint, ducking: Bool, alpha: Double, pop: Double) {
    guard alpha > 0.001 else { return }
    let glyph = ducking ? "🙉" : "🐵"
    let label = ducking ? "下げています" : "待機中"
    let tint = ducking ? Palette.accent : Palette.inkFaint
    let font = Face.semi(34)
    let lw = measure(label, font).width
    let scale = 1 + 0.06 * pop
    let w = (lw + 118) * scale
    let h: CGFloat = 78 * scale
    let r = NSRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h)
    roundedRect(r, radius: h / 2, fill: ducking ? Palette.accentSoft : Palette.paperDeep, alpha: alpha)
    let f = Face.emoji(40 * scale)
    let g = measure(glyph, f)
    text(glyph, f, .white, at: NSPoint(x: r.minX + 26, y: center.y - g.height / 2), alpha: alpha)
    text(label, font, tint, at: NSPoint(x: r.minX + 26 + g.width + 14,
                                        y: center.y - 17 * scale), alpha: alpha)
}

// MARK: - 各カット

private func drawLogo(_ t: Double) {
    let a = fadeInOut(t, in: 0.15, hold: 0.9, out: 3.55, gone: 4.0)
    guard a > 0.001 else { return }
    let grow = easeOut(progress(t, 0.15, 1.0))
    appBadge(center: NSPoint(x: W / 2, y: H / 2 + 132), side: 190 * lerp(0.82, 1, grow), alpha: a)

    let nameA = fadeInOut(t, in: 0.6, hold: 1.25, out: 3.55, gone: 4.0)
    let rise = lerp(26, 0, easeOut(progress(t, 0.6, 1.25)))
    textCentered("Kikazaru", Face.bold(148), Palette.ink,
                 centerX: W / 2, y: H / 2 - 96 - rise, alpha: nameA, kern: -4)

    let subA = fadeInOut(t, in: 1.15, hold: 1.8, out: 3.55, gone: 4.0)
    textCentered("マイクがオンの間だけ、部屋のBGMを下げる", Face.semi(46), Palette.inkSoft,
                 centerX: W / 2, y: H / 2 - 188, alpha: subA)
}

private func drawProblem(_ t: Double) {
    let a = fadeInOut(t, in: 3.7, hold: 4.4, out: 10.3, gone: 10.8)
    guard a > 0.001 else { return }

    // 音楽が鳴っている側
    let sp = NSPoint(x: 470, y: H / 2 + 120)
    let f = Face.emoji(112)
    let g = measure("🔊", f)
    text("🔊", f, .white, at: NSPoint(x: sp.x - g.width / 2, y: sp.y - g.height / 2), alpha: a)
    soundWaves(from: NSPoint(x: sp.x + 78, y: sp.y), level: 1, phase: t * 2.2,
               alpha: a, color: Palette.warn)
    textCentered("部屋のスピーカー", Face.body(30), Palette.paperOnDark.withAlphaComponent(0.62),
                 centerX: sp.x, y: sp.y - 132, alpha: a)

    // 喋っている側
    let mp = NSPoint(x: W - 470, y: H / 2 + 120)
    let g2 = measure("🎙", f)
    text("🎙", f, .white, at: NSPoint(x: mp.x - g2.width / 2, y: mp.y - g2.height / 2), alpha: a)
    textCentered("音声入力", Face.body(30), Palette.paperOnDark.withAlphaComponent(0.62),
                 centerX: mp.x, y: mp.y - 132, alpha: a)

    // 音がマイクへ回り込む線
    let flow = progress(t, 5.4, 6.6)
    if flow > 0.01 {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: sp.x + 210, y: sp.y + 30))
        let endX = lerp(Double(sp.x + 210), Double(mp.x - 96), easeInOut(flow))
        path.curve(to: NSPoint(x: endX, y: sp.y + 30),
                   controlPoint1: NSPoint(x: sp.x + 380, y: sp.y + 150),
                   controlPoint2: NSPoint(x: endX - 180, y: sp.y + 150))
        Palette.warn.withAlphaComponent(a * 0.85).setStroke()
        path.lineWidth = 7
        path.lineCapStyle = .round
        let dash: [CGFloat] = [22, 16]
        path.setLineDash(dash, count: 2, phase: CGFloat(-t * 90))
        path.stroke()
    }

    // 混ざった結果
    let cardRect = NSRect(x: 420, y: 250, width: 1080, height: 178)
    let cardA = fadeInOut(t, in: 6.4, hold: 6.9, out: 10.3, gone: 10.8)
    transcriptCard(cardRect, alpha: cardA,
                   clean: "議事録から箇条書きにして",
                   dirty: "君と歩いた あの日の",
                   dirtyAlpha: fadeInOut(t, in: 7.4, hold: 7.9, out: 10.3, gone: 10.8))

    caption("音声入力に、部屋の音楽が混ざる", t, (4.9, 5.5, 10.2, 10.6), onDark: true, y: 120)
}

private func drawWhy(_ t: Double) {
    let headA = fadeInOut(t, in: 10.6, hold: 11.4, out: 16.9, gone: 17.45)
    textCentered("ほかのアプリが下げてくれるのは、Mac につないだスピーカーだけ",
                 Face.bold(54), Palette.ink, centerX: W / 2, y: H - 232, alpha: headA)

    let cw: CGFloat = 700, ch: CGFloat = 330
    let y = H / 2 - 230

    let leftA = fadeInOut(t, in: 11.2, hold: 11.9, out: 16.9, gone: 17.45)
    let lr = NSRect(x: W / 2 - cw - 30, y: y, width: cw, height: ch)
    card(lr, radius: 22, alpha: leftA)
    text("✓  自動で下がる", Face.bold(38), Palette.ok,
         at: NSPoint(x: lr.minX + 46, y: lr.maxY - 96), alpha: leftA)
    text("Mac につないだスピーカー", Face.semi(42), Palette.ink,
         at: NSPoint(x: lr.minX + 46, y: lr.minY + 128), alpha: leftA)
    text("Bluetooth・USB・AirPlay など", Face.body(30), Palette.inkFaint,
         at: NSPoint(x: lr.minX + 46, y: lr.minY + 66), alpha: leftA)

    let rightA = fadeInOut(t, in: 11.8, hold: 12.5, out: 16.9, gone: 17.45)
    let rr = NSRect(x: W / 2 + 30, y: y, width: cw, height: ch)
    card(rr, radius: 22, alpha: rightA)
    text("✕  下がらない", Face.bold(38), Palette.accent,
         at: NSPoint(x: rr.minX + 46, y: rr.maxY - 96), alpha: rightA)
    text("Sonos / Google Home", Face.semi(42), Palette.ink,
         at: NSPoint(x: rr.minX + 46, y: rr.minY + 128), alpha: rightA)
    text("スピーカー自身が鳴らしているため", Face.body(30), Palette.inkFaint,
         at: NSPoint(x: rr.minX + 46, y: rr.minY + 66), alpha: rightA)

    caption("Mac が持っていない音は、Mac には止められない", t, (13.8, 14.4, 16.8, 17.2))
}

private func drawFix(_ t: Double) {
    let a = fadeInOut(t, in: 17.1, hold: 17.9, out: 26.0, gone: 26.5)
    guard a > 0.001 else { return }

    // マイクが開いている区間。下げる・戻すはここから逆算する。
    let micOn = t >= 19.0 && t < 23.4
    let duck = easeInOut(progress(t, 19.1, 19.5)) - easeInOut(progress(t, 23.5, 24.0))
    let volume = lerp(20, 6, min(max(duck, 0), 1))

    // 左の柱：アプリの状態。上から badge → chip の順に、重ならない高さへ置く。
    appBadge(center: NSPoint(x: 320, y: 706), side: 168, alpha: a,
             glyph: micOn ? "🙉" : "🐵")
    let pop = max(fadeInOut(t, in: 19.0, hold: 19.12, out: 19.2, gone: 19.55),
                  fadeInOut(t, in: 23.4, hold: 23.52, out: 23.6, gone: 23.95))
    stateChip(center: NSPoint(x: 320, y: 552), ducking: micOn, alpha: a, pop: pop)

    // 右の柱：きっかけ（マイク）→ 効き目（音量）→ 結果（文字起こし）の順に上から並べる。
    let colX: CGFloat = 620
    let micColor = micOn ? Palette.accent : Palette.inkFaint
    let f = Face.emoji(54)
    let g = measure("🎙", f)
    text("🎙", f, .white, at: NSPoint(x: colX, y: 790 - g.height / 2), alpha: a)
    text(micOn ? "マイク ON" : "マイク OFF", Face.semi(40), micColor,
         at: NSPoint(x: colX + g.width + 18, y: 790 - 20), alpha: a)
    if micOn {
        soundWaves(from: NSPoint(x: colX + g.width + 300, y: 790),
                   level: 0.7, phase: t * 3, alpha: a * 0.9, color: Palette.accent)
    }

    volumeBar(NSRect(x: colX, y: 600, width: 880, height: 42),
              value: volume, origin: 20, alpha: a, label: "部屋のBGMの音量")

    let cardA = fadeInOut(t, in: 20.0, hold: 20.5, out: 26.0, gone: 26.5)
    transcriptCard(NSRect(x: colX, y: 322, width: 1020, height: 176), alpha: cardA,
                   clean: "議事録から箇条書きにして",
                   typed: easeOut(progress(t, 20.2, 21.6)))

    caption("喋っている間だけ、部屋を静かにする", t, (19.6, 20.2, 22.6, 23.0))
    caption("話し終われば、元の音量に戻る", t, (23.9, 24.5, 25.9, 26.3))
}

private func drawSetup(_ t: Double) {
    let a = fadeInOut(t, in: 26.2, hold: 26.9, out: 29.4, gone: 29.9)
    guard a > 0.001 else { return }

    if let shot = settingsShot {
        let h: CGFloat = 720
        let w = h * (shot.size.width / max(shot.size.height, 1))
        let r = NSRect(x: 300, y: H / 2 - h / 2, width: w, height: h)
        NSGraphicsContext.saveGraphicsState()
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.2 * a)
        sh.shadowOffset = NSSize(width: 0, height: -12)
        sh.shadowBlurRadius = 40
        sh.set()
        roundedRect(r, radius: 16, fill: .white, alpha: a)
        NSGraphicsContext.restoreGraphicsState()
        shot.draw(in: r, from: .zero, operation: .sourceOver, fraction: a)
        roundedRect(r, radius: 16, fill: nil, stroke: Palette.line, lineWidth: 1, alpha: a)
    }

    let x: CGFloat = 1010
    text("設定はこれだけ", Face.bold(64), Palette.ink,
         at: NSPoint(x: x, y: H / 2 + 96), alpha: a)
    text("同じネットワークのスピーカーが自動で並びます。", Face.body(38), Palette.inkSoft,
         at: NSPoint(x: x, y: H / 2 + 16), alpha: a)
    text("下げたいものにチェックを入れるだけ。", Face.semi(38), Palette.ink,
         at: NSPoint(x: x, y: H / 2 - 44), alpha: a)
    text("IP アドレスの入力は要りません。", Face.body(34), Palette.inkFaint,
         at: NSPoint(x: x, y: H / 2 - 116), alpha: a)
}

private func drawCTA(_ t: Double) {
    let a = fadeInOut(t, in: 29.6, hold: 30.3, out: 33.6, gone: 33.7)
    guard a > 0.001 else { return }
    appBadge(center: NSPoint(x: W / 2, y: H / 2 + 196), side: 176, alpha: a, onDark: true)
    textCentered("Kikazaru", Face.bold(120), Palette.paperOnDark,
                 centerX: W / 2, y: H / 2 - 26, alpha: a, kern: -3)

    let metaA = fadeInOut(t, in: 30.3, hold: 30.9, out: 33.6, gone: 33.7)
    textCentered("macOS 14 以降　/　無料　/　約 400 KB", Face.body(38),
                 Palette.paperOnDark.withAlphaComponent(0.6),
                 centerX: W / 2, y: H / 2 - 116, alpha: metaA)

    let urlA = fadeInOut(t, in: 30.7, hold: 31.3, out: 33.6, gone: 33.7)
    let label = "kikazaru.koji-okada.workers.dev"
    let f = Face.semi(44)
    let s = measure(label, f)
    roundedRect(NSRect(x: W / 2 - s.width / 2 - 40, y: H / 2 - 246,
                       width: s.width + 80, height: 92),
                radius: 46, fill: Palette.accent, alpha: urlA)
    textCentered(label, f, .white, centerX: W / 2, y: H / 2 - 220, alpha: urlA)
}

// MARK: - 1枚の絵

func drawFrame(_ t: Double, _ ctx: CGContext) {
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    background(t, ctx)
    drawLogo(t)
    drawProblem(t)
    drawWhy(t)
    drawFix(t)
    drawSetup(t)
    drawCTA(t)
}
