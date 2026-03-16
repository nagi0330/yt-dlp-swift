import Foundation

// 対応サイト一覧の管理
@Observable
class SiteRegistry {
    static let shared = SiteRegistry()

    var categories: [SiteCategory] = []
    var allExtractors: [String] = []
    var isLoading = false

    // SupportedSites.jsonからカテゴリデータを読み込み
    func loadSiteData() {
        guard let url = Bundle.main.url(forResource: "SupportedSites", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(SupportedSitesData.self, from: data)
            categories = decoded.categories
        } catch {
            print("SupportedSites.json の読み込みに失敗: \(error)")
        }
    }

    // yt-dlpから動的にエクストラクター一覧を取得
    func fetchExtractors() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allExtractors = try await YtDlpService.shared.listExtractors()
        } catch {
            print("エクストラクター一覧の取得に失敗: \(error)")
        }
    }

    // エクストラクターが利用可能かチェック
    func isExtractorAvailable(_ pattern: String) -> Bool {
        guard !allExtractors.isEmpty else { return true } // 未取得の場合はtrue
        return allExtractors.contains(where: {
            $0.lowercased().contains(pattern.lowercased())
        })
    }
}
