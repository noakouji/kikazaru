import Foundation

/// Sonos を共通の形に合わせる。
///
/// 検出とグループ構成の解析は Sonos 固有の処理が多いので、
/// 既存の実装をそのまま使い、外向きの顔だけ揃える。
final class SonosSpeaker: SpeakerControl, @unchecked Sendable {

    let id: String
    let name: String
    let kind: SpeakerKind = .sonos
    private let device: SonosDevice

    init(device: SonosDevice) {
        self.device = device
        self.id = "sonos:\(device.ip)"
        self.name = device.roomName
    }

    func volume() async throws -> Int { try await device.volume() }
    func setVolume(_ value: Int) async throws { try await device.setVolume(value) }

    /// 音量を個別に持つ可視メンバーだけを返す。
    /// サテライト（Sub・サラウンド）は親機に追従するので含めない。
    static func discover() async -> [SpeakerControl] {
        let ips = await SonosDiscovery.discover()
        guard !ips.isEmpty else { return [] }
        return await SonosTopology.rooms(askingAnyOf: ips).map(SonosSpeaker.init)
    }
}
