import Foundation

/// SSDP マルチキャストで LAN 上の Sonos を探す。
/// IP を設定させないための仕組みで、DHCP で変わっても追従できる。
enum SonosDiscovery {

    static func discover(timeout: TimeInterval = 3) async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: search(timeout: timeout))
            }
        }
    }

    private static func search(timeout: TimeInterval) -> [String] {
        // 改行は CRLF でなければ機器が応答しないため、複数行リテラルは使わない
        let message = [
            "M-SEARCH * HTTP/1.1",
            "HOST: 239.255.255.250:1900",
            "MAN: \"ssdp:discover\"",
            "MX: 1",
            "ST: urn:schemas-upnp-org:device:ZonePlayer:1",
            "", "",
        ].joined(separator: "\r\n")

        let sock = socket(AF_INET, SOCK_DGRAM, 0)
        guard sock >= 0 else { return [] }
        defer { close(sock) }

        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))
        var tv = timeval(tv_sec: Int(timeout), tv_usec: 0)
        setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, socklen_t(MemoryLayout<timeval>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)  // BSD 系では必須
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(1900).bigEndian
        addr.sin_addr.s_addr = inet_addr("239.255.255.250")

        let payload = [UInt8](message.utf8)
        for _ in 0..<2 {
            _ = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    sendto(sock, payload, payload.count, 0, sa, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }
        }

        var found = Set<String>()
        let deadline = Date().addingTimeInterval(timeout)
        var buffer = [UInt8](repeating: 0, count: 2048)
        while Date() < deadline {
            var from = sockaddr_in()
            var fromLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            let n = withUnsafeMutablePointer(to: &from) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    recvfrom(sock, &buffer, buffer.count, 0, sa, &fromLen)
                }
            }
            if n <= 0 { break }
            let ip = String(cString: inet_ntoa(from.sin_addr))
            found.insert(ip)
        }
        return found.sorted()
    }

    /// 機体の説明 XML から部屋名を読む。
    static func roomName(ip: String) async -> String? {
        guard let url = URL(string: "http://\(ip):1400/xml/device_description.xml") else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 4)
        request.httpMethod = "GET"
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return SonosDevice.extract("roomName", from: String(decoding: data, as: UTF8.self))
    }
}
