import Foundation

struct SupportedSitesData: Codable {
    let version: String
    let note: String?
    let categories: [SiteCategory]
}

struct SiteCategory: Identifiable, Codable {
    let id: String
    let nameJa: String
    let nameEn: String?
    let sites: [SiteInfo]

    enum CodingKeys: String, CodingKey {
        case id
        case nameJa = "name_ja"
        case nameEn = "name_en"
        case sites
    }

    var displayName: String { nameJa }
}

struct SiteInfo: Identifiable, Codable {
    var id: String { extractorPattern }
    let extractorPattern: String
    let nameJa: String
    let descriptionJa: String?
    let requiresLogin: Bool?
    let requiresJsRuntime: Bool?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case extractorPattern = "extractor_pattern"
        case nameJa = "name_ja"
        case descriptionJa = "description_ja"
        case requiresLogin = "requires_login"
        case requiresJsRuntime = "requires_js_runtime"
        case url
    }
}
