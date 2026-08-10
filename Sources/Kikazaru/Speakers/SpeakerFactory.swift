import Foundation

/// 保存しておいた識別子から、スピーカーを組み立て直す。
///
/// 異常終了からの復元では、まだ検出が終わっていないことがある。
/// 「見つかっていないから戻せない」で諦めると音量が下がったまま取り残されるので、
/// 識別子だけを頼りに直接つなぎに行けるようにしておく。
enum SpeakerFactory {

    /// 識別子は "種別:ホスト" の形。IPv6 を含むためホスト側の区切りは分割しない。
    static func make(id: String) -> SpeakerControl? {
        let parts = id.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, !parts[1].isEmpty else { return nil }
        let host = parts[1]

        switch parts[0] {
        case SpeakerKind.sonos.rawValue:
            return SonosSpeaker(device: SonosDevice(ip: host, roomName: host))
        case SpeakerKind.bose.rawValue:
            return BoseSpeaker(host: host, name: host)
        case SpeakerKind.googleCast.rawValue:
            return CastSpeaker(host: host, name: host)
        default:
            return nil
        }
    }
}
