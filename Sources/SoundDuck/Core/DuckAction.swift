import Foundation

/// 「下げる」「戻す」の 2 つだけ実装すれば、Coordinator に繋がる。
///
/// Sonos のコードを触らずに Mac 本体音量・照明・Slack ステータスなどを足せる。
/// snapshot / apply は、異常終了しても元の状態へ戻せるようにするためのもの。
protocol DuckAction: AnyObject, Sendable {
    /// 設定画面や状態表示に出す名前
    var name: String { get }

    /// 下げる。ratio は元の値に対する割合（0.3 なら 30% まで）
    func duck(ratio: Double) async

    /// 元に戻す
    func restore() async

    /// 復元に必要な情報。キーは任意の識別子（Sonos なら IP）
    func snapshot() -> [String: Int]

    /// 起動時に前回の残骸から復元する
    func apply(snapshot: [String: Int]) async
}
