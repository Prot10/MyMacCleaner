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
        case .spanish: return "Español"
        }
    }

    var displayName: String {
        nativeName
    }

    var shortCode: String {
        rawValue.uppercased()
    }
}

// MARK: - Localized String Helper

/// Cache for loaded string dictionaries to avoid repeated file I/O
private var stringsCache: [String: [String: String]] = [:]
private let stringsCacheLock = NSLock()

/// Load strings dictionary for a given language
private func loadStrings(for languageCode: String) -> [String: String]? {
    stringsCacheLock.lock()
    defer { stringsCacheLock.unlock() }

    // Check cache first
    if let cached = stringsCache[languageCode] {
        return cached
    }

    // Try to load from the lproj folder
    guard let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
        print("[Localization] No lproj found for: \(languageCode)")
        return nil
    }

    let stringsPath = (lprojPath as NSString).appendingPathComponent("Localizable.strings")
    let stringsURL = URL(fileURLWithPath: stringsPath)

    // Load the plist using PropertyListSerialization for better UTF-16 handling
    guard let data = try? Data(contentsOf: stringsURL),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
          let dict = plist as? [String: String] else {
        print("[Localization] Failed to load strings from: \(stringsPath)")
        return nil
    }

    print("[Localization] Loaded \(dict.count) strings for: \(languageCode)")

    // Cache it
    stringsCache[languageCode] = dict
    return dict
}

/// Clear the strings cache (call when language changes)
func clearLocalizationCache() {
    stringsCacheLock.lock()
    stringsCache.removeAll()
    stringsCacheLock.unlock()
    print("[Localization] Cache cleared")
}

/// Helper function to get localized string using the app's selected language
/// Use for ALL localization: L("home.title"), L("common.cancel"), L("navigation.\(rawValue)")
///
/// IMPORTANT: This takes a plain String, NOT String.LocalizationValue!
/// The old version using String.LocalizationValue was broken because "\(key)" on
/// a LocalizationValue performs Apple's localization, not key extraction.
func L(_ key: String) -> String {
    let languageCode = LocalizationManager.shared.languageCode

    // Load strings dictionary for current language
    if let dict = loadStrings(for: languageCode), let value = dict[key] {
        return value
    }

    // Fallback to English
    if languageCode != "en", let dict = loadStrings(for: "en"), let value = dict[key] {
        return value
    }

    // Final fallback - return the key itself
    return key
}

/// Alias for backwards compatibility with code using L(key:)
func L(key: String) -> String {
    return L(key)
}

/// Helper function for format strings with arguments
/// Example: LFormat("diskCleaner.itemsFound %lld", count)
/// The key in String Catalog should include the format specifier
func LFormat(_ keyPattern: String, _ args: CVarArg...) -> String {
    let languageCode = LocalizationManager.shared.languageCode

    // Try current language
    if let dict = loadStrings(for: languageCode), let format = dict[keyPattern] {
        return String(format: format, arguments: args)
    }

    // Fallback to English
    if languageCode != "en", let dict = loadStrings(for: "en"), let format = dict[keyPattern] {
        return String(format: format, arguments: args)
    }

    // Final fallback - return keyPattern with args substituted
    return String(format: keyPattern, arguments: args)
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
        print("[Localization] Setting language to: \(language.rawValue)")
        languageCode = language.rawValue
        storedLanguageCode = language.rawValue
        // Clear the cache so strings are reloaded with new language
        clearLocalizationCache()
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
