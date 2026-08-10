import ApplicationServices
import CoreGraphics
import Foundation

/// ディクテーションのホットキーが離されたことを検知する。
///
/// これは主役ではなく加速装置。マイクが閉じるのを待たずに音量を戻すためだけに使う。
/// 取り逃しても Coordinator 側のマイクOFF が保険として働くので、状態がズレたままにならない。
///
/// アクセシビリティ権限が必要なため、設定で明示的に有効化したときだけ動かす。
final class HotkeyMonitor: @unchecked Sendable {

    /// 権限が付与されているか。プロンプトは出さない。
    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// 権限を要求する（システム設定へ誘導するダイアログが出る）
    static func requestPermission() {
        // kAXTrustedCheckOptionPrompt は可変グローバルとして公開されており
        // 直接参照すると並行性チェックに掛かるため、キー文字列を直接使う
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var onRelease: (@Sendable () -> Void)?

    /// 監視対象のキーコード。既定は fn キー。
    var keyCode: Int64

    init(keyCode: Int64 = 63) {
        self.keyCode = keyCode
    }

    func start(onRelease: @escaping @Sendable () -> Void) {
        guard tap == nil, Self.isTrusted else { return }
        self.onRelease = onRelease

        // keyUp と flagsChanged の両方を見る。
        // 通常キーなら keyUp、修飾キー（fn / ctrl 等）なら flagsChanged で解放が分かる。
        let mask = (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let monitor = Unmanaged<HotkeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
            monitor.handle(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,          // 入力を横取りしない
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return }

        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        source = nil
        tap = nil
        onRelease = nil
    }

    private func handle(type: CGEventType, event: CGEvent) {
        let code = event.getIntegerValueField(.keyboardEventKeycode)
        guard code == keyCode else { return }

        switch type {
        case .keyUp:
            onRelease?()
        case .flagsChanged:
            // 修飾キーは押下も解放も flagsChanged で来る。
            // 該当フラグが落ちていれば解放とみなす。
            if !event.flags.contains(Self.flag(for: code)) {
                onRelease?()
            }
        default:
            break
        }
    }

    private static func flag(for keyCode: Int64) -> CGEventFlags {
        switch keyCode {
        case 63: return .maskSecondaryFn
        case 59, 62: return .maskControl
        case 58, 61: return .maskAlternate
        case 55, 54: return .maskCommand
        case 56, 60: return .maskShift
        default: return []
        }
    }
}
