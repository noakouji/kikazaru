import AppKit
import CoreAudio
import Foundation

/// いまマイクを使っているアプリを調べる。
///
/// 「誰が使っているか」で動きを変えたい。音声入力なら少し下げるだけでよいが、
/// ビデオ会議中は完全に黙らせたい。macOS 14.2 以降ならプロセス単位で取得でき、
/// 追加の権限も要らない。
enum MicUsers {

    /// いま入力を使っているアプリのバンドルID
    static func active() -> [String] {
        processObjects().compactMap { object in
            guard flag(object, kAudioProcessPropertyIsRunningInput) else { return nil }
            return string(object, kAudioProcessPropertyBundleID)
        }
    }

    /// バンドルIDから、人が読める名前を引く。取れなければIDをそのまま返す。
    static func displayName(for bundleID: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url),
           let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName")
                       ?? bundle.object(forInfoDictionaryKey: "CFBundleName")) as? String {
            return name
        }
        // ヘルパープロセスは親アプリ名が引けないことがあるので、末尾を整えて出す
        return bundleID.split(separator: ".").last.map(String.init) ?? bundleID
    }

    // MARK: - CoreAudio

    private static func address(_ selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector,
                                   mScope: kAudioObjectPropertyScopeGlobal,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func processObjects() -> [AudioObjectID] {
        var a = address(kAudioHardwarePropertyProcessObjectList)
        var size: UInt32 = 0
        let system = AudioObjectID(kAudioObjectSystemObject)
        guard AudioObjectGetPropertyDataSize(system, &a, 0, nil, &size) == noErr else { return [] }
        var ids = [AudioObjectID](repeating: 0, count: Int(size) / MemoryLayout<AudioObjectID>.size)
        guard AudioObjectGetPropertyData(system, &a, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    private static func string(_ object: AudioObjectID,
                               _ selector: AudioObjectPropertySelector) -> String? {
        var a = address(selector)
        var size = UInt32(MemoryLayout<CFString?>.size)
        var value: CFString?
        guard AudioObjectGetPropertyData(object, &a, 0, nil, &size, &value) == noErr else { return nil }
        return value as String?
    }

    private static func flag(_ object: AudioObjectID,
                             _ selector: AudioObjectPropertySelector) -> Bool {
        var a = address(selector)
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        guard AudioObjectGetPropertyData(object, &a, 0, nil, &size, &value) == noErr else { return false }
        return value != 0
    }
}

/// アプリごとの動き。
enum DuckMode: String, Sendable, CaseIterable {
    /// 設定したぶんだけ下げる
    case lower
    /// 完全に黙らせる
    case mute

    var label: String {
        switch self {
        case .lower: return L10n.t("下げる", "Lower")
        case .mute: return L10n.t("ミュート", "Mute")
        }
    }
}
