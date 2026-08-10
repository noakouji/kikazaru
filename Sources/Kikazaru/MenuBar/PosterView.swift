import SwiftUI

/// 紹介用の 1 枚画像。SNS で共有する想定で 16:9 に収める。
///
/// 画面の実物ではなく、伝わる順序に組み直したもの。
/// 「何が困るのか」を先に見せてから、解決を出す。
struct PosterView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.15))
            HStack(alignment: .top, spacing: 28) {
                problemColumn
                solutionColumn
            }
            .padding(.horizontal, 28)
            .padding(.top, 26)
            Spacer(minLength: 0)
            menuBarBand
            Spacer(minLength: 0)
            footer
        }
        .frame(width: 1200, height: 675)
        .background(
            LinearGradient(colors: [
                Color(red: 0.13, green: 0.11, blue: 0.16),
                Color(red: 0.07, green: 0.06, blue: 0.09),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundStyle(.white)
    }

    // MARK: - ヘッダー

    private var header: some View {
        HStack(spacing: 20) {
            Text("🙉").font(.system(size: 68))
            VStack(alignment: .leading, spacing: 6) {
                Text("Kikazaru").font(.system(size: 46, weight: .bold))
                Text("マイクがオンの間だけ、部屋のBGMを下げる Mac アプリ")
                    .font(.system(size: 20)).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                tag("macOS 専用")
                tag("メニューバー常駐")
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.12)))
    }

    // MARK: - 左：困りごと

    private var problemColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            columnTitle("😩", "音声入力に、BGMが混ざる")

            VStack(alignment: .leading, spacing: 10) {
                quote("話した内容", "明日の定例は10時からです", .white.opacity(0.65))
                quote("入力された文字", "明日の定例は10時からです 君と歩いた あの日の",
                      Color(red: 1.0, green: 0.72, blue: 0.35))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))

            Text("音声入力アプリが下げてくれるのは Mac につないだスピーカーだけ。\nSonos や Google Home は、スピーカー自身が鳴らしているので止まりません。")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 520, alignment: .leading)
    }

    private func quote(_ label: String, _ text: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
            Text("「\(text)」").font(.system(size: 17)).foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 右：解決

    private var solutionColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            columnTitle("🙉", "話している間だけ、勝手に下がる")

            VStack(alignment: .leading, spacing: 14) {
                step("🎙", "話し始める", "マイクがオンになったのを検知")
                step("🙉", "BGMが下がる", "約0.1秒でスピーカー本体の音量を下げる")
                step("🐵", "話し終わる", "元の音量にそのまま戻す")
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))

            HStack(spacing: 8) {
                Text("対応").font(.system(size: 13)).foregroundStyle(.white.opacity(0.45))
                tag("Sonos")
                tag("Google Home")
                tag("Bose")
            }
        }
        .frame(width: 520, alignment: .leading)
    }

    private func columnTitle(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji).font(.system(size: 26))
            Text(text).font(.system(size: 22, weight: .bold))
        }
    }

    private func step(_ emoji: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 24))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 17, weight: .semibold))
                Text(detail).font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - メニューバーの見え方

    /// 状態がアイコンで分かることを、実物に近い形で見せる。
    private var menuBarBand: some View {
        HStack(spacing: 22) {
            menuBarChip("🐵", "待機中", "BGMはそのまま", .white.opacity(0.5))
            Image(systemName: "arrow.right").font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.35))
            menuBarChip("🙉", "話している間", "BGMが下がる",
                        Color(red: 0.45, green: 0.85, blue: 0.6))
            Spacer()
            Text("メニューバーの絵文字だけで、\nいまどちらの状態か分かります。")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 28)
    }

    private func menuBarChip(_ emoji: String, _ title: String,
                             _ detail: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold))
                Text(detail).font(.system(size: 13)).foregroundStyle(color)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))
    }

    // MARK: - フッター

    private var footer: some View {
        HStack(spacing: 14) {
            Text("ヘッドホンに切り替えなくても、音楽を流したまま喋れます。")
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Text("ニッチすぎる自覚はあります。欲しい方はご連絡ください 🙏")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
    }
}
