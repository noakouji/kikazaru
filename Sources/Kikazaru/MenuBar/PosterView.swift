import AppKit
import SwiftUI

/// 紹介用の 1 枚画像。SNS で共有する想定で 16:9 に収める。
///
/// 説明の順番は「何が困るか → どう動くか → 実際の画面」。
/// 仕組みの話から入っても伝わらないので、まず困りごとを実例で見せる。
struct PosterView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.14))
            HStack(alignment: .top, spacing: 26) {
                leftColumn
                rightColumn
            }
            .padding(.horizontal, 30)
            .padding(.top, 22)
            Spacer(minLength: 0)
            footer
        }
        .frame(width: 1200, height: 675)
        .background(
            LinearGradient(colors: [
                Color(red: 0.13, green: 0.11, blue: 0.17),
                Color(red: 0.06, green: 0.05, blue: 0.09),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .foregroundStyle(.white)
    }

    // MARK: - ヘッダー

    private var header: some View {
        HStack(spacing: 18) {
            Text("🙉").font(.system(size: 58))
            VStack(alignment: .leading, spacing: 5) {
                Text("Kikazaru").font(.system(size: 40, weight: .bold))
                Text("マイクがオンの間だけ、部屋のBGMを下げる Mac アプリ")
                    .font(.system(size: 18)).foregroundStyle(.white.opacity(0.75))
            }
            Spacer()
            HStack(spacing: 6) {
                chip("macOS 専用")
                chip("メニューバー常駐")
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 18)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.12)))
    }

    // MARK: - 左：困りごと ＋ 動き

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            problem
            steps
            menuBarStrip
        }
        .frame(width: 620, alignment: .leading)
    }

    private var problem: some View {
        VStack(alignment: .leading, spacing: 10) {
            title("😩", "スピーカーで音楽を流していると、こうなる")

            VStack(alignment: .leading, spacing: 9) {
                line("話した内容", "さっきの議事録から、ネクストアクションだけ箇条書きにして",
                     .white.opacity(0.7), false)
                line("実際に入力された文字",
                     "さっきの議事録から、ネクストアクションだけ箇条書きにして 君と歩いた あの日の",
                     Color(red: 1.0, green: 0.72, blue: 0.35), true)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))

            Text("マイクが自分の声と一緒に、スピーカーの音楽まで拾ってしまうため。")
                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
        }
    }

    private func line(_ label: String, _ text: String,
                      _ color: Color, _ emphasize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.system(size: 11)).foregroundStyle(.white.opacity(0.4))
            Text("「\(text)」")
                .font(.system(size: 16, weight: emphasize ? .semibold : .regular))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            title("✅", "入れておくと、勝手にこうなる")
            HStack(spacing: 10) {
                stepCard(1, "🎙", "話し始める", "マイクがオンに\nなったのを検知")
                arrow
                stepCard(2, "🙉", "BGMが下がる", "約0.1秒で\nスピーカーを絞る")
                arrow
                stepCard(3, "🐵", "話し終わる", "元の音量へ\nそのまま戻る")
            }
        }
    }

    /// メニューバーだけで状態が分かることを見せる。
    private var menuBarStrip: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Text("🐵").font(.system(size: 26))
                Text("待機中").font(.system(size: 13))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 9).fill(.white.opacity(0.07)))

            arrow

            HStack(spacing: 8) {
                Text("🙉").font(.system(size: 26))
                Text("下げている").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.6))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 9).fill(.white.opacity(0.07)))

            Text("メニューバーの絵文字だけで、いまどちらか分かります")
                .font(.system(size: 13)).foregroundStyle(.white.opacity(0.5))
            Spacer()
        }
    }

    private var arrow: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white.opacity(0.3))
    }

    private func stepCard(_ number: Int, _ emoji: String,
                          _ title: String, _ detail: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("\(number)")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(.white.opacity(0.18)))
                Text(emoji).font(.system(size: 22))
            }
            Text(title).font(.system(size: 15, weight: .semibold))
            Text(detail)
                .font(.system(size: 12)).foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .frame(width: 168, height: 112)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.07)))
    }

    // MARK: - 右：実際の画面

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            title("🖥", "設定はチェックを入れるだけ")
            screenshot
            HStack(spacing: 6) {
                Text("対応").font(.system(size: 12)).foregroundStyle(.white.opacity(0.45))
                chip("Sonos")
                chip("Google Home")
                chip("Bose")
            }
        }
        .frame(width: 424, alignment: .leading)
    }

    /// 設定画面を模した図。
    ///
    /// 実画面を描画して貼る方法も試したが、チェックボックスなどの UI 部品は
    /// オフスクリーン描画では描かれず、崩れた絵になる。ここでは図として組み直す。
    private var screenshot: some View {
        VStack(spacing: 0) {
            windowBar
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 9) {
                    Text("🙉").font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Kikazaru").font(.system(size: 15, weight: .bold))
                        Text("マイクがオンの間だけ、BGMを下げます")
                            .font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Text("どのスピーカーを下げるか")
                    .font(.system(size: 13, weight: .semibold))

                speakerGroup("Sonos", badge: "推奨", rows: [
                    ("リビング", true), ("書斎", true),
                ])
                speakerGroup("Google Home", badge: nil, rows: [
                    ("キッチン", false), ("寝室", false),
                ])
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(width: 424, height: 268, alignment: .topLeading)
            .background(Color(red: 0.96, green: 0.96, blue: 0.97))
        }
        .foregroundStyle(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.14)))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 8)
    }

    private func speakerGroup(_ name: String, badge: String?,
                              rows: [(String, Bool)]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(name).font(.system(size: 12, weight: .semibold))
                if let badge {
                    Text(badge)
                        .font(.system(size: 9))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.2)))
                        .foregroundStyle(Color.green)
                }
                Spacer()
            }
            ForEach(rows, id: \.0) { row in
                HStack(spacing: 7) {
                    Image(systemName: row.1 ? "checkmark.square.fill" : "square")
                        .font(.system(size: 12))
                        .foregroundStyle(row.1 ? Color.accentColor : Color.black.opacity(0.25))
                    Text(row.0).font(.system(size: 12))
                    Spacer()
                    Text(row.1 ? "下げる" : "そのまま")
                        .font(.system(size: 10))
                        .foregroundStyle(row.1 ? Color.green : Color.black.opacity(0.35))
                }
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.05)))
    }

    private var windowBar: some View {
        HStack(spacing: 6) {
            ForEach([Color(red: 1, green: 0.37, blue: 0.34),
                     Color(red: 1, green: 0.74, blue: 0.18),
                     Color(red: 0.16, green: 0.79, blue: 0.25)], id: \.self) { color in
                Circle().fill(color).frame(width: 9, height: 9)
            }
            Spacer()
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(Color(red: 0.92, green: 0.92, blue: 0.93))
    }

    private func title(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 9) {
            Text(emoji).font(.system(size: 20))
            Text(text).font(.system(size: 19, weight: .bold))
        }
    }

    // MARK: - フッター

    private var footer: some View {
        HStack(spacing: 14) {
            Text("ヘッドホンに切り替えなくても、音楽を流したまま喋れます。")
                .font(.system(size: 16, weight: .medium))
            Spacer()
            Text("ニッチすぎる自覚はあります。欲しい方はご連絡ください 🙏")
                .font(.system(size: 15)).foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.05))
    }
}
