# Kikazaru（聞かざる）

話している間だけ、部屋のスピーカーを黙らせる macOS のメニューバーアプリ。

名前は三猿の「聞かざる」から。マイクに BGM を聞かせない、という役割そのものを表している。
アイコンも待機中は耳を開け、音量を下げている間は手で耳を塞ぐ。

音声入力（ディクテーション、オンライン会議）を使うとき、スピーカーから流れる音楽が
マイクに回り込んで認識精度を落とす問題を解決する。ヘッドホンに切り替えず、スピーカー環境のまま使える。

```
マイクON        → 全ルームの音量をフェードダウン
ホットキー解放   → 即座に戻す（任意機能）
マイクOFF       → 猶予後に戻す
```

## なぜこの方式なのか

スピーカーの音がマイクに入る問題は、本来 AEC（音響エコーキャンセル）で消す。
AEC は「スピーカーに送った信号」と「マイクに入った音」の時間を突き合わせて引き算する仕組みだが、
AirPlay 経由の Sonos は遅延が 2 秒前後あり、しかも別クロックで動くため、この前提が崩れて機能しない。

そこで「消す」のをやめ、「喋っている間だけ鳴らさない」方式にした。

## 特徴

- **待機中の CPU 使用率 0.0%** — ポーリングせず、CoreAudio の通知で状態変化を受け取る
- **設定不要** — SSDP で自動検出するので IP を書かなくてよい。DHCP で変わっても追従する
- **権限なしで動く** — マイクの使用状態のみを読み、音声そのものは扱わない
- **音量が取り残されない** — 強制終了しても次回起動時に元の音量へ戻す
- **アクションを差し替えられる** — `DuckAction` を実装すれば Sonos 以外にも広げられる

## 対応スピーカー

| メーカー | 状態 | 検出方法 |
|---|---|---|
| **Sonos**（推奨） | ✅ 実機確認済み | SSDP。グループ構成を解析して可視メンバーのみ制御 |
| **Google Home / Chromecast** | ✅ 実機確認済み | Bonjour + CASTV2（TLS 上の protobuf を自前実装） |
| **Bose SoundTouch** | ⚠️ 実機未確認 | Bonjour + HTTP API（ポート 8090） |
| Mac から鳴らしているもの全部 | ✅ | 本体音量を下げる設定を on にする（Bluetooth / AirPlay 等） |

Sonos 以外は **初期状態でオフ**。テレビなど下げてほしくない機器を勝手に操作しないため、
設定画面で明示的にチェックを入れて有効にする。

## 動作要件

- macOS 14 以降
- Sonos アプリで **UPnP が有効**（アカウント → プライバシーとセキュリティ → UPnP）
- 接続セキュリティの **Authentication は OFF**（初期値。ON にすると弾かれる）

## ビルドと起動

```bash
./scripts/build-app.sh
open build/Kikazaru.app
```

メニューバーにアイコンが出れば動いている。Dock には表示されない。

## 設定

メニューバーのアイコン → 設定。

| 項目 | 既定値 | 内容 |
|---|---|---|
| ダッキング量 | 30% | 元の音量の何割まで下げるか |
| 復帰の猶予 | 0.4 秒 | 発話が途切れてから戻すまで |
| Mac 本体の音量も下げる | OFF | Sonos と同時に本体側も下げる |
| ホットキーで即座に戻す | OFF | アクセシビリティ権限が必要 |

### 復帰の猶予について

0 にしてはいけない。ディクテーションアプリは発話の切れ目でマイクを一瞬閉じて即座に開き直すことがあり、
猶予がないと音量が上下にばたつく。

### ホットキーによる高速復帰

ディクテーションアプリは、発話後もマイクを数秒保持する。
これは「最初や最後の単語を取りこぼさない」ための設計で、その間マイクは使用中のままになる。
結果として、マイクの状態だけを見ていると戻りが数秒遅れる。

ホットキーの解放を見れば待たずに戻せる。ただしアクセシビリティ権限が必要なため既定は無効。

ホットキーは**主役ではなく加速装置**として使う。オンライン会議アプリはホットキーを押さないので、
ホットキー単独では会議で機能しない。取り逃してもマイクOFF が保険として働き、音量が下がりっぱなしにならない。

## 構成

```
Sources/Kikazaru/
├── main.swift              エントリ（.accessory で Dock に出さない）
├── AppDelegate.swift
├── Core/
│   ├── Coordinator.swift   状態機械・デバウンス
│   ├── DuckAction.swift    アクションのプロトコル
│   ├── StateStore.swift    クラッシュ復元用の永続化
│   └── Settings.swift
├── Triggers/
│   ├── MicMonitor.swift    CoreAudio プロパティリスナー
│   └── HotkeyMonitor.swift CGEventTap（listenOnly）
├── Actions/
│   ├── SonosAction.swift
│   └── SystemVolumeAction.swift
├── Sonos/
│   ├── SonosDiscovery.swift
│   ├── SonosDevice.swift
│   └── SonosTopology.swift
└── MenuBar/
    ├── StatusItemController.swift
    └── SettingsView.swift
```

外部依存はゼロ。CoreAudio・AppKit・SwiftUI・URLSession のみ。

## アクションを追加する

`DuckAction` を実装して `AppDelegate` の配列に足すだけでよい。

```swift
protocol DuckAction: AnyObject, Sendable {
    var name: String { get }
    func duck(ratio: Double) async
    func restore() async
    func snapshot() -> [String: Int]        // クラッシュ復元用
    func apply(snapshot: [String: Int]) async
}
```

`SystemVolumeAction` が 2 つ目の実装例。Sonos 側のコードを触らずに追加できている。

## 実装上の注意（実機検証で判明）

Sonos の UPnP は非公開 API で、ドキュメントに書かれていない挙動がある。

- **`RampToVolume` はダッキングに使えない。** フェードイン専用で、目標値を指定すると
  いったん 0 まで落ちてから目標値へ上がる
- **`RestoreVolumePriorToRamp` は HTTP 500 を返す**（Arc Ultra / ファーム 96.0-79160）
- **親機の `TransportState` は信用できない。** メンバーが再生中でも親機が `STOPPED` を返すため、
  再生状態による分岐はしない
- **`GetZoneGroupState` の戻り値は二重 XML エスケープされている**
- グループ再生中は各機が自分の音量を持つため、**可視メンバー全員を個別に制御する**。
  サテライト（Sub・サラウンド）は親機に追従するので除外する
- **SSDP の M-SEARCH は改行が CRLF でないと応答が返らない。** また macOS では
  `sockaddr_in.sin_len` を設定しないと送信できない

## 実測値

Arc Ultra + Sub 4 + Era 300 の構成で測定。

| 項目 | 値 |
|---|---|
| 待機中の CPU | 0.0% |
| メモリ | 約 40 MB |
| SSDP 検出 | 3 台 / 約 3 秒 |
| `SetVolume` 往復 | 13〜16ms |
| フェード（5 段・全ルーム並列） | 約 125ms |

## legacy/

Swift 版の元になった Python 実装と、開発時に使った診断スクリプト。
マイクの使用状態やゲインのドリフトを調べるのに単体で使える。

| ファイル | 用途 |
|---|---|
| `sonos_duck.py` | Python 版の常駐スクリプト |
| `tools/sonos_discover.py` | SSDP で Sonos を探す |
| `tools/micprobe.py` | マイクの使用開始・終了をリアルタイム監視 |
| `tools/miclag.py` | マイクが開いている時間をミリ秒精度で計測 |
| `tools/outprobe.py` | 出力デバイスが音量・ミュート制御に対応しているか判定 |
| `tools/gainlog.py` | 入力音量の変化を高頻度で記録 |
| `tools/gainwatch.py` | 入力・出力音量とマイク状態を長時間記録（スリープ検出付き） |

## ライセンス

Private.
