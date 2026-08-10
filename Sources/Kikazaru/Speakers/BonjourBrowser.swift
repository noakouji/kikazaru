import Foundation
import Network

/// Bonjour（mDNS）で機器を探し、IP アドレスを返す。
///
/// Bose と Google Home はどちらも Bonjour で見つかるので、探索部分を共通化する。
enum BonjourBrowser {

    /// 指定したサービス種別の機器を探し、IP アドレスの一覧を返す。
    static func hosts(ofType type: String, timeout: TimeInterval) async -> [String] {
        let results = await browse(type: type, timeout: timeout)
        var hosts: [String] = []
        for endpoint in results {
            if let ip = await resolve(endpoint: endpoint, timeout: 2), !hosts.contains(ip) {
                hosts.append(ip)
            }
        }
        return hosts
    }

    /// IPv6 は URL に入れるとき角括弧が要る。
    static func urlHost(_ host: String) -> String {
        host.contains(":") ? "[\(host)]" : host
    }

    private static func browse(type: String, timeout: TimeInterval) async -> [NWEndpoint] {
        await withCheckedContinuation { continuation in
            let browser = NWBrowser(
                for: .bonjour(type: type, domain: nil),
                using: .tcp)
            let box = ResultBox()

            browser.browseResultsChangedHandler = { results, _ in
                box.set(results.map(\.endpoint))
            }
            browser.start(queue: .global(qos: .utility))

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                browser.cancel()
                continuation.resume(returning: box.get())
            }
        }
    }

    /// エンドポイントを実際に接続して IP アドレスを取り出す。
    /// Bonjour 名のままでは HTTP クライアントから使いにくいため。
    private static func resolve(endpoint: NWEndpoint, timeout: TimeInterval) async -> String? {
        await withCheckedContinuation { continuation in
            let connection = NWConnection(to: endpoint, using: .tcp)
            let once = OnceFlag()

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    var ip: String?
                    if case let .hostPort(host, _) = connection.currentPath?.remoteEndpoint {
                        switch host {
                        case .ipv4(let v4): ip = "\(v4)".components(separatedBy: "%").first
                        case .ipv6(let v6): ip = "\(v6)".components(separatedBy: "%").first
                        default: break
                        }
                    }
                    connection.cancel()
                    if once.claim() { continuation.resume(returning: ip) }
                case .failed, .cancelled:
                    if once.claim() { continuation.resume(returning: nil) }
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .utility))

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                connection.cancel()
                if once.claim() { continuation.resume(returning: nil) }
            }
        }
    }
}

/// 複数スレッドから触るための小さな入れ物。
private final class ResultBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value: [NWEndpoint] = []
    func set(_ v: [NWEndpoint]) { lock.withLock { value = v } }
    func get() -> [NWEndpoint] { lock.withLock { value } }
}

/// continuation を二重に再開させないための旗。
private final class OnceFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var used = false
    func claim() -> Bool {
        lock.withLock {
            if used { return false }
            used = true
            return true
        }
    }
}
