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
    ///
    /// 経路を 2 つ持つ。SSDP は生のマルチキャストを使うため、
    /// ローカルネットワークの許可が下りていないと無音で失敗する。
    /// その場合でも Bonjour 経由なら見つかるので、両方試す。
    static func discover() async -> [SpeakerControl] {
        var ips = await SonosDiscovery.discover()
        if ips.isEmpty {
            ips = await BonjourBrowser.hosts(ofType: "_sonos._tcp", timeout: 3)
        }
        guard !ips.isEmpty else { return [] }
        return await SonosTopology.rooms(askingAnyOf: ips).map(SonosSpeaker.init)
    }
}
