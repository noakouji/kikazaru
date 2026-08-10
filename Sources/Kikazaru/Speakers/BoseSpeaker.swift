import Foundation

/// Bose SoundTouch。ポート 8090 の HTTP API を叩く（認証不要）。
///
///   GET  /volume  → <volume><actualvolume>30</actualvolume>…</volume>
///   POST /volume  ← <volume>30</volume>
final class BoseSpeaker: SpeakerControl, @unchecked Sendable {

    let id: String
    let name: String
    let kind: SpeakerKind = .bose
    private let host: String

    init(host: String, name: String) {
        self.host = host
        self.id = "bose:\(host)"
        self.name = name
    }

    func volume() async throws -> Int {
        let xml = try await request(path: "/volume", method: "GET", body: nil)
        guard let raw = SonosDevice.extract("actualvolume", from: xml), let value = Int(raw) else {
            throw SpeakerError.unexpectedResponse
        }
        return value
    }

    func setVolume(_ value: Int) async throws {
        let clamped = max(0, min(100, value))
        _ = try await request(path: "/volume", method: "POST",
                              body: "<volume>\(clamped)</volume>")
    }

    private func request(path: String, method: String, body: String?) async throws -> String {
        guard let url = URL(string: "http://\(BonjourBrowser.urlHost(host)):8090\(path)") else { throw SpeakerError.badURL }
        var req = URLRequest(url: url, timeoutInterval: 5)
        req.httpMethod = method
        if let body {
            req.setValue("text/xml", forHTTPHeaderField: "Content-Type")
            req.httpBody = Data(body.utf8)
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SpeakerError.http(http.statusCode)
        }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - 検出

    /// Bonjour の `_soundtouch._tcp` で探し、`/info` から機器名を読む。
    static func discover(timeout: TimeInterval = 3) async -> [SpeakerControl] {
        let hosts = await BonjourBrowser.hosts(ofType: "_soundtouch._tcp", timeout: timeout)
        var found: [SpeakerControl] = []
        for host in hosts {
            let name = await deviceName(host: host) ?? host
            found.append(BoseSpeaker(host: host, name: name))
        }
        return found
    }

    private static func deviceName(host: String) async -> String? {
        guard let url = URL(string: "http://\(BonjourBrowser.urlHost(host)):8090/info") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 4)
        req.httpMethod = "GET"
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return SonosDevice.extract("name", from: String(decoding: data, as: UTF8.self))
    }
}

enum SpeakerError: Error {
    case badURL
    case http(Int)
    case unexpectedResponse
    case timeout
}
