import Foundation

/// 日本語と英語の切り替え。
///
/// 文言の数が少ないので、キー表を持たずに呼び出し側で日英を並べて書く。
/// 「どの文言がどう訳されるか」がその場で読めるほうが、ずれに気づきやすい。
enum L10n {

    enum Language: String, CaseIterable, Sendable {
        case auto, japanese, english

        var label: String {
            switch self {
            case .auto: return L10n.isJapanese ? "システムに合わせる" : "Match system"
            case .japanese: return "日本語"
            case .english: return "English"
            }
        }
    }

    /// 設定から上書きされる。auto のときは OS の言語設定に従う。
    nonisolated(unsafe) static var override: Language = .auto

    static var isJapanese: Bool {
        switch override {
        case .japanese: return true
        case .english: return false
        case .auto:
            return Locale.preferredLanguages.first?.hasPrefix("ja") ?? false
        }
    }

    /// 日本語と英語を並べて渡す。
    static func t(_ ja: String, _ en: String) -> String {
        isJapanese ? ja : en
    }
}
