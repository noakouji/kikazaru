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

    /// アプリごとの動き（バンドルID → 下げる／ミュート）
    var appModes: [String: DuckMode] = AppPresets.defaultModes

    /// 表に無いアプリをどう扱うか
    var defaultMode: DuckMode = .lower

    /// マイクを使ったのを見たことがあるアプリ。設定画面に並べる。
    var seenApps: [String] = []

    /// マイクの入力ゲインを固定するか。通話アプリに勝手に上げられるのを防ぐ。
    var micGainLockEnabled: Bool = false

    /// 固定したいゲイン（0.0〜1.0）。負なら「有効にした時点の値」を使う。
    var micGainTarget: Double = -1

    /// そのアプリに対する動きを返す
    func mode(for bundleID: String) -> DuckMode {
        appModes[bundleID] ?? defaultMode
    }

    private enum Key {
        static let ratio = "duckRatio"
        static let delay = "releaseDelay"
        static let hotkey = "hotkeyEnabled"
        static let systemVolume = "systemVolumeEnabled"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let language = "language"
        static let disabledSpeakers = "disabledSpeakerIDs"
        static let knownSpeakers = "knownSpeakerIDs"
        static let appModes = "appModes"
        static let defaultMode = "defaultMode"
        static let seenApps = "seenApps"
        static let gainLock = "micGainLockEnabled"
        static let gainTarget = "micGainTarget"
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
        // 保存済みの振り分けを、プリセットの上に重ねる。
        // 新しくプリセットへ足したアプリも、次の起動から反映される。
        var modes = AppPresets.defaultModes
        for (id, raw) in defaults.dictionary(forKey: Key.appModes) as? [String: String] ?? [:] {
            if let mode = DuckMode(rawValue: raw) { modes[id] = mode }
        }
        s.appModes = modes
        if let raw = defaults.string(forKey: Key.defaultMode), let m = DuckMode(rawValue: raw) {
            s.defaultMode = m
        }
        s.seenApps = defaults.stringArray(forKey: Key.seenApps) ?? []
        s.micGainLockEnabled = defaults.bool(forKey: Key.gainLock)
        if defaults.object(forKey: Key.gainTarget) != nil {
            s.micGainTarget = defaults.double(forKey: Key.gainTarget)
        }
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
        defaults.set(appModes.mapValues(\.rawValue), forKey: Key.appModes)
        defaults.set(defaultMode.rawValue, forKey: Key.defaultMode)
        defaults.set(seenApps, forKey: Key.seenApps)
        defaults.set(micGainLockEnabled, forKey: Key.gainLock)
        defaults.set(micGainTarget, forKey: Key.gainTarget)
        L10n.override = language
    }
}
