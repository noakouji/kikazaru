import Foundation

/// Sonos の 1 台。ポート 1400 の UPnP/SOAP を直接叩く（認証不要）。
struct SonosDevice: Sendable, Hashable {
    let ip: String
    var roomName: String

    private static let renderingControl = (
        urn: "urn:schemas-upnp-org:service:RenderingControl:1",
        path: "/MediaRenderer/RenderingControl/Control"
    )

    // MARK: - 音量

    func volume() async throws -> Int {
        let body = try await Self.soap(
            ip: ip, service: Self.renderingControl, action: "GetVolume",
            args: ["InstanceID": "0", "Channel": "Master"])
        guard let raw = Self.extract("CurrentVolume", from: body), let v = Int(raw) else {
            throw SonosError.unexpectedResponse
        }
        return v
    }

    func setVolume(_ value: Int) async throws {
        let clamped = max(0, min(100, value))
        _ = try await Self.soap(
            ip: ip, service: Self.renderingControl, action: "SetVolume",
            args: ["InstanceID": "0", "Channel": "Master", "DesiredVolume": String(clamped)])
    }

    /// 段階的に音量を変える。急な変化を避けつつ、全体で 100ms 前後に収める。
    /// RampToVolume はフェードイン専用でダッキングに使えないため自前で刻む。
    func fade(from start: Int, to end: Int, steps: Int) async {
        guard steps > 0 else { return }
        for i in 1...steps {
            let value = start + (end - start) * i / steps
            try? await setVolume(value)
        }
    }

    // MARK: - SOAP

    static func soap(
        ip: String,
        service: (urn: String, path: String),
        action: String,
        args: [String: String] = [:],
        timeout: TimeInterval = 5
    ) async throws -> String {
        // 引数の順序は Sonos 側が要求するため、呼び出し側の意図した順を保てるよう
        // InstanceID / Channel を先頭に固定してから残りを並べる。
        let ordered = ["InstanceID", "Channel", "DesiredVolume"]
        let sorted = args.sorted { a, b in
            let ia = ordered.firstIndex(of: a.key) ?? Int.max
            let ib = ordered.firstIndex(of: b.key) ?? Int.max
            return ia == ib ? a.key < b.key : ia < ib
        }
        let inner = sorted.map { "<\($0.key)>\(escape($0.value))</\($0.key)>" }.joined()
        let envelope = """
        <?xml version="1.0"?>\
        <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" \
        s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>\
        <u:\(action) xmlns:u="\(service.urn)">\(inner)</u:\(action)>\
        </s:Body></s:Envelope>
        """

        guard let url = URL(string: "http://\(ip):1400\(service.path)") else {
            throw SonosError.badURL
        }
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("text/xml; charset=\"utf-8\"", forHTTPHeaderField: "Content-Type")
        request.setValue("\"\(service.urn)#\(action)\"", forHTTPHeaderField: "SOAPACTION")
        request.httpBody = Data(envelope.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw SonosError.http(http.statusCode)
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// `<Tag>値</Tag>` を1つ取り出す。
    static func extract(_ tag: String, from xml: String) -> String? {
        guard let open = xml.range(of: "<\(tag)>"),
              let close = xml.range(of: "</\(tag)>", range: open.upperBound..<xml.endIndex)
        else { return nil }
        return String(xml[open.upperBound..<close.lowerBound])
    }

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

enum SonosError: Error {
    case badURL
    case http(Int)
    case unexpectedResponse
}
