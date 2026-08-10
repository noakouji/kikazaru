import CoreAudio
import Foundation

/// Mac 本体（既定の出力デバイス）の音量を下げる／戻すアクション。
///
/// DuckAction を 2 つ実装するだけで足せることを示す 2 つ目の実装でもある。
/// AirPlay など音量プロパティを持たないデバイスでは何もしない。
final class SystemVolumeAction: DuckAction, @unchecked Sendable {

    let name = "Mac本体"

    private let lock = NSLock()
    private var savedPercent: Int?

    func duck(ratio: Double) async {
        guard lock.withLock({ savedPercent == nil }), let current = Self.currentVolume() else { return }
        let target = Float(max(0.02, Double(current) * ratio))
        guard target < current else { return }
        Self.setVolume(target)
        lock.withLock { savedPercent = Int((current * 100).rounded()) }
    }

    func restore() async {
        let snapshot = lock.withLock { savedPercent }
        guard snapshot != nil else { return }
        await apply(snapshot: self.snapshot())
        lock.withLock { savedPercent = nil }
    }

    func snapshot() -> [String: Int] {
        guard let value = lock.withLock({ savedPercent }) else { return [:] }
        return ["default": value]
    }

    func apply(snapshot: [String: Int]) async {
        guard let percent = snapshot["default"] else { return }
        Self.setVolume(Float(percent) / 100)
    }

    // MARK: - CoreAudio

    private static func defaultOutputDevice() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr ? device : kAudioObjectUnknown
    }

    /// マスター要素に無い機種があるので、チャンネル 1 / 2 も順に試す。
    private static func volumeAddress(_ device: AudioDeviceID) -> AudioObjectPropertyAddress? {
        for element in [kAudioObjectPropertyElementMain, 1, 2] {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: AudioObjectPropertyElement(element))
            if AudioObjectHasProperty(device, &address) {
                return address
            }
        }
        return nil
    }

    static func currentVolume() -> Float? {
        let device = defaultOutputDevice()
        guard device != kAudioObjectUnknown, var address = volumeAddress(device) else { return nil }
        var value: Float = 0
        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    static func setVolume(_ value: Float) {
        let device = defaultOutputDevice()
        guard device != kAudioObjectUnknown, var address = volumeAddress(device) else { return }
        var v = max(0, min(1, value))
        AudioObjectSetPropertyData(
            device, &address, 0, nil, UInt32(MemoryLayout<Float>.size), &v)
    }
}
