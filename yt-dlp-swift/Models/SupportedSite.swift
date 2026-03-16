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
    let nameZhHant: String?
    let nameZhHans: String?
    let nameKo: String?
    let nameRu: String?
    let nameEs: String?
    let nameFr: String?
    let nameDe: String?
    let nameIt: String?
    let namePt: String?
    let sites: [SiteInfo]

    enum CodingKeys: String, CodingKey {
        case id, sites
        case nameJa = "name_ja"
        case nameEn = "name_en"
        case nameZhHant = "name_zh_hant"
        case nameZhHans = "name_zh_hans"
        case nameKo = "name_ko"
        case nameRu = "name_ru"
        case nameEs = "name_es"
        case nameFr = "name_fr"
        case nameDe = "name_de"
        case nameIt = "name_it"
        case namePt = "name_pt"
    }

    var displayName: String { nameJa }

    var localizedName: String {
        switch L10n.lang {
        case .ja: return nameJa
        case .en: return nameEn ?? nameJa
        case .zhHant: return nameZhHant ?? nameEn ?? nameJa
        case .zhHans: return nameZhHans ?? nameEn ?? nameJa
        case .ko: return nameKo ?? nameEn ?? nameJa
        case .ru: return nameRu ?? nameEn ?? nameJa
        case .es: return nameEs ?? nameEn ?? nameJa
        case .fr: return nameFr ?? nameEn ?? nameJa
        case .de: return nameDe ?? nameEn ?? nameJa
        case .it: return nameIt ?? nameEn ?? nameJa
        case .pt: return namePt ?? nameEn ?? nameJa
        }
    }
}

struct SiteInfo: Identifiable, Codable, Hashable {
    var id: String { extractorPattern }
    let extractorPattern: String
    let nameJa: String
    let nameEn: String?
    let descriptionJa: String?
    let descriptionEn: String?
    let requiresLogin: Bool?
    let requiresJsRuntime: Bool?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case extractorPattern = "extractor_pattern"
        case nameJa = "name_ja"
        case nameEn = "name_en"
        case descriptionJa = "description_ja"
        case descriptionEn = "description_en"
        case requiresLogin = "requires_login"
        case requiresJsRuntime = "requires_js_runtime"
        case url
    }

    var localizedName: String {
        switch L10n.lang {
        case .ja: return nameJa
        default: return nameEn ?? nameJa
        }
    }

    var localizedDescription: String? {
        switch L10n.lang {
        case .ja: return descriptionJa
        default: return descriptionEn ?? descriptionJa
        }
    }
}
