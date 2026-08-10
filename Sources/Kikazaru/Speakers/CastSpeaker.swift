import Foundation

/// Google Home / Chromecast。
///
/// 音量は 0.0〜1.0 の小数で扱われるので、他機種と揃えるため 0〜100 に変換する。
final class CastSpeaker: SpeakerControl, @unchecked Sendable {

    let id: String
    let name: String
    let kind: SpeakerKind = .googleCast
    private let host: String
    private var requestId = 0

    init(host: String, name: String) {
        self.host = host
        self.id = "cast:\(host)"
        self.name = name
    }

    func volume() async throws -> Int {
        let status = try await withChannel { channel in
            try await self.send(.getStatus, on: channel)
        }
        guard let level = Self.level(from: status) else { throw SpeakerError.unexpectedResponse }
        return Int((level * 100).rounded())
    }

    func setVolume(_ value: Int) async throws {
        let level = Double(max(0, min(100, value))) / 100
        _ = try await withChannel { channel in
            try await self.send(.setVolume(level), on: channel)
        }
    }

    // MARK: - 通信

    private enum Command {
        case getStatus
        case setVolume(Double)
    }

    private func send(_ command: Command, on channel: CastChannel) async throws -> [String: Any] {
        requestId += 1
        var payload: [String: Any] = ["requestId": requestId]
        switch command {
        case .getStatus:
            payload["type"] = "GET_STATUS"
        case .setVolume(let level):
            payload["type"] = "SET_VOLUME"
            payload["volume"] = ["level": level]
        }
        try await channel.send(namespace: CastChannel.Namespace.receiver, payload: payload)
        return try await channel.receive(type: "RECEIVER_STATUS")
    }

    /// 接続は都度張って閉じる。常時つなぐと端末側の接続数を無駄に消費するため。
    private func withChannel<T>(_ body: (CastChannel) async throws -> T) async throws -> T {
        let channel = CastChannel(host: host)
        try await channel.connect()
        defer { channel.close() }
        return try await body(channel)
    }

    private static func level(from status: [String: Any]) -> Double? {
        guard let receiver = status["status"] as? [String: Any],
              let volume = receiver["volume"] as? [String: Any],
              let level = volume["level"] as? Double
        else { return nil }
        return level
    }

    // MARK: - 検出

    static func discover(timeout: TimeInterval = 3) async -> [SpeakerControl] {
        let hosts = await BonjourBrowser.hosts(ofType: "_googlecast._tcp", timeout: timeout)
        var found: [SpeakerControl] = []
        for host in hosts {
            let name = await deviceName(host: host) ?? host
            found.append(CastSpeaker(host: host, name: name))
        }
        return found
    }

    /// 端末名はセットアップ用の HTTP から読む。取れなければ IP をそのまま名前にする。
    private static func deviceName(host: String) async -> String? {
        guard let url = URL(string: "http://\(BonjourBrowser.urlHost(host)):8008/setup/eureka_info") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 4)
        req.httpMethod = "GET"
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return (json["name"] as? String) ?? (json["ssid"] as? String)
    }
}
