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

// MARK: - Table Mapping

/// Maps key prefixes to their String Catalog table names
private let keyPrefixToTable: [(prefix: String, table: String)] = [
    // Feature-specific tables (check longer prefixes first)
    ("applications.", "Applications"),
    ("category.", "DiskCleaner"),
    ("diskCleaner.", "DiskCleaner"),
    ("duplicates.", "Duplicates"),
    ("home.", "Home"),
    ("menuBar.", "MenuBar"),
    ("navigation.", "Common"),
    ("orphans.", "OrphanedFiles"),
    ("performance.", "Performance"),
    ("permissions.", "Permissions"),
    ("portManagement.", "PortManagement"),
    ("privacy.", "DiskCleaner"),
    ("scanResults.", "Home"),
    ("settings.", "Settings"),
    ("update.", "Settings"),
    ("sidebar.", "Common"),
    ("spaceLens.", "DiskCleaner"),
    ("startupItems.", "StartupItems"),
    ("systemHealth.", "SystemHealth"),
    ("common.", "Common"),
    ("comingSoon.", "Common"),
]

/// Determines the table name for a given key based on its prefix
private func tableForKey(_ key: String) -> String {
    for (prefix, table) in keyPrefixToTable {
        if key.hasPrefix(prefix) {
            return table
        }
    }
    // Default to Common for unmatched keys (format strings, symbols, etc.)
    return "Common"
}

// MARK: - Thread-Safe Localization Cache

/// Thread-safe cache for loaded string dictionaries using a reader-writer pattern
/// Uses a concurrent queue with barrier writes for optimal performance
/// Cache key format: "languageCode:tableName"
private final class LocalizationCache: @unchecked Sendable {
    private var cache: [String: [String: String]] = [:]
    private let queue = DispatchQueue(label: "com.mymaccleaner.localization", attributes: .concurrent)

    /// Perform a full lookup with fallback to English in a single atomic operation
    /// This prevents race conditions where the cache might change between lookups
    func lookup(key: String, languageCode: String) -> String {
        let table = tableForKey(key)

        // Perform the entire lookup atomically using a sync read
        return queue.sync {
            // Try current language in the appropriate table
            let currentDict = getOrLoadStrings(for: languageCode, table: table)
            if let value = currentDict?[key] {
                return value
            }

            // Fallback to English (if not already English)
            if languageCode != "en" {
                let englishDict = getOrLoadStrings(for: "en", table: table)
                if let value = englishDict?[key] {
                    return value
                }
            }

            // Try Common table as final fallback for shared strings
            if table != "Common" {
                let commonDict = getOrLoadStrings(for: languageCode, table: "Common")
                if let value = commonDict?[key] {
                    return value
                }
                if languageCode != "en" {
                    let commonEnDict = getOrLoadStrings(for: "en", table: "Common")
                    if let value = commonEnDict?[key] {
                        return value
                    }
                }
            }

            // Final fallback - return the key itself
            return key
        }
    }

    /// Clear all cached strings
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
            print("[Localization] Cache cleared")
        }
    }

    /// Get cached strings or load from disk (must be called within queue.sync)
    private func getOrLoadStrings(for languageCode: String, table: String) -> [String: String]? {
        let cacheKey = "\(languageCode):\(table)"

        // Check cache first
        if let cached = cache[cacheKey] {
            return cached
        }

        // Load from disk
        guard let dict = loadFromDisk(languageCode: languageCode, table: table) else {
            return nil
        }

        // Cache it (safe because we're in a sync block on the concurrent queue)
        // For writes, we need to use barrier, but since this is within a sync read,
        // we'll do a nested async barrier write
        let dictCopy = dict
        queue.async(flags: .barrier) { [weak self] in
            // Double-check in case another thread loaded it
            if self?.cache[cacheKey] == nil {
                self?.cache[cacheKey] = dictCopy
            }
        }

        return dict
    }

    /// Load strings dictionary from disk for a given language and table
    private func loadFromDisk(languageCode: String, table: String) -> [String: String]? {
        // Try to load from the lproj folder
        guard let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj") else {
            print("[Localization] No lproj found for: \(languageCode)")
            return nil
        }

        let stringsPath = (lprojPath as NSString).appendingPathComponent("\(table).strings")
        let stringsURL = URL(fileURLWithPath: stringsPath)

        // Load the plist using PropertyListSerialization for better UTF-16 handling
        guard let data = try? Data(contentsOf: stringsURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dict = plist as? [String: String] else {
            // Silent fail for missing tables - not all tables exist for all languages
            return nil
        }

        print("[Localization] Loaded \(dict.count) strings from \(table).strings for: \(languageCode)")
        return dict
    }
}

/// Shared localization cache instance
private let localizationCache = LocalizationCache()

/// Clear the strings cache (call when language changes)
func clearLocalizationCache() {
    localizationCache.clear()
}

// MARK: - Localized String Helpers

/// Helper function to get localized string using the app's selected language
/// Use for ALL localization: L("home.title"), L("common.cancel"), L("navigation.\(rawValue)")
///
/// IMPORTANT: This takes a plain String, NOT String.LocalizationValue!
/// The old version using String.LocalizationValue was broken because "\(key)" on
/// a LocalizationValue performs Apple's localization, not key extraction.
///
/// Thread-safe: Uses a reader-writer cache with atomic lookup operations.
func L(_ key: String) -> String {
    let languageCode = LocalizationManager.shared.languageCode
    return localizationCache.lookup(key: key, languageCode: languageCode)
}

/// Alias for backwards compatibility with code using L(key:)
func L(key: String) -> String {
    return L(key)
}

/// Helper function for format strings with arguments
/// Example: LFormat("diskCleaner.itemsFound %lld", count)
/// The key in String Catalog should include the format specifier
func LFormat(_ keyPattern: String, _ args: CVarArg...) -> String {
    let format = L(keyPattern)
    return String(format: format, arguments: args)
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
