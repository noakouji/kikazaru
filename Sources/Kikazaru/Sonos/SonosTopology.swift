import Foundation

/// ゾーン構成を解析して「音量を個別に持つ実体」を割り出す。
///
/// グループ再生中は各機が自分の音量を持つため、可視メンバー全員を制御対象にする。
/// サテライト（Sub・サラウンド）は親機に追従するので除外する。
enum SonosTopology {

    private static let service = (
        urn: "urn:schemas-upnp-org:service:ZoneGroupTopology:1",
        path: "/ZoneGroupTopology/Control"
    )

    /// 制御対象のルーム一覧を返す。どれか 1 台に問い合わせれば全体像が得られる。
    static func rooms(askingAnyOf ips: [String]) async -> [SonosDevice] {
        for ip in ips {
            if let rooms = try? await rooms(askingIP: ip), !rooms.isEmpty {
                return rooms
            }
        }
        return []
    }

    static func rooms(askingIP ip: String) async throws -> [SonosDevice] {
        let body = try await SonosDevice.soap(
            ip: ip, service: service, action: "GetZoneGroupState")
        guard let raw = SonosDevice.extract("ZoneGroupState", from: body) else {
            throw SonosError.unexpectedResponse
        }
        // 戻り値は二重 XML エスケープされている
        let state = unescape(unescape(raw))
        return parseMembers(state)
    }

    /// `<ZoneGroupMember .../>` のうち、Invisible でないものを拾う。
    /// Satellite 要素は入れ子で現れるが、タグ名が異なるので自然に除外される。
    private static func parseMembers(_ xml: String) -> [SonosDevice] {
        var result: [SonosDevice] = []
        var seen = Set<String>()
        var cursor = xml.startIndex

        while let open = xml.range(of: "<ZoneGroupMember ", range: cursor..<xml.endIndex) {
            guard let close = xml.range(of: ">", range: open.upperBound..<xml.endIndex) else { break }
            let attrs = String(xml[open.upperBound..<close.lowerBound])
            cursor = close.upperBound

            if attribute("Invisible", in: attrs) == "1" { continue }
            guard let location = attribute("Location", in: attrs),
                  let ip = ipAddress(fromLocation: location),
                  !seen.contains(ip) else { continue }
            seen.insert(ip)
            result.append(SonosDevice(ip: ip, roomName: attribute("ZoneName", in: attrs) ?? ip))
        }
        return result
    }

    private static func attribute(_ name: String, in attrs: String) -> String? {
        guard let key = attrs.range(of: "\(name)=\"") else { return nil }
        guard let end = attrs.range(of: "\"", range: key.upperBound..<attrs.endIndex) else { return nil }
        return String(attrs[key.upperBound..<end.lowerBound])
    }

    private static func ipAddress(fromLocation location: String) -> String? {
        guard let start = location.range(of: "//"),
              let end = location.range(of: ":1400", range: start.upperBound..<location.endIndex)
        else { return nil }
        return String(location[start.upperBound..<end.lowerBound])
    }

    private static func unescape(_ s: String) -> String {
        s.replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
