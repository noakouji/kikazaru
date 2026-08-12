import Observation

/// 画面に出す状態をまとめて持つ。
///
/// 設定画面から「いま何台見つかっているか」を見せたいので、
/// 探索結果を UI と共有できる場所に置く。
@MainActor
@Observable
final class AppModel {

    enum Tab: Hashable { case settings, about }

    /// 設定画面のどのタブを開くか。別ウインドウを増やさないため状態で持つ。
    var settingsTab: Tab = .settings

    /// マイクを使ったのを見たことがあるアプリ。設定画面に並べる。
    private(set) var seenApps: [String] = []

    /// 見かけたアプリが増えたときに呼ばれる
    var onAppsChanged: (([String]) -> Void)?

    private(set) var speakers: [SpeakerControl] = []
    private(set) var isSearching = false

    /// 起動直後の「まだ探していない」と「探したが 0 台」を区別する。
    private(set) var hasSearched = false

    let action: SpeakersAction

    /// 選択状態が変わったら呼ばれる。設定の保存に使う。
    var onSelectionChange: ((Set<String>, Set<String>) -> Void)?

    init(action: SpeakersAction) {
        self.action = action
    }

    func refresh() async {
        guard !isSearching else { return }
        isSearching = true
        speakers = await action.refresh()
        isSearching = false
        hasSearched = true
        persistSelection()
    }

    /// 起動直後はネットワークがまだ整っていないことがある。
    /// 1 回の空振りで「見つかりません」と表示し続けないよう、間隔を空けて数回試す。
    func refreshWithRetry() async {
        for delay in [0.0, 2.0, 5.0, 10.0, 20.0] {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            await refresh()
            if !speakers.isEmpty { return }
        }
    }

    /// 実際に下げる対象になっている台数
    var enabledCount: Int { speakers.filter { action.isEnabled($0) }.count }

    func setSeenApps(_ apps: [String]) { seenApps = apps }

    func noteSeen(_ bundleIDs: [String]) {
        let added = bundleIDs.filter { !seenApps.contains($0) }
        guard !added.isEmpty else { return }
        seenApps.append(contentsOf: added)
        onAppsChanged?(seenApps)
    }

    func speakers(of kind: SpeakerKind) -> [SpeakerControl] {
        speakers.filter { $0.kind == kind }
    }

    func isEnabled(_ speaker: SpeakerControl) -> Bool { action.isEnabled(speaker) }

    func setEnabled(_ enabled: Bool, for speaker: SpeakerControl) {
        action.setEnabled(enabled, for: speaker)
        speakers = action.allSpeakers   // 表示を更新する
        persistSelection()
    }

    private func persistSelection() {
        onSelectionChange?(action.currentDisabledIDs, action.currentKnownIDs)
    }
}
