import SwiftUI

/// 設定画面のうち「アプリごとの動き」の部分。
///
/// 音声入力と会議は求めるものが違う。前者は少し下げるだけでよく、後者は完全に黙らせたい。
/// カメラの有無で見分ける案もあったが、会議でカメラを切ることがあるので確実ではない。
/// マイクを使っているアプリそのもので判断し、振り分けはユーザーが決められるようにする。
extension SettingsView {

    /// 表示上の 1 行。同じアプリが複数の識別子を持つことがあるのでまとめて扱う。
    struct AppEntry: Identifiable {
        let name: String
        let bundleIDs: [String]
        let seen: Bool
        var id: String { name }
    }

    var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.t("アプリごとの動き", "Per-app behavior"), systemImage: "app.badge")
                .font(.headline)

            Text(L10n.t(
                "マイクを使ったアプリがここに並びます。アプリごとに、音量を下げるか完全にミュートするかを選べます。音声入力は下げる、オンライン会議はミュート、が目安です。",
                "Apps that use your microphone appear here. Choose per app whether to lower the volume or mute it completely. Dictation usually works well lowered; meetings are better muted."))
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            appGroup(L10n.t("🔉 音量を下げる", "🔉 Lower the volume"), mode: .lower)
            appGroup(L10n.t("🔇 完全にミュートする", "🔇 Mute completely"), mode: .mute)

            HStack(spacing: 10) {
                Text(L10n.t("表に無いアプリは", "Apps not listed")).font(.callout)
                Picker("", selection: $settings.defaultMode) {
                    ForEach(DuckMode.allCases, id: \.self) { Text($0.label).tag($0) }
                }
                .labelsHidden().frame(width: 120)
                Spacer()
            }
        }
    }

    // MARK: - グループ

    private func appGroup(_ title: String, mode: DuckMode) -> some View {
        let entries = entries(for: mode)
        let seen = entries.filter(\.seen)
        let unseen = entries.filter { !$0.seen }

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(title).font(.subheadline).bold()
                Text(mode == .lower
                     ? L10n.t("元の音量の \(Int(settings.duckRatio * 100))% まで",
                              "to \(Int(settings.duckRatio * 100))% of original")
                     : L10n.t("完全に無音", "fully silent"))
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
            }

            if seen.isEmpty && unseen.isEmpty {
                Text(L10n.t("まだありません", "None yet"))
                    .font(.caption).foregroundStyle(.tertiary)
            }

            // 実際にマイクを使ったアプリだけ、常に見える位置に出す
            ForEach(seen) { appRow($0) }

            // まだ使われていないプリセットは畳んでおく。並べると長くなるだけなので。
            if !unseen.isEmpty {
                DisclosureGroup {
                    VStack(spacing: 6) {
                        ForEach(unseen) { appRow($0) }
                    }
                    .padding(.top, 6)
                } label: {
                    Text(L10n.t("よく使われるアプリ \(unseen.count)件（設定済み）",
                                "\(unseen.count) common apps (preconfigured)"))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.07)))
    }

    private func appRow(_ entry: AppEntry) -> some View {
        HStack(spacing: 8) {
            Text(entry.name).font(.callout)
            if entry.seen {
                Text(L10n.t("使用を確認", "seen"))
                    .font(.caption2)
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
                    .foregroundStyle(.green)
            }
            Spacer()
            Picker("", selection: Binding(
                get: { settings.mode(for: entry.bundleIDs[0]) },
                // 同じアプリの識別子はまとめて切り替える
                set: { newMode in
                    for id in entry.bundleIDs { settings.appModes[id] = newMode }
                })
            ) {
                ForEach(DuckMode.allCases, id: \.self) { Text($0.label).tag($0) }
            }
            .labelsHidden().frame(width: 110)
        }
    }

    // MARK: - 一覧の組み立て

    /// プリセットと、実際にマイクを使ったのを見たアプリを合わせ、
    /// 表示名が同じものは 1 行にまとめる。
    private func entries(for mode: DuckMode) -> [AppEntry] {
        let seenIDs = Set(model?.seenApps ?? [])
        let allIDs = Set(settings.appModes.keys).union(seenIDs)

        var grouped: [String: [String]] = [:]
        for id in allIDs where settings.mode(for: id) == mode {
            grouped[AppPresets.name(for: id), default: []].append(id)
        }
        return grouped
            .map { AppEntry(name: $0.key,
                            bundleIDs: $0.value.sorted(),
                            seen: $0.value.contains(where: seenIDs.contains)) }
            .sorted { ($0.seen ? 0 : 1, $0.name) < ($1.seen ? 0 : 1, $1.name) }
    }
}
