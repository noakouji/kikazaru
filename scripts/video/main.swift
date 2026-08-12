import AppKit

// 紹介動画のコマを書き出す。
//
//   render <出力先> [--fps 30] [--at 5.2]
//
// --at を渡すと、その1秒だけを1枚書き出す。作りながら確認するため。

let args = CommandLine.arguments
func flag(_ name: String) -> String? {
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}

let outDir = args.dropFirst().first(where: { !$0.hasPrefix("--") }) ?? "build/video/frames"
let fps = Double(flag("--fps") ?? "30") ?? 30
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

/// ビットマップへ直接描く。
/// NSImage の lockFocus は画面の倍率を拾って 2 倍の絵になるうえ、
/// 大量に呼ぶと途中で描けなくなることがある（実際に 472 枚落ちた）。
func render(_ t: Double) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(W), pixelsHigh: Int(H),
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
        let gc = NSGraphicsContext(bitmapImageRep: rep)
    else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gc
    drawFrame(t, gc.cgContext)
    gc.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

if let at = flag("--at"), let t = Double(at) {
    guard let data = render(t) else { print("❌ 描けませんでした"); exit(1) }
    let path = "\(outDir)/at-\(at).png"
    try! data.write(to: URL(fileURLWithPath: path))
    print("✅ \(path)")
    exit(0)
}

let total = Int((Cut.total * fps).rounded())
var failed: [Int] = []
for i in 0..<total {
    let t = Double(i) / fps
    guard let data = render(t) else { failed.append(i); continue }
    do {
        try data.write(to: URL(fileURLWithPath: String(format: "\(outDir)/%05d.png", i)))
    } catch {
        failed.append(i)
    }
    if i % 120 == 0 { print("… \(i)/\(total)") }
}

if failed.isEmpty {
    print("✅ \(total) 枚 / \(String(format: "%.1f", Cut.total))秒 → \(outDir)")
} else {
    // 黙って飛ばすと、動画になってから初めて気づくことになる。
    print("❌ \(failed.count) 枚が書き出せませんでした: \(failed.prefix(10))")
    exit(1)
}
