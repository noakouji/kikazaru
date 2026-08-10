import Foundation

/// UserDefaults に保存する設定。
struct Settings: Sendable, Equatable {

    /// 元の音量に対して何割まで下げるか
    var duckRatio: Double = 0.30

    /// 発話が途切れてから戻すまでの猶予（秒）
    var releaseDelay: TimeInterval = 0.4

    /// ホットキーによる高速復帰。アクセシビリティ権限が必要なため既定は無効
    var hotkeyEnabled: Bool = false

    /// Mac 本体の音量も一緒に下げるか
    var systemVolumeEnabled: Bool = false

    /// ホットキーとして監視するキーコード。既定は fn（Aqua Voice の既定キー）
    var hotkeyKeyCode: Int64 = 63

    /// 表示言語
    var language: L10n.Language = .auto

    /// 下げない対象として外したスピーカー
    var disabledSpeakerIDs: Set<String> = []

    /// 一度でも見つけたスピーカー。新顔かどうかの判定に使う。
    var knownSpeakerIDs: Set<String> = []

    private enum Key {
        static let ratio = "duckRatio"
        static let delay = "releaseDelay"
        static let hotkey = "hotkeyEnabled"
        static let systemVolume = "systemVolumeEnabled"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let language = "language"
        static let disabledSpeakers = "disabledSpeakerIDs"
        static let knownSpeakers = "knownSpeakerIDs"
    }

    static func load(from defaults: UserDefaults = .standard) -> Settings {
        var s = Settings()
        if defaults.object(forKey: Key.ratio) != nil {
            s.duckRatio = defaults.double(forKey: Key.ratio)
        }
        if defaults.object(forKey: Key.delay) != nil {
            s.releaseDelay = defaults.double(forKey: Key.delay)
        }
        s.hotkeyEnabled = defaults.bool(forKey: Key.hotkey)
        s.systemVolumeEnabled = defaults.bool(forKey: Key.systemVolume)
        if defaults.object(forKey: Key.hotkeyKeyCode) != nil {
            s.hotkeyKeyCode = Int64(defaults.integer(forKey: Key.hotkeyKeyCode))
        }
        if let raw = defaults.string(forKey: Key.language),
           let lang = L10n.Language(rawValue: raw) {
            s.language = lang
        }
        s.disabledSpeakerIDs = Set(defaults.stringArray(forKey: Key.disabledSpeakers) ?? [])
        s.knownSpeakerIDs = Set(defaults.stringArray(forKey: Key.knownSpeakers) ?? [])
        L10n.override = s.language
        return s
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(duckRatio, forKey: Key.ratio)
        defaults.set(releaseDelay, forKey: Key.delay)
        defaults.set(hotkeyEnabled, forKey: Key.hotkey)
        defaults.set(systemVolumeEnabled, forKey: Key.systemVolume)
        defaults.set(Int(hotkeyKeyCode), forKey: Key.hotkeyKeyCode)
        defaults.set(language.rawValue, forKey: Key.language)
        defaults.set(Array(disabledSpeakerIDs), forKey: Key.disabledSpeakers)
        defaults.set(Array(knownSpeakerIDs), forKey: Key.knownSpeakers)
        L10n.override = language
    }
}
