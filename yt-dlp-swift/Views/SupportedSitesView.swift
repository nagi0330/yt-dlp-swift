import SwiftUI

struct SupportedSitesView: View {
    @State private var siteRegistry = SiteRegistry.shared
    @State private var searchText = ""
    @State private var loginSite: SiteInfo?
    @State private var cookieRefreshID = UUID()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text(L10n.supportedSitesList)
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(L10n.close) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            // 検索
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(L10n.searchSitesPlaceholder, text: $searchText)
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
                    Section(category.localizedName) {
                        ForEach(filteredSites(in: category)) { site in
                            SiteRow(
                                site: site,
                                hasCookies: CookieManager.shared.hasCookies(for: site.extractorPattern),
                                onLogin: { loginSite = site },
                                onLogout: {
                                    try? CookieManager.shared.removeCookies(for: site.extractorPattern)
                                    cookieRefreshID = UUID()
                                }
                            )
                        }
                    }
                }

                if !siteRegistry.allExtractors.isEmpty {
                    Section {
                        Text(L10n.totalSitesSupported(siteRegistry.allExtractors.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .id(cookieRefreshID)
        }
        .task {
            siteRegistry.loadSiteData()
            await siteRegistry.fetchExtractors()
        }
        .sheet(item: $loginSite) { site in
            LoginWebView(site: site) {
                cookieRefreshID = UUID()
            }
            .frame(minWidth: 800, minHeight: 600)
        }
    }

    // アダルトカテゴリを最後に、非対応サイトを除外
    private var filteredCategories: [SiteCategory] {
        let sorted = siteRegistry.categories.sorted { a, b in
            if a.id == "adult" { return false }
            if b.id == "adult" { return true }
            return false // 元の順序を維持
        }
        return sorted.filter { !filteredSites(in: $0).isEmpty }
    }

    private func filteredSites(in category: SiteCategory) -> [SiteInfo] {
        let available = category.sites.filter {
            siteRegistry.isExtractorAvailable($0.extractorPattern)
        }
        if searchText.isEmpty {
            return available
        }
        let query = searchText.lowercased()
        return available.filter {
            $0.localizedName.lowercased().contains(query) ||
            $0.nameJa.lowercased().contains(query) ||
            ($0.nameEn?.lowercased().contains(query) ?? false) ||
            $0.extractorPattern.lowercased().contains(query)
        }
    }
}

struct SiteRow: View {
    let site: SiteInfo
    let hasCookies: Bool
    let onLogin: () -> Void
    let onLogout: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(site.localizedName)
                        .font(.body)

                    if site.requiresLogin == true {
                        Text(L10n.requiresLogin)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }

                    if site.requiresJsRuntime == true {
                        Text(L10n.jsRequired)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.purple.opacity(0.15), in: Capsule())
                            .foregroundStyle(.purple)
                    }

                    if hasCookies {
                        Text(L10n.loggedIn)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(.green.opacity(0.15), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }

                if let desc = site.localizedDescription {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // ログインボタン (要ログインサイトのみ)
            if site.requiresLogin == true && site.url != nil {
                if hasCookies {
                    Menu {
                        Button(L10n.reLogin) { onLogin() }
                        Button(L10n.logoutDeleteCookies, role: .destructive) { onLogout() }
                    } label: {
                        Label(L10n.loggedIn, systemImage: "person.crop.circle.badge.checkmark")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                } else {
                    Button {
                        onLogin()
                    } label: {
                        Label(L10n.login, systemImage: "person.crop.circle.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}
