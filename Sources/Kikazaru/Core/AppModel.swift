import Observation

/// 画面に出す状態をまとめて持つ。
///
/// 設定画面から「いま何台見つかっているか」を見せたいので、
/// 探索結果を UI と共有できる場所に置く。
@MainActor
@Observable
final class AppModel {

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
