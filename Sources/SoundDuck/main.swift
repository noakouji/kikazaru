import Foundation

// 1周目: Sonos 制御層の動作確認用エントリ。
// メニューバー UI を載せる段階で AppDelegate に差し替える。

let start = Date()
print("=== SSDP 検出 ===")
let ips = await SonosDiscovery.discover()
print("  \(ips.count)台 / \(String(format: "%.1f", Date().timeIntervalSince(start)))秒")
for ip in ips {
    let name = await SonosDiscovery.roomName(ip: ip) ?? "?"
    print("    \(ip)  \(name)")
}

print("\n=== 制御対象（可視メンバーのみ）===")
let rooms = await SonosTopology.rooms(askingAnyOf: ips)
if rooms.isEmpty {
    print("  ❌ 取得できませんでした")
    exit(1)
}
for room in rooms {
    let v = (try? await room.volume()).map(String.init) ?? "?"
    print("    \(room.ip)  \(room.roomName)  音量=\(v)")
}

print("\n=== SetVolume 往復レイテンシ ===")
guard let target = rooms.first else { exit(1) }
let original = try await target.volume()
var samples: [Double] = []
for i in 0..<5 {
    let t = Date()
    try await target.setVolume(i % 2 == 0 ? original : original - 1)
    samples.append(Date().timeIntervalSince(t) * 1000)
}
try await target.setVolume(original)
let avg = samples.reduce(0, +) / Double(samples.count)
print(String(format: "  平均 %.0fms / 最小 %.0fms / 最大 %.0fms", avg, samples.min()!, samples.max()!))

print("\n=== フェード動作（全ルーム並列）===")
await withTaskGroup(of: Void.self) { group in
    for room in rooms {
        group.addTask {
            guard let from = try? await room.volume() else { return }
            let to = max(3, Int(Double(from) * 0.3))
            let t = Date()
            await room.fade(from: from, to: to, steps: 5)
            let down = Date().timeIntervalSince(t) * 1000
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await room.fade(from: to, to: from, steps: 5)
            print(String(format: "    %@  %d → %d → %d  (下げ %.0fms)",
                         room.roomName, from, to, from, down))
        }
    }
}

print("\n=== 復元確認 ===")
for room in rooms {
    let v = (try? await room.volume()).map(String.init) ?? "?"
    print("    \(room.roomName)  音量=\(v)")
}
