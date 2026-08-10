import AppKit

// 画面の見た目確認用。通常起動には影響しない。
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-settings" {
    let path = CommandLine.arguments[2]
    await SettingsExporter.run(into: path)
    exit(0)
}

if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-poster" {
    PosterExporter.run(into: CommandLine.arguments[2])
    exit(0)
}
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-about" {
    await AboutExporter.run(into: CommandLine.arguments[2])
    exit(0)
}

// 検出だけ実行して結果を出す。トラブル時の切り分け用。
if CommandLine.arguments.contains("--scan") {
    let found = await SpeakersAction().refresh()
    if found.isEmpty {
        print("見つかりませんでした")
    } else {
        for kind in SpeakerKind.allCases {
            let list = found.filter { $0.kind == kind }
            print("[\(kind.label)] \(list.isEmpty ? "なし" : "\(list.count)台")")
            for s in list {
                let v = (try? await s.volume()).map(String.init) ?? "?"
                print("    \(s.name)  音量=\(v)  id=\(s.id)")
            }
        }
    }
    exit(0)
}

// 読み書き両方を確かめる。音量は「今の値をそのまま書き戻す」ので聞こえ方は変わらない。
if CommandLine.arguments.contains("--selftest") {
    for speaker in await SpeakersAction().refresh() {
        do {
            let before = try await speaker.volume()
            try await speaker.setVolume(before)
            let after = try await speaker.volume()
            let ok = before == after
            print("\(ok ? "✅" : "⚠️") [\(speaker.kind.label)] \(speaker.name)  読み=\(before) 書き戻し後=\(after)")
        } catch {
            print("❌ [\(speaker.kind.label)] \(speaker.name)  \(error)")
        }
    }
    exit(0)
}

// メニューバーのみで動かすため .accessory を指定する。
// Dock にもアプリスイッチャーにも出ない。
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate
app.run()
