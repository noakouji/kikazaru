import AppKit

/// アイコンをコードで描く。
///
/// 画像ファイルを持たないので、どの解像度でも滲まず、ライト／ダークにも自動で追従する。
/// メニューバー用はテンプレート画像にして、OS 側に色を任せる。
///
/// 図案は三猿の「聞かざる」。待機中は耳を開け、下げている間は手で耳を塞ぐ。
/// シルエットが横に広がるので、18px でも状態の差が読み取れる。
enum AppIcon {

    /// メニューバー用（18pt）
    static func menuBar(ducked: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            draw(ducked: ducked, in: 18, color: .black)
            return true
        }
        image.isTemplate = true
        return image
    }

    /// 設定画面のヘッダー用。丸背景に白で描く。
    static func appIcon(size: CGFloat = 64) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let background = NSBezierPath(roundedRect: rect,
                                          xRadius: size * 0.22, yRadius: size * 0.22)
            NSGradient(colors: [
                NSColor(calibratedRed: 0.36, green: 0.28, blue: 0.22, alpha: 1),
                NSColor(calibratedRed: 0.22, green: 0.16, blue: 0.13, alpha: 1),
            ])?.draw(in: background, angle: -90)

            // タイルの縁に余白を作るため、少し縮めて中央に描く
            let inset = size * 0.11
            NSGraphicsContext.current?.saveGraphicsState()
            let move = NSAffineTransform()
            move.translateX(by: inset, yBy: inset)
            move.concat()
            draw(ducked: true, in: size - inset * 2, color: .white,
                 eyeColor: NSColor(calibratedRed: 0.25, green: 0.18, blue: 0.14, alpha: 1))
            NSGraphicsContext.current?.restoreGraphicsState()
            return true
        }
    }

    // MARK: - 描画

    /// 18x18 を基準に描き、指定サイズへ拡大する。
    ///
    /// `eyeColor` が nil のときは目を「くり抜く」。単色のテンプレート画像で表情を出すための処理で、
    /// 背景を持つアプリアイコンでは抜くと透明になって見えないため、色を指定して塗る。
    private static func draw(ducked: Bool, in side: CGFloat,
                             color: NSColor, eyeColor: NSColor? = nil) {
        let s = side / 18
        color.setFill()
        func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }
        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> NSBezierPath {
            NSBezierPath(ovalIn: NSRect(x: (x - r) * s, y: (y - r) * s,
                                        width: r * 2 * s, height: r * 2 * s))
        }

        // 耳。塞ぐときは手の下に隠れるので、開いているときだけ描く。
        // 手より一回り小さくして、塞いだときにシルエットが明確に広がるようにする。
        if !ducked {
            circle(3.9, 10.2, 1.8).fill()
            circle(14.1, 10.2, 1.8).fill()
        }

        // 顔。上が広く下がすぼまった輪郭にして猿らしさを出す。
        let face = NSBezierPath()
        face.move(to: p(4.6, 11.6))
        face.curve(to: p(13.4, 11.6), controlPoint1: p(5.6, 16.4), controlPoint2: p(12.4, 16.4))
        face.curve(to: p(9.0, 2.6), controlPoint1: p(14.6, 7.0), controlPoint2: p(12.6, 2.6))
        face.curve(to: p(4.6, 11.6), controlPoint1: p(5.4, 2.6), controlPoint2: p(3.4, 7.0))
        face.close()
        face.fill()

        // 目
        NSGraphicsContext.current?.saveGraphicsState()
        if let eyeColor {
            eyeColor.setFill()
        } else {
            NSGraphicsContext.current?.compositingOperation = .destinationOut
            NSColor.black.setFill()
        }
        if ducked {
            // 塞いでいるときは目を閉じる。丸は描かず横棒だけにする。
            for x in [6.2 as CGFloat, 9.8] {
                NSBezierPath(roundedRect: NSRect(x: x * s, y: 9.0 * s,
                                                 width: 2.0 * s, height: 0.85 * s),
                             xRadius: 0.42 * s, yRadius: 0.42 * s).fill()
            }
        } else {
            circle(7.2, 9.4, 1.05).fill()
            circle(10.8, 9.4, 1.05).fill()
        }
        NSGraphicsContext.current?.restoreGraphicsState()

        // 手。耳より大きく、上下にも張り出させてシルエットの差を作る。
        if ducked {
            color.setFill()
            handPath(centerX: 3.1, in: s).fill()
            handPath(centerX: 14.9, in: s).fill()
        }
    }

    /// 耳を塞ぐ手。縦長の丸みのある塊にして、シルエットを横へ張り出させる。
    private static func handPath(centerX: CGFloat, in s: CGFloat) -> NSBezierPath {
        let rect = NSRect(x: (centerX - 2.6) * s, y: 5.2 * s, width: 5.2 * s, height: 8.6 * s)
        return NSBezierPath(roundedRect: rect, xRadius: 2.6 * s, yRadius: 2.6 * s)
    }
}
