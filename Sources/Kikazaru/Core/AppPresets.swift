import Foundation

/// アプリごとの初期の振り分け。
///
/// 音声入力は少し下げるだけでよく、オンライン会議は完全に黙らせたい。
/// 用途がはっきり違うので、最初からグループを分けておく。
/// ここに無いアプリも、マイクを使えば設定画面に出てきて後から振り分けられる。
enum AppPresets {

    /// 音声入力・ディクテーション
    static let dictation: [String: String] = [
        "aquavoice.macOSBridge": "Aqua Voice",
        "com.aquavoice.AquaVoice": "Aqua Voice",
        "com.apple.SpeechRecognitionCore.speechrecognitiond": L10n.t("macOS 音声入力", "macOS Dictation"),
        "com.apple.assistantd": L10n.t("macOS 音声入力", "macOS Dictation"),
        "com.superduper.superwhisper": "superwhisper",
        "com.goodsnooze.MacWhisper": "MacWhisper",
        "com.wispr.flow": "Wispr Flow",
        "com.electron.wispr-flow": "Wispr Flow",
    ]

    /// オンライン会議・通話
    static let meeting: [String: String] = [
        "com.google.Chrome": "Google Chrome",
        "us.zoom.xos": "Zoom",
        "com.microsoft.teams2": "Microsoft Teams",
        "com.microsoft.teams": "Microsoft Teams",
        "com.tinyspeck.slackmacgap": "Slack",
        "com.hnc.Discord": "Discord",
        "Cisco-Systems.Spark": "Webex",
        "com.apple.FaceTime": "FaceTime",
        "company.thebrowser.Browser": "Arc",
        "com.apple.Safari": "Safari",
        "org.mozilla.firefox": "Firefox",
    ]

    /// 初期状態の振り分け表
    static var defaultModes: [String: DuckMode] {
        var modes: [String: DuckMode] = [:]
        for id in dictation.keys { modes[id] = .lower }
        for id in meeting.keys { modes[id] = .mute }
        return modes
    }

    /// プリセットに名前があればそれを使う。無ければ実際のアプリ名を引く。
    static func name(for bundleID: String) -> String {
        dictation[bundleID] ?? meeting[bundleID] ?? MicUsers.displayName(for: bundleID)
    }
}
