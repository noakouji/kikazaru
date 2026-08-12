import AppKit

// 描画の下ごしらえ。色・イージング・文字と図形の置き方をここに集める。
// シーンごとの記述（Scenes.swift）を「何を描くか」だけに保つため。

enum Palette {
    static let paper = NSColor(srgbRed: 0.969, green: 0.961, blue: 0.945, alpha: 1)
    static let paperDeep = NSColor(srgbRed: 0.937, green: 0.922, blue: 0.894, alpha: 1)
    static let ink = NSColor(srgbRed: 0.106, green: 0.102, blue: 0.122, alpha: 1)
    static let inkSoft = NSColor(srgbRed: 0.333, green: 0.322, blue: 0.361, alpha: 1)
    static let inkFaint = NSColor(srgbRed: 0.545, green: 0.529, blue: 0.573, alpha: 1)
    static let line = NSColor(srgbRed: 0.867, green: 0.843, blue: 0.804, alpha: 1)
    static let dark = NSColor(srgbRed: 0.090, green: 0.078, blue: 0.098, alpha: 1)
    static let accent = NSColor(srgbRed: 0.706, green: 0.384, blue: 0.184, alpha: 1)
    static let accentSoft = NSColor(srgbRed: 0.941, green: 0.886, blue: 0.839, alpha: 1)
    static let ok = NSColor(srgbRed: 0.247, green: 0.490, blue: 0.329, alpha: 1)
    static let okBright = NSColor(srgbRed: 0.498, green: 0.855, blue: 0.631, alpha: 1)
    static let warn = NSColor(srgbRed: 1.0, green: 0.616, blue: 0.420, alpha: 1)
    static let paperOnDark = NSColor(srgbRed: 0.937, green: 0.914, blue: 0.886, alpha: 1)
}

/// 0〜1 の進み具合。start より前は 0、end より後は 1。
func progress(_ t: Double, _ start: Double, _ end: Double) -> Double {
    guard end > start else { return t >= end ? 1 : 0 }
    return min(max((t - start) / (end - start), 0), 1)
}

/// 立ち上がりが速く、終わりで静かに止まる。UI の動きに一番なじむ。
func easeOut(_ x: Double) -> Double { 1 - pow(1 - x, 3) }
func easeInOut(_ x: Double) -> Double {
    x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
}

/// 出て、しばらく留まり、消える。テロップの寿命をこれ1本で書く。
func fadeInOut(_ t: Double, in a: Double, hold b: Double, out c: Double, gone d: Double) -> Double {
    if t < a { return 0 }
    if t < b { return easeOut(progress(t, a, b)) }
    if t < c { return 1 }
    if t < d { return 1 - easeOut(progress(t, c, d)) }
    return 0
}

func lerp(_ a: Double, _ b: Double, _ x: Double) -> Double { a + (b - a) * x }

// MARK: - 書体

enum Face {
    static func bold(_ size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .heavy)
    }
    static func semi(_ size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .semibold)
    }
    static func body(_ size: CGFloat) -> NSFont {
        NSFont.systemFont(ofSize: size, weight: .medium)
    }
    static func mono(_ size: CGFloat) -> NSFont {
        NSFont.monospacedSystemFont(ofSize: size, weight: .bold)
    }
    static func emoji(_ size: CGFloat) -> NSFont {
        NSFont(name: "Apple Color Emoji", size: size) ?? NSFont.systemFont(ofSize: size)
    }
}

// MARK: - 文字

/// 左下を原点に文字を置く。戻り値は描いた大きさ。
@discardableResult
func text(_ s: String, _ font: NSFont, _ color: NSColor,
          at p: NSPoint, alpha: Double = 1, kern: CGFloat = 0) -> NSSize {
    guard alpha > 0.001 else { return .zero }
    var attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color.withAlphaComponent(color.alphaComponent * alpha),
    ]
    if kern != 0 { attrs[.kern] = kern }
    let ns = s as NSString
    ns.draw(at: p, withAttributes: attrs)
    return ns.size(withAttributes: attrs)
}

func measure(_ s: String, _ font: NSFont, kern: CGFloat = 0) -> NSSize {
    var attrs: [NSAttributedString.Key: Any] = [.font: font]
    if kern != 0 { attrs[.kern] = kern }
    return (s as NSString).size(withAttributes: attrs)
}

/// 中央揃え。x は中心。
@discardableResult
func textCentered(_ s: String, _ font: NSFont, _ color: NSColor,
                  centerX: CGFloat, y: CGFloat, alpha: Double = 1, kern: CGFloat = 0) -> NSSize {
    let size = measure(s, font, kern: kern)
    return text(s, font, color, at: NSPoint(x: centerX - size.width / 2, y: y),
                alpha: alpha, kern: kern)
}

// MARK: - 図形

func roundedRect(_ r: NSRect, radius: CGFloat, fill: NSColor?, stroke: NSColor? = nil,
                 lineWidth: CGFloat = 1, alpha: Double = 1) {
    guard alpha > 0.001 else { return }
    let path = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    if let fill {
        fill.withAlphaComponent(fill.alphaComponent * alpha).setFill()
        path.fill()
    }
    if let stroke {
        stroke.withAlphaComponent(stroke.alphaComponent * alpha).setStroke()
        path.lineWidth = lineWidth
        path.stroke()
    }
}

func circle(_ center: NSPoint, _ radius: CGFloat, fill: NSColor?, stroke: NSColor? = nil,
            lineWidth: CGFloat = 1, alpha: Double = 1) {
    let r = NSRect(x: center.x - radius, y: center.y - radius,
                   width: radius * 2, height: radius * 2)
    roundedRect(r, radius: radius, fill: fill, stroke: stroke, lineWidth: lineWidth, alpha: alpha)
}

/// 紙のざらつき。均一なベタ塗りを避ける。
///
/// 1コマにつき数万個の点を打つことになるので、1度だけ作って使い回す。
/// 毎回描き直すと、これだけで描画時間の大半を持っていかれる。
private var textureCache: [String: CGImage] = [:]

func paperTexture(_ rect: NSRect, _ ctx: CGContext, strength: Double = 0.022) {
    let key = "\(Int(rect.width))x\(Int(rect.height))@\(strength)"
    if textureCache[key] == nil {
        let w = Int(rect.width), h = Int(rect.height)
        guard let bmp = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return }
        bmp.setFillColor(NSColor.black.withAlphaComponent(strength).cgColor)
        var y = 0
        while y < h {
            var x = 0
            while x < w {
                bmp.fill(CGRect(x: x, y: y, width: 2, height: 2))
                x += 6
            }
            y += 6
        }
        textureCache[key] = bmp.makeImage()
    }
    if let image = textureCache[key] { ctx.draw(image, in: rect) }
}

/// 影付きのカード。UI の部品に見せたいときに使う。
func card(_ r: NSRect, radius: CGFloat = 18, alpha: Double = 1,
          fill: NSColor = .white, shadow: Double = 0.10) {
    guard alpha > 0.001 else { return }
    NSGraphicsContext.saveGraphicsState()
    let s = NSShadow()
    s.shadowColor = NSColor.black.withAlphaComponent(shadow * alpha)
    s.shadowOffset = NSSize(width: 0, height: -8)
    s.shadowBlurRadius = 28
    s.set()
    roundedRect(r, radius: radius, fill: fill, alpha: alpha)
    NSGraphicsContext.restoreGraphicsState()
    roundedRect(r, radius: radius, fill: nil, stroke: Palette.line, lineWidth: 1, alpha: alpha)
}
