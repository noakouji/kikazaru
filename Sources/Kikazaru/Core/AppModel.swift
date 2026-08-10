import Observation

/// 画面に出す状態をまとめて持つ。
///
/// 設定画面から「いま何台見つかっているか」を見せたいので、
/// 探索結果を UI と共有できる場所に置く。
@MainActor
@Observable
final class AppModel {

    private(set) var rooms: [SonosDevice] = []
    private(set) var isSearching = false

    let sonos: SonosAction

    init(sonos: SonosAction) {
        self.sonos = sonos
    }

    /// 起動直後の「まだ探していない」と「探したが 0 台」を区別する。
    private(set) var hasSearched = false

    func refresh() async {
        guard !isSearching else { return }
        isSearching = true
        rooms = await sonos.refreshRooms()
        isSearching = false
        hasSearched = true
    }
}
