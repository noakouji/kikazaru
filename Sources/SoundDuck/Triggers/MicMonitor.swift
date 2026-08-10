import CoreAudio
import Foundation

/// マイクが使われ始めた／終わったことを、OS からの通知で受け取る。
///
/// ポーリングしないので待機中の CPU 使用率は実質ゼロになる。
/// 既定の入力デバイスが切り替わった場合も追従する。
final class MicMonitor: @unchecked Sendable {

    /// true = どれかのアプリが入力デバイスを使用中
    private(set) var isActive = false

    private var onChange: (@Sendable (Bool) -> Void)?
    private var watchedDevice: AudioDeviceID = kAudioObjectUnknown
    private let queue = DispatchQueue(label: "SoundDuck.MicMonitor")

    private var defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)

    private var runningAddress = AudioObjectPropertyAddress(
        mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)

    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var runningListener: AudioObjectPropertyListenerBlock?

    // MARK: - 開始 / 停止

    func start(onChange: @escaping @Sendable (Bool) -> Void) {
        self.onChange = onChange

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.rebindToCurrentDevice()
        }
        deviceListener = listener
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, queue, listener)

        rebindToCurrentDevice()
    }

    func stop() {
        detachRunningListener()
        if let listener = deviceListener {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, queue, listener)
            deviceListener = nil
        }
        onChange = nil
    }

    // MARK: - デバイスの張り替え

    /// 既定の入力デバイスを取り直し、そこに使用状態のリスナーを付け直す。
    private func rebindToCurrentDevice() {
        let device = Self.defaultInputDevice()
        guard device != watchedDevice else {
            publish(Self.isRunning(device))
            return
        }
        detachRunningListener()
        watchedDevice = device
        guard device != kAudioObjectUnknown else {
            publish(false)
            return
        }

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            guard let self else { return }
            self.publish(Self.isRunning(self.watchedDevice))
        }
        runningListener = listener
        AudioObjectAddPropertyListenerBlock(device, &runningAddress, queue, listener)
        publish(Self.isRunning(device))
    }

    private func detachRunningListener() {
        guard watchedDevice != kAudioObjectUnknown, let listener = runningListener else { return }
        AudioObjectRemovePropertyListenerBlock(watchedDevice, &runningAddress, queue, listener)
        runningListener = nil
    }

    private func publish(_ active: Bool) {
        guard active != isActive else { return }
        isActive = active
        onChange?(active)
    }

    // MARK: - CoreAudio 問い合わせ

    static func defaultInputDevice() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var device = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &device)
        return status == noErr ? device : kAudioObjectUnknown
    }

    static func isRunning(_ device: AudioDeviceID) -> Bool {
        guard device != kAudioObjectUnknown else { return false }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value)
        return status == noErr && value != 0
    }

    static func deviceName(_ device: AudioDeviceID) -> String {
        guard device != kAudioObjectUnknown else { return "?" }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = AudioObjectGetPropertyData(device, &address, 0, nil, &size, &name)
        return status == noErr ? (name as String) : "?"
    }
}
