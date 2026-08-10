import Foundation

/// 音量を上げ下げできるスピーカー 1 台。
///
/// メーカーごとに通信方法は違うが、Kikazaru が必要とするのは
/// 「いまの音量を読む」「音量を変える」の 2 つだけ。
/// ここを揃えておけば、対応機種を増やしても上位の処理は変わらない。
protocol SpeakerControl: AnyObject, Sendable {
    /// 重複判定と保存に使う一意な識別子
    var id: String { get }
    /// 画面に出す名前（部屋名など）
    var name: String { get }
    /// どの種類か
    var kind: SpeakerKind { get }

    func volume() async throws -> Int
    func setVolume(_ value: Int) async throws
}

enum SpeakerKind: String, Sendable, CaseIterable {
    case sonos, bose, googleCast

    var label: String {
        switch self {
        case .sonos: return "Sonos"
        case .bose: return "Bose SoundTouch"
        case .googleCast: return L10n.t("Google Home / Chromecast", "Google Home / Chromecast")
        }
    }

    /// 動作確認の状況を正直に出す。実機で確認できていないものは画面上でもそう伝える。
    /// Sonos と Google Home は実機で読み書きを確認済み。Bose は実機がなく未確認。
    var isVerified: Bool { self != .bose }
}

extension SpeakerControl {
    /// 段階的に音量を変える。急な変化を避けつつ、全体で 100ms 前後に収める。
    func fade(from start: Int, to end: Int, steps: Int) async {
        guard steps > 0 else { return }
        for i in 1...steps {
            try? await setVolume(start + (end - start) * i / steps)
        }
    }
}
