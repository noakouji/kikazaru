import CoreAudio
import Foundation

/// マイクの入力ゲインを、勝手に動かされても書き戻して固定する。
///
/// Google Meet / Chrome / Zoom / Teams などは、通話の途中で
/// OS 側の入力ゲインそのものを書き換えることがある。
/// 一度上げられると次の音声入力にも引き継がれ、部屋の音まで拾うようになる。
///
/// ポーリングはしない。ゲインが変わった瞬間に OS から通知が来るので、
/// そこで目標値に戻す。自分が書き戻したぶんは無視して往復を止める。
///
/// 機器によってゲインの置き場所が違う。本体マイクは main（要素0）に出すが、
/// USB マイクは左右チャンネル（要素1・2）にしか出さないことがある。
/// どこにあるかを起動時に調べ、見つかった全要素を同じ値で扱う。
final class MicGainLock: @unchecked Sendable {

    /// 固定したい値（0.0〜1.0）。nil なら固定しない。
    private var target: Float?

    /// 書き戻したときに呼ばれる。（勝手に変わった値, 戻した値）
    var onCorrected: (@Sendable (Float, Float) -> Void)?

    private var watchedDevice: AudioDeviceID = kAudioObjectUnknown
    private var watchedElements: [UInt32] = []
    private let queue = DispatchQueue(label: "Kikazaru.MicGainLock")

    /// 自分の書き込みで発火した通知の残り。これが 0 でないうちは反応しない。
    private var selfWrites = 0

    private var defaultDeviceAddress = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultInputDevice,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain)

    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var gainListener: AudioObjectPropertyListenerBlock?

    // MARK: - 開始 / 停止

    func start() {
        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.rebindToCurrentDevice()
        }
        deviceListener = listener
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, queue, listener)
        rebindToCurrentDevice()
    }

    func stop() {
        detachGainListener()
        if let listener = deviceListener {
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject), &defaultDeviceAddress, queue, listener)
            deviceListener = nil
        }
    }

    /// 固定を始める。値を渡さなければ「いまの値」で固定する。
    @discardableResult
    func lock(to value: Float? = nil) -> Float? {
        if watchedDevice == kAudioObjectUnknown { rebindToCurrentDevice() }
        guard let now = value ?? Self.gain(of: watchedDevice) else { return nil }
        target = min(max(now, 0), 1)
        apply()
        return target
    }

    func unlock() { target = nil }

    var lockedValue: Float? { target }

    // MARK: - 監視

    private func rebindToCurrentDevice() {
        let device = Self.defaultInputDevice()
        guard device != watchedDevice else { return }
        detachGainListener()
        watchedDevice = device
        watchedElements = Self.gainElements(of: device)
        guard device != kAudioObjectUnknown, !watchedElements.isEmpty else { return }

        let listener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.handleChange()
        }
        gainListener = listener
        for element in watchedElements {
            var address = Self.gainAddress(element)
            AudioObjectAddPropertyListenerBlock(device, &address, queue, listener)
        }

        // 機器ごとにゲインは別管理なので、前の機器の値を持ち込まない。
        if target != nil { target = Self.gain(of: device) }
    }

    private func detachGainListener() {
        guard watchedDevice != kAudioObjectUnknown, let listener = gainListener else { return }
        for element in watchedElements {
            var address = Self.gainAddress(element)
            AudioObjectRemovePropertyListenerBlock(watchedDevice, &address, queue, listener)
        }
        gainListener = nil
        watchedElements = []
    }

    private func handleChange() {
        if selfWrites > 0 {
            selfWrites -= 1
            return
        }
        guard let target, let now = Self.gain(of: watchedDevice) else { return }
        // 端数のずれで往復しないよう、目に見える差があるときだけ戻す。
        guard abs(now - target) > 0.01 else { return }
        apply()
        onCorrected?(now, target)
    }

    private func apply() {
        guard let target, !watchedElements.isEmpty else { return }
        // 左右チャンネルに分かれている機器では、要素の数だけ通知が返ってくる。
        selfWrites += watchedElements.count
        let wrote = Self.setGain(target, on: watchedDevice)
        if !wrote { selfWrites = max(0, selfWrites - watchedElements.count) }
    }

    // MARK: - CoreAudio 問い合わせ

    /// CoreAudio が inout を要求するので、都度作って渡す。
    private static func gainAddress(_ element: UInt32) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioObjectPropertyScopeInput,
            mElement: element)
    }

    /// ゲインを持っている要素。main が無い機器では左右チャンネルを使う。
    static func gainElements(of device: AudioDeviceID) -> [UInt32] {
        guard device != kAudioObjectUnknown else { return [] }
        func has(_ element: UInt32) -> Bool {
            var address = gainAddress(element)
            guard AudioObjectHasProperty(device, &address) else { return false }
            var settable: DarwinBoolean = false
            guard AudioObjectIsPropertySettable(device, &address, &settable) == noErr
            else { return false }
            return settable.boolValue
        }
        if has(kAudioObjectPropertyElementMain) { return [kAudioObjectPropertyElementMain] }
        // ステレオ入力までを見る。これ以上のチャンネルを持つ機器は対象外でよい。
        return (UInt32(1)...2).filter(has)
    }

    static func defaultInputDevice() -> AudioDeviceID { MicMonitor.defaultInputDevice() }

    /// 入力ゲイン（0.0〜1.0）。複数チャンネルのときは最初の値を代表とする。
    static func gain(of device: AudioDeviceID) -> Float? {
        guard let element = gainElements(of: device).first else { return nil }
        var address = gainAddress(element)
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        guard AudioObjectGetPropertyData(device, &address, 0, nil, &size, &value) == noErr
        else { return nil }
        return value
    }

    /// 見つかった全要素に同じ値を書く。左右がずれたままになるのを防ぐ。
    @discardableResult
    static func setGain(_ value: Float, on device: AudioDeviceID) -> Bool {
        let elements = gainElements(of: device)
        guard !elements.isEmpty else { return false }
        var wroteAny = false
        for element in elements {
            var address = gainAddress(element)
            var v = Float32(min(max(value, 0), 1))
            let size = UInt32(MemoryLayout<Float32>.size)
            if AudioObjectSetPropertyData(device, &address, 0, nil, size, &v) == noErr {
                wroteAny = true
            }
        }
        return wroteAny
    }

    /// この機器のゲインを変えられるか。仮想デバイスなどは変えられないことがある。
    static func isSettable(_ device: AudioDeviceID) -> Bool {
        !gainElements(of: device).isEmpty
    }
}
