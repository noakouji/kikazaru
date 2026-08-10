import Foundation

/// Sonos の全ルームを下げる／戻すアクション。
///
/// グループ再生中は各機が自分の音量を持つため、可視メンバー全員を並列に制御する。
/// ルーム数が増えても所要時間は伸びない。
final class SonosAction: DuckAction, @unchecked Sendable {

    let name = "Sonos"

    private let floor: Int
    private let fadeSteps: Int
    private let lock = NSLock()
    private var rooms: [SonosDevice] = []
    private var saved: [String: Int] = [:]

    init(floor: Int = 3, fadeSteps: Int = 5) {
        self.floor = floor
        self.fadeSteps = fadeSteps
    }

    // MARK: - 対象の管理

    var currentRooms: [SonosDevice] {
        lock.withLock { rooms }
    }

    /// LAN を探して制御対象を取り直す。グループの組み替えに追従するため定期的に呼ぶ。
    @discardableResult
    func refreshRooms() async -> [SonosDevice] {
        let ips = await SonosDiscovery.discover()
        guard !ips.isEmpty else { return currentRooms }
        let found = await SonosTopology.rooms(askingAnyOf: ips)
        guard !found.isEmpty else { return currentRooms }
        lock.withLock { rooms = found }
        return found
    }

    // MARK: - DuckAction

    func duck(ratio: Double) async {
        let targets = currentRooms
        guard !targets.isEmpty, lock.withLock({ saved.isEmpty }) else { return }

        let results = await withTaskGroup(of: (String, Int)?.self) { group in
            for room in targets {
                group.addTask { [floor, fadeSteps] in
                    guard let original = try? await room.volume() else { return nil }
                    let target = max(floor, min(original, Int((Double(original) * ratio).rounded())))
                    guard target < original else { return nil }
                    await room.fade(from: original, to: target, steps: fadeSteps)
                    return (room.ip, original)
                }
            }
            var acc: [(String, Int)] = []
            for await result in group {
                if let result { acc.append(result) }
            }
            return acc
        }

        lock.withLock {
            for (ip, original) in results { saved[ip] = original }
        }
    }

    func restore() async {
        let snapshot = lock.withLock { saved }
        guard !snapshot.isEmpty else { return }
        await apply(snapshot: snapshot)
        lock.withLock { saved.removeAll() }
    }

    func snapshot() -> [String: Int] {
        lock.withLock { saved }
    }

    func apply(snapshot: [String: Int]) async {
        let known = Dictionary(uniqueKeysWithValues: currentRooms.map { ($0.ip, $0) })
        await withTaskGroup(of: Void.self) { group in
            for (ip, original) in snapshot {
                let room = known[ip] ?? SonosDevice(ip: ip, roomName: ip)
                group.addTask { [fadeSteps] in
                    let from = (try? await room.volume()) ?? original
                    await room.fade(from: from, to: original, steps: fadeSteps)
                }
            }
        }
    }
}
