import Foundation
import Network

/// Chromecast / Google Home と話すための最小限の通信路。
///
/// CASTV2 は「4 バイトの長さ + protobuf」という枠に JSON を包んで送る独自形式。
/// 依存を増やしたくないので、必要な 6 フィールドだけを手で組み立てる。
/// 端末の証明書は自己署名なので、検証を外して接続する（LAN 内の機器のみが相手）。
final class CastChannel: @unchecked Sendable {

    private let host: String
    private var connection: NWConnection?
    private var buffer = Data()
    private let lock = NSLock()

    init(host: String) {
        self.host = host
    }

    // MARK: - 接続

    func connect(timeout: TimeInterval = 5) async throws {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(
            options.securityProtocolOptions,
            { _, _, complete in complete(true) },   // LAN 内の自己署名証明書を受け入れる
            DispatchQueue.global(qos: .utility))

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: 8009,
            using: NWParameters(tls: options))
        self.connection = connection

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let once = Once()
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if once.claim() { cont.resume() }
                case .failed(let error):
                    if once.claim() { cont.resume(throwing: error) }
                case .cancelled:
                    if once.claim() { cont.resume(throwing: SpeakerError.timeout) }
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                if once.claim() {
                    connection.cancel()
                    cont.resume(throwing: SpeakerError.timeout)
                }
            }
        }

        // 接続直後に CONNECT を送らないと、以降のメッセージが無視される
        try await send(namespace: Namespace.connection, payload: ["type": "CONNECT"])
    }

    func close() {
        connection?.cancel()
        connection = nil
    }

    // MARK: - 送受信

    func send(namespace: String, payload: [String: Any]) async throws {
        guard let connection else { throw SpeakerError.timeout }
        let json = try JSONSerialization.data(withJSONObject: payload)
        let frame = Self.frame(namespace: namespace,
                               payload: String(decoding: json, as: UTF8.self))
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            connection.send(content: frame, completion: .contentProcessed { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            })
        }
    }

    /// 指定した `type` の応答が来るまで読み続ける。
    func receive(type wanted: String, timeout: TimeInterval = 5) async throws -> [String: Any] {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let message = try popMessage() {
                if let dict = try? JSONSerialization.jsonObject(with: Data(message.utf8)) as? [String: Any],
                   dict["type"] as? String == wanted {
                    return dict
                }
                continue
            }
            try await readMore()
        }
        throw SpeakerError.timeout
    }

    private func readMore() async throws {
        guard let connection else { throw SpeakerError.timeout }
        let chunk: Data = try await withCheckedThrowingContinuation { cont in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { data, _, _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume(returning: data ?? Data()) }
            }
        }
        guard !chunk.isEmpty else { throw SpeakerError.timeout }
        lock.withLock { buffer.append(chunk) }
    }

    /// 溜まったバイト列から 1 通取り出す。足りなければ nil。
    private func popMessage() throws -> String? {
        lock.withLock {
            guard buffer.count >= 4 else { return nil }
            let length = buffer.prefix(4).reduce(0) { $0 << 8 | Int($1) }
            guard buffer.count >= 4 + length else { return nil }
            let body = buffer.subdata(in: 4..<(4 + length))
            buffer.removeSubrange(0..<(4 + length))
            return Self.payload(fromProtobuf: body)
        }
    }

    // MARK: - protobuf（必要な分だけ手で組む）

    enum Namespace {
        static let connection = "urn:x-cast:com.google.cast.tp.connection"
        static let receiver = "urn:x-cast:com.google.cast.receiver"
    }

    private static func frame(namespace: String, payload: String) -> Data {
        var body = Data()
        body.append(varintField(1, 0))            // protocol_version = CASTV2_1_0
        body.append(stringField(2, "sender-kikazaru"))
        body.append(stringField(3, "receiver-0"))
        body.append(stringField(4, namespace))
        body.append(varintField(5, 0))            // payload_type = STRING
        body.append(stringField(6, payload))

        var out = Data()
        let length = UInt32(body.count).bigEndian
        withUnsafeBytes(of: length) { out.append(contentsOf: $0) }
        out.append(body)
        return out
    }

    private static func varintField(_ field: Int, _ value: Int) -> Data {
        var data = Data([UInt8(field << 3)])      // wire type 0
        data.append(varint(value))
        return data
    }

    private static func stringField(_ field: Int, _ value: String) -> Data {
        let bytes = Data(value.utf8)
        var data = Data([UInt8(field << 3 | 2)])  // wire type 2
        data.append(varint(bytes.count))
        data.append(bytes)
        return data
    }

    private static func varint(_ value: Int) -> Data {
        var v = value
        var data = Data()
        repeat {
            var byte = UInt8(v & 0x7F)
            v >>= 7
            if v != 0 { byte |= 0x80 }
            data.append(byte)
        } while v != 0
        return data
    }

    /// フィールド 6（payload_utf8）だけ取り出す。
    private static func payload(fromProtobuf data: Data) -> String? {
        var i = data.startIndex
        while i < data.endIndex {
            let key = Int(data[i]); i += 1
            let field = key >> 3, wire = key & 0x7
            switch wire {
            case 0:
                while i < data.endIndex, data[i] & 0x80 != 0 { i += 1 }
                i += 1
            case 2:
                var length = 0, shift = 0
                while i < data.endIndex {
                    let byte = data[i]; i += 1
                    length |= Int(byte & 0x7F) << shift
                    if byte & 0x80 == 0 { break }
                    shift += 7
                }
                guard i + length <= data.endIndex else { return nil }
                let slice = data.subdata(in: i..<(i + length))
                i += length
                if field == 6 { return String(decoding: slice, as: UTF8.self) }
            default:
                return nil
            }
        }
        return nil
    }
}

/// continuation を二重に再開させないための旗。
private final class Once: @unchecked Sendable {
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
