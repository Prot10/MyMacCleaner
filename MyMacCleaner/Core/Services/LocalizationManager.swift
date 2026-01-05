import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case italian = "it"
    case spanish = "es"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        case .spanish: return "Espanol"
        }
    }

    var displayName: String {
        nativeName
    }

    var shortCode: String {
        rawValue.uppercased()
    }
}

// MARK: - Localization Manager

@Observable
class LocalizationManager {
    static let shared = LocalizationManager()

    @ObservationIgnored
    @AppStorage("appLanguage") private var storedLanguageCode: String?

    private(set) var languageCode: String = "en"

    var locale: Locale {
        Locale(identifier: languageCode)
    }

    var currentLanguage: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    init() {
        // Initialize with stored preference or system language
        if let stored = storedLanguageCode {
            languageCode = stored
        } else {
            languageCode = detectSystemLanguage()
        }
    }

    func setLanguage(_ language: AppLanguage) {
        languageCode = language.rawValue
        storedLanguageCode = language.rawValue
    }

    private func detectSystemLanguage() -> String {
        // Get system language code
        let systemLang = Locale.current.language.languageCode?.identifier ?? "en"

        // Only use system language if it's one of our supported languages
        if AppLanguage(rawValue: systemLang) != nil {
            return systemLang
        }

        // Fallback to English
        return "en"
    }
}
