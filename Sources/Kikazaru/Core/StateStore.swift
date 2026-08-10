import Foundation

/// 下げた時点の元の音量をディスクに残す。
///
/// 強制終了で落ちても、次回起動時にここから元へ戻せるようにするのが目的。
/// 「音量が下がったまま取り残される」が最も影響の大きい事故なので、
/// 終了処理に頼らず、下げた瞬間に書く。
enum StateStore {

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Kikazaru", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("pending-restore.json")
    }

    /// アクション名 → スナップショット
    static func save(_ snapshots: [String: [String: Int]]) {
        if snapshots.allSatisfy({ $0.value.isEmpty }) {
            clear()
            return
        }
        guard let data = try? JSONEncoder().encode(snapshots) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    static func load() -> [String: [String: Int]]? {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: [String: Int]].self, from: data),
              !decoded.isEmpty
        else { return nil }
        return decoded
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
