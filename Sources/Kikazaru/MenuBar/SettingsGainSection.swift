import SwiftUI

/// 「マイクのゲインを固定する」欄。
///
/// 通話アプリは通話の途中で OS 側の入力ゲインそのものを書き換えることがある。
/// 一度上げられた値は次の音声入力にも引き継がれ、部屋の音まで拾うようになる。
/// ここで固定しておくと、上げられた瞬間に元の値へ戻す。
extension SettingsView {

    var gainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.t("マイクのゲインを固定する", "Keep the mic gain where you put it"),
                  systemImage: "mic.badge.plus").font(.headline)

            Toggle(L10n.t("勝手に変えられたら元に戻す", "Put it back if something changes it"),
                   isOn: Binding(
                    get: { settings.micGainLockEnabled },
                    set: { on in
                        settings.micGainLockEnabled = on
                        // 有効にした時点の値を基準にする。使い慣れた位置がそのまま残る。
                        if on { settings.micGainTarget = Double(currentGain ?? 0.55) }
                        refreshGain()
                    }))

            if settings.micGainLockEnabled {
                HStack(spacing: 8) {
                    Text(L10n.t("固定する値", "Locked at"))
                    Slider(value: $settings.micGainTarget, in: 0...1)
                    Text("\(Int((settings.micGainTarget * 100).rounded()))%")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 44, alignment: .trailing)
                }

                Button(L10n.t("いまの値で固定する", "Lock at the current value")) {
                    if let now = currentGain { settings.micGainTarget = Double(now) }
                }
                .controlSize(.small)
            }

            HStack(spacing: 6) {
                Text(L10n.t("いまの入力", "Current input"))
                Text(gainDeviceName)
                    .foregroundStyle(.secondary)
                Text(currentGain.map { "\(Int(($0 * 100).rounded()))%" } ?? "—")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .font(.caption)

            md(L10n.t("""
                Google Meet や Zoom は、通話中に **Mac の入力ゲインそのもの** を書き換えることがあります。\
                上げられた値はそのまま残るので、通話が終わったあとの音声入力でも部屋の音を拾い続けます。

                固定しておくと、変えられた瞬間に元の値へ戻します。\
                機器ごとに別々に覚えるので、マイクを差し替えても持ち越しません。
                """,
                """
                Google Meet and Zoom can rewrite **the Mac's own input gain** mid-call. \
                The raised value simply stays there, so your dictation keeps picking up the room afterwards.

                Locking it puts the value straight back whenever something moves it. \
                Each device is remembered separately, so swapping microphones carries nothing over.
                """))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !gainIsSettable {
                Label(L10n.t("この入力機器はゲインを変えられません",
                             "This input device does not expose a gain control"),
                      systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
    }
}
