import Foundation
import ServiceManagement

/// ログイン時の自動起動。
///
/// 開発中はスクリプトで LaunchAgent を置いていたが、配布された人はそれを実行できない。
/// アプリ自身が登録できる仕組みを使い、設定画面のスイッチだけで完結させる。
enum LoginItem {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// 登録に失敗したら理由を返す。成功なら nil。
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> String? {
        do {
            if enabled {
                // 一度登録済みだと再登録でエラーになるため、状態を見てから呼ぶ
                guard SMAppService.mainApp.status != .enabled else { return nil }
                try SMAppService.mainApp.register()
            } else {
                guard SMAppService.mainApp.status == .enabled else { return nil }
                try SMAppService.mainApp.unregister()
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// システム設定側で拒否されている状態。ユーザーの操作が要る。
    static var isBlockedByUser: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }
}
