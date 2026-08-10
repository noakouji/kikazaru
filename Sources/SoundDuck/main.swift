import Foundation

// 2周目: マイク監視（イベント駆動）と状態機械の検証用エントリ。
// メニューバー UI を載せる段階で AppDelegate に差し替える。

@MainActor
func runVerification() async {
    let sonos = SonosAction()
    var settings = Settings()
    settings.releaseDelay = 0.4

    print("=== 制御対象を取得 ===")
    let rooms = await sonos.refreshRooms()
    guard !rooms.isEmpty else {
        print("  ❌ Sonos が見つかりません")
        exit(1)
    }
    for room in rooms {
        let v = (try? await room.volume()).map(String.init) ?? "?"
        print("    \(room.roomName)  \(room.ip)  音量=\(v)")
    }

    let device = MicMonitor.defaultInputDevice()
    print("\n=== 入力デバイス ===")
    print("    \(MicMonitor.deviceName(device))  使用中=\(MicMonitor.isRunning(device))")

    let coordinator = Coordinator(actions: [sonos], settings: settings)
    coordinator.onStateChange = { state in
        let stamp = DateFormatter.localizedString(
            from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(stamp)] \(state == .ducked ? "🔉 下げた" : "🔊 戻した")")
    }

    print("\n=== 監視開始（60秒）。喋ってみてください ===")
    await coordinator.start()

    try? await Task.sleep(nanoseconds: 60_000_000_000)
    await coordinator.shutdown()

    print("\n=== 終了後の音量 ===")
    for room in sonos.currentRooms {
        let v = (try? await room.volume()).map(String.init) ?? "?"
        print("    \(room.roomName)  音量=\(v)")
    }
}

await runVerification()
