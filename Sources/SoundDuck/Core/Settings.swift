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

    private enum Key {
        static let ratio = "duckRatio"
        static let delay = "releaseDelay"
        static let hotkey = "hotkeyEnabled"
        static let systemVolume = "systemVolumeEnabled"
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
        return s
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(duckRatio, forKey: Key.ratio)
        defaults.set(releaseDelay, forKey: Key.delay)
        defaults.set(hotkeyEnabled, forKey: Key.hotkey)
        defaults.set(systemVolumeEnabled, forKey: Key.systemVolume)
    }
}
