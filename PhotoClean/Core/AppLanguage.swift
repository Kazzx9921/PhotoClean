import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = ""
    case en = "en"
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case ja = "ja"
    case es = "es"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return String(localized: "System default")
        case .en: return "English"
        case .zhHant: return "繁體中文"
        case .zhHans: return "简体中文"
        case .ja: return "日本語"
        case .es: return "Español"
        }
    }

    static var applicableRawValues: Set<String> {
        Set(allCases.compactMap { $0 == .system ? nil : $0.rawValue })
    }
}
