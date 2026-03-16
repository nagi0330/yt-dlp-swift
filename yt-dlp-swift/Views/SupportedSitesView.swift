import SwiftUI

struct SupportedSitesView: View {
    @State private var siteRegistry = SiteRegistry.shared
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("対応サイト一覧")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("閉じる") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            // 検索
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("サイトを検索...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal)

            Divider()
                .padding(.top, 8)

            // サイト一覧
            List {
                ForEach(filteredCategories) { category in
                    Section(category.displayName) {
                        ForEach(filteredSites(in: category)) { site in
                            SiteRow(site: site, isAvailable: siteRegistry.isExtractorAvailable(site.extractorPattern))
                        }
                    }
                }

                // yt-dlpから動的取得したエクストラクター数
                if !siteRegistry.allExtractors.isEmpty {
                    Section {
                        Text("yt-dlp は合計 \(siteRegistry.allExtractors.count) サイトに対応しています")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .task {
            siteRegistry.loadSiteData()
            await siteRegistry.fetchExtractors()
        }
    }

    private var filteredCategories: [SiteCategory] {
        if searchText.isEmpty {
            return siteRegistry.categories
        }
        return siteRegistry.categories.filter { category in
            !filteredSites(in: category).isEmpty
        }
    }

    private func filteredSites(in category: SiteCategory) -> [SiteInfo] {
        if searchText.isEmpty {
            return category.sites
        }
        let query = searchText.lowercased()
        return category.sites.filter {
            $0.nameJa.lowercased().contains(query) ||
            $0.extractorPattern.lowercased().contains(query)
        }
    }
}

struct SiteRow: View {
    let site: SiteInfo
    let isAvailable: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(site.nameJa)
                        .font(.body)

                    if site.requiresLogin == true {
                        Text("要ログイン")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }

                    if site.requiresJsRuntime == true {
                        Text("JS必須")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }

                if let desc = site.descriptionJa {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // 対応状況
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "questionmark.circle")
                .foregroundStyle(isAvailable ? .green : .secondary)
        }
    }
}
