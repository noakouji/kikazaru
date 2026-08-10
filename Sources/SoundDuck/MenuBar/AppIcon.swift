import AppKit

/// アイコンをコードで描く。
///
/// 画像ファイルを持たないので、どの解像度でも滲まず、ライト／ダークにも自動で追従する。
/// メニューバー用はテンプレート画像にして、OS 側に色を任せる。
enum AppIcon {

    /// メニューバー用（18pt）。状態が一目で分かるよう、波の本数を変える。
    static func menuBar(ducked: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            NSColor.black.setStroke()
            speakerBody().fill()

            if ducked {
                // 下げている状態: 波は描かず下向き矢印だけにする。
                // 18px では波と矢印が重なって潰れるため、意味の強い矢印に絞る。
                downArrow().stroke()
            } else {
                // 待機状態: 波2本
                wave(radius: 3.6, lineWidth: 1.5).stroke()
                wave(radius: 6.0, lineWidth: 1.5).stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    /// 設定画面のヘッダー用。丸背景に白のスピーカーを載せる。
    static func appIcon(size: CGFloat = 64) -> NSImage {
        NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let scale = size / 18

            let background = NSBezierPath(roundedRect: rect,
                                          xRadius: size * 0.22, yRadius: size * 0.22)
            NSGradient(colors: [
                NSColor(calibratedRed: 0.20, green: 0.55, blue: 0.95, alpha: 1),
                NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.80, alpha: 1),
            ])?.draw(in: background, angle: -90)

            NSColor.white.setFill()
            NSColor.white.setStroke()
            let transform = NSAffineTransform()
            transform.scale(by: scale)

            let body = speakerBody()
            body.transform(using: transform as AffineTransform)
            body.fill()

            for radius in [3.6, 6.0] {
                let path = wave(radius: radius, lineWidth: 1.5)
                path.transform(using: transform as AffineTransform)
                path.lineWidth = 1.5 * scale
                path.stroke()
            }
            return true
        }
    }

    // MARK: - 部品（18x18 の座標系で描く）

    /// スピーカー本体。四角い駆動部と、右へ広がるコーン。
    private static func speakerBody() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 2.5, y: 6.5))
        path.line(to: NSPoint(x: 5.0, y: 6.5))
        path.line(to: NSPoint(x: 8.5, y: 3.0))
        path.line(to: NSPoint(x: 8.5, y: 15.0))
        path.line(to: NSPoint(x: 5.0, y: 11.5))
        path.line(to: NSPoint(x: 2.5, y: 11.5))
        path.close()
        return path
    }

    /// コーンの右側に広がる音の波。
    private static func wave(radius: CGFloat, lineWidth: CGFloat) -> NSBezierPath {
        let path = NSBezierPath()
        path.appendArc(withCenter: NSPoint(x: 8.5, y: 9),
                       radius: radius, startAngle: -52, endAngle: 52)
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        return path
    }

    /// 下げていることを示す矢印。スピーカーと重ならない位置に置く。
    private static func downArrow() -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: NSPoint(x: 13.3, y: 13.2))
        path.line(to: NSPoint(x: 13.3, y: 5.6))
        path.move(to: NSPoint(x: 10.8, y: 8.4))
        path.line(to: NSPoint(x: 13.3, y: 5.4))
        path.line(to: NSPoint(x: 15.8, y: 8.4))
        path.lineWidth = 1.7
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        return path
    }
}
