import Foundation

/// 説明用のスクリーンショットに並べる架空のスピーカー。
///
/// 実機を並べると自宅の部屋名がそのまま公開物に載ってしまうので、
/// 配布サイトや説明画像には必ずこちらを使う。通信は一切しない。
final class DemoSpeaker: SpeakerControl {
    let id: String
    let name: String
    let kind: SpeakerKind

    init(id: String, name: String, kind: SpeakerKind) {
        self.id = id
        self.name = name
        self.kind = kind
    }

    func volume() async throws -> Int { 20 }
    func setVolume(_ value: Int) async throws {}

    /// 書き出し用の一式。Sonos は有効、Google Home は既定どおり無効で見せる。
    static func sample() -> [SpeakerControl] {
        [
            DemoSpeaker(id: "sonos:demo-1", name: L10n.t("リビング", "Living Room"), kind: .sonos),
            DemoSpeaker(id: "sonos:demo-2", name: L10n.t("書斎", "Study"), kind: .sonos),
            DemoSpeaker(id: "googleCast:demo-1", name: L10n.t("キッチン", "Kitchen"), kind: .googleCast),
            DemoSpeaker(id: "googleCast:demo-2", name: L10n.t("寝室", "Bedroom"), kind: .googleCast),
        ]
    }
}
