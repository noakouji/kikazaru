import AppKit

// 画面の見た目確認用。通常起動には影響しない。
if CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "--export-settings" {
    // 書き出し時だけ言語を固定できるようにする（配布サイトの日英ページ用）
    if let i = CommandLine.arguments.firstIndex(of: "--lang"),
       i + 1 < CommandLine.arguments.count,
       let lang = L10n.Language(rawValue: CommandLine.arguments[i + 1] == "en" ? "english" : "japanese") {
        L10n.override = lang
    }
    let demo = CommandLine.arguments.contains("--demo")
    await SettingsExporter.run(into: CommandLine.arguments[2], demo: demo)
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

// ゲイン固定が実際に効くかを確かめる。外から書き換えて、戻るかを見る。
if CommandLine.arguments.contains("--gaintest") {
    let device = MicGainLock.defaultInputDevice()
    print("入力機器: \(MicMonitor.deviceName(device))  変更可: \(MicGainLock.isSettable(device))")
    guard let before = MicGainLock.gain(of: device) else {
        print("❌ ゲインを読めません"); exit(1)
    }
    print("開始時のゲイン: \(Int((before * 100).rounded()))%")

    let lock = MicGainLock()
    lock.onCorrected = { changed, restored in
        print("↩︎ \(Int((changed * 100).rounded()))% に変えられたので \(Int((restored * 100).rounded()))% に戻しました")
    }
    lock.start()
    lock.lock()

    // 他のアプリが上げた状況を再現する
    let intruder = min(before + 0.25, 1.0)
    print("→ 外部から \(Int((intruder * 100).rounded()))% に変更してみます")
    MicGainLock.setGain(intruder, on: device)
    try? await Task.sleep(nanoseconds: 1_500_000_000)

    let after = MicGainLock.gain(of: device) ?? -1
    let ok = abs(after - before) < 0.02
    print("\(ok ? "✅" : "❌") 1.5秒後のゲイン: \(Int((after * 100).rounded()))%（期待: \(Int((before * 100).rounded()))%）")
    lock.stop()
    MicGainLock.setGain(before, on: device)
    exit(ok ? 0 : 1)
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
