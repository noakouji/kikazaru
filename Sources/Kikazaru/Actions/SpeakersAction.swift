import Foundation

/// 見つかったスピーカーをまとめて下げる／戻す。
///
/// メーカーごとの違いは SpeakerControl の内側に閉じているので、
/// ここは「全台を並列に処理する」ことだけを担当する。台数が増えても所要時間は伸びない。
final class SpeakersAction: DuckAction, @unchecked Sendable {

    let name = "Speakers"

    private let floor: Int
    private let fadeSteps: Int
    private let lock = NSLock()
    private var speakers: [SpeakerControl] = []
    private var disabledIDs: Set<String> = []
    private var knownIDs: Set<String> = []
    private var saved: [String: Int] = [:]

    init(floor: Int = 3, fadeSteps: Int = 5) {
        self.floor = floor
        self.fadeSteps = fadeSteps
    }

    // MARK: - 対象の管理

    var allSpeakers: [SpeakerControl] { lock.withLock { speakers } }

    var activeSpeakers: [SpeakerControl] {
        lock.withLock { speakers.filter { !disabledIDs.contains($0.id) } }
    }

    func isEnabled(_ speaker: SpeakerControl) -> Bool {
        lock.withLock { !disabledIDs.contains(speaker.id) }
    }

    func setEnabled(_ enabled: Bool, for speaker: SpeakerControl) {
        lock.withLock {
            if enabled { disabledIDs.remove(speaker.id) } else { disabledIDs.insert(speaker.id) }
        }
    }

    /// 保存しておいた選択状態を復元する。
    func restoreSelection(disabled: Set<String>, known: Set<String>) {
        lock.withLock {
            disabledIDs = disabled
            knownIDs = known
        }
    }

    var currentDisabledIDs: Set<String> { lock.withLock { disabledIDs } }
    var currentKnownIDs: Set<String> { lock.withLock { knownIDs } }

    /// 全メーカーを並行して探す。見つからないメーカーがあっても他は使える。
    @discardableResult
    func refresh(kinds: Set<SpeakerKind> = Set(SpeakerKind.allCases)) async -> [SpeakerControl] {
        var found: [SpeakerControl] = []
        await withTaskGroup(of: [SpeakerControl].self) { group in
            if kinds.contains(.sonos) { group.addTask { await SonosSpeaker.discover() } }
            if kinds.contains(.bose) { group.addTask { await BoseSpeaker.discover() } }
            if kinds.contains(.googleCast) { group.addTask { await CastSpeaker.discover() } }
            for await result in group { found.append(contentsOf: result) }
        }
        let sorted = found.sorted { ($0.kind.rawValue, $0.name) < ($1.kind.rawValue, $1.name) }
        lock.withLock {
            speakers = sorted
            // 初めて見つけた機器のうち、Sonos 以外は既定でオフにする。
            // テレビなど「下げてほしくないもの」を勝手に操作しないため。
            for speaker in sorted where !knownIDs.contains(speaker.id) {
                knownIDs.insert(speaker.id)
                if speaker.kind != .sonos { disabledIDs.insert(speaker.id) }
            }
        }
        return sorted
    }

    // MARK: - DuckAction

    func duck(ratio: Double) async {
        let targets = activeSpeakers
        guard !targets.isEmpty, lock.withLock({ saved.isEmpty }) else { return }

        let results = await withTaskGroup(of: (String, Int)?.self) { group in
            for speaker in targets {
                group.addTask { [floor, fadeSteps] in
                    guard let original = try? await speaker.volume() else { return nil }
                    let target = max(floor, min(original, Int((Double(original) * ratio).rounded())))
                    guard target < original else { return nil }
                    await speaker.fade(from: original, to: target, steps: fadeSteps)
                    return (speaker.id, original)
                }
            }
            var acc: [(String, Int)] = []
            for await result in group where result != nil { acc.append(result!) }
            return acc
        }
        lock.withLock { for (id, original) in results { saved[id] = original } }
    }

    func restore() async {
        let snapshot = lock.withLock { saved }
        guard !snapshot.isEmpty else { return }
        await apply(snapshot: snapshot)
        lock.withLock { saved.removeAll() }
    }

    func snapshot() -> [String: Int] { lock.withLock { saved } }

    @discardableResult
    func apply(snapshot: [String: Int]) async -> Bool {
        let known = Dictionary(uniqueKeysWithValues: allSpeakers.map { ($0.id, $0) })
        let results = await withTaskGroup(of: Bool.self) { group in
            for (id, original) in snapshot {
                // 検出が終わっていなくても、識別子から直接つなぎに行く。
                // ここで諦めると音量が下がったまま取り残される。
                guard let speaker = known[id] ?? SpeakerFactory.make(id: id) else { continue }
                group.addTask { [fadeSteps] in
                    guard let from = try? await speaker.volume() else { return false }
                    await speaker.fade(from: from, to: original, steps: fadeSteps)
                    return ((try? await speaker.volume()) ?? original) == original
                }
            }
            var all: [Bool] = []
            for await ok in group { all.append(ok) }
            return all
        }
        return !results.contains(false)
    }
}
