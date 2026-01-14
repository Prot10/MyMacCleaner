import Foundation

// MARK: - Browser Types

enum BrowserType: String, CaseIterable, Identifiable {
    case safari = "Safari"
    case chrome = "Chrome"
    case firefox = "Firefox"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .safari: return "safari"
        case .chrome: return "globe"
        case .firefox: return "flame"
        }
    }

    var isInstalled: Bool {
        switch self {
        case .safari:
            return FileManager.default.fileExists(atPath: "/Applications/Safari.app")
        case .chrome:
            return FileManager.default.fileExists(atPath: "/Applications/Google Chrome.app")
        case .firefox:
            return FileManager.default.fileExists(atPath: "/Applications/Firefox.app")
        }
    }
}

// MARK: - Browser Data Types

enum BrowserDataType: String, CaseIterable, Identifiable {
    case history = "History"
    case cookies = "Cookies"
    case cache = "Cache"
    case localStorage = "Local Storage"
    case sessionData = "Session Data"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .history: return "clock.arrow.circlepath"
        case .cookies: return "birthday.cake"
        case .cache: return "internaldrive"
        case .localStorage: return "externaldrive"
        case .sessionData: return "rectangle.stack"
        }
    }

    var description: String {
        switch self {
        case .history: return "Browsing history and visited URLs"
        case .cookies: return "Website cookies and login data"
        case .cache: return "Cached images, scripts, and web content"
        case .localStorage: return "Website local storage data"
        case .sessionData: return "Open tabs and session information"
        }
    }

    var warningLevel: WarningLevel {
        switch self {
        case .history, .cache, .localStorage:
            return .low
        case .sessionData:
            return .medium
        case .cookies:
            return .high
        }
    }

    enum WarningLevel {
        case low, medium, high

        var message: String? {
            switch self {
            case .low: return nil
            case .medium: return "May log you out of some websites"
            case .high: return "Will log you out of all websites"
            }
        }
    }
}

// MARK: - Browser Data Item

struct BrowserDataItem: Identifiable {
    let id = UUID()
    let browser: BrowserType
    let dataType: BrowserDataType
    let path: URL
    let size: Int64
    var isSelected: Bool = false

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Browser Cleaner Service

actor BrowserCleanerService {
    static let shared = BrowserCleanerService()

    private init() {}

    // MARK: - Scanning

    /// Scan all browsers for cleanable data
    func scanAllBrowsers() async -> [BrowserDataItem] {
        var items: [BrowserDataItem] = []

        for browser in BrowserType.allCases where browser.isInstalled {
            let browserItems = await scanBrowser(browser)
            items.append(contentsOf: browserItems)
        }

        return items
    }

    /// Scan a specific browser
    func scanBrowser(_ browser: BrowserType) async -> [BrowserDataItem] {
        var items: [BrowserDataItem] = []
        let home = NSHomeDirectory()

        switch browser {
        case .safari:
            items.append(contentsOf: await scanSafari(home: home))
        case .chrome:
            items.append(contentsOf: await scanChrome(home: home))
        case .firefox:
            items.append(contentsOf: await scanFirefox(home: home))
        }

        return items
    }

    // MARK: - Safari

    private func scanSafari(home: String) async -> [BrowserDataItem] {
        var items: [BrowserDataItem] = []

        // History
        let historyPath = "\(home)/Library/Safari/History.db"
        if let size = getFileSize(at: historyPath), size > 0 {
            items.append(BrowserDataItem(
                browser: .safari,
                dataType: .history,
                path: URL(fileURLWithPath: historyPath),
                size: size
            ))
        }

        // Cookies
        let cookiesPath = "\(home)/Library/Cookies/Cookies.binarycookies"
        if let size = getFileSize(at: cookiesPath), size > 0 {
            items.append(BrowserDataItem(
                browser: .safari,
                dataType: .cookies,
                path: URL(fileURLWithPath: cookiesPath),
                size: size
            ))
        }

        // Cache
        let cachePath = "\(home)/Library/Caches/com.apple.Safari"
        if let size = getDirectorySize(at: cachePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .safari,
                dataType: .cache,
                path: URL(fileURLWithPath: cachePath),
                size: size
            ))
        }

        // Local Storage
        let localStoragePath = "\(home)/Library/Safari/LocalStorage"
        if let size = getDirectorySize(at: localStoragePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .safari,
                dataType: .localStorage,
                path: URL(fileURLWithPath: localStoragePath),
                size: size
            ))
        }

        return items
    }

    // MARK: - Chrome

    private func scanChrome(home: String) async -> [BrowserDataItem] {
        var items: [BrowserDataItem] = []
        let chromePath = "\(home)/Library/Application Support/Google/Chrome/Default"

        // History
        let historyPath = "\(chromePath)/History"
        if let size = getFileSize(at: historyPath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .history,
                path: URL(fileURLWithPath: historyPath),
                size: size
            ))
        }

        // Cookies
        let cookiesPath = "\(chromePath)/Cookies"
        if let size = getFileSize(at: cookiesPath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .cookies,
                path: URL(fileURLWithPath: cookiesPath),
                size: size
            ))
        }

        // Cache
        let cachePath = "\(chromePath)/Cache"
        if let size = getDirectorySize(at: cachePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .cache,
                path: URL(fileURLWithPath: cachePath),
                size: size
            ))
        }

        // Also check the Library/Caches location
        let libraryCachePath = "\(home)/Library/Caches/Google/Chrome"
        if let size = getDirectorySize(at: libraryCachePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .cache,
                path: URL(fileURLWithPath: libraryCachePath),
                size: size
            ))
        }

        // Local Storage
        let localStoragePath = "\(chromePath)/Local Storage"
        if let size = getDirectorySize(at: localStoragePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .localStorage,
                path: URL(fileURLWithPath: localStoragePath),
                size: size
            ))
        }

        // Session Storage
        let sessionPath = "\(chromePath)/Session Storage"
        if let size = getDirectorySize(at: sessionPath), size > 0 {
            items.append(BrowserDataItem(
                browser: .chrome,
                dataType: .sessionData,
                path: URL(fileURLWithPath: sessionPath),
                size: size
            ))
        }

        return items
    }

    // MARK: - Firefox

    private func scanFirefox(home: String) async -> [BrowserDataItem] {
        var items: [BrowserDataItem] = []
        let profilesPath = "\(home)/Library/Application Support/Firefox/Profiles"

        // Find Firefox profiles
        guard let profiles = try? FileManager.default.contentsOfDirectory(atPath: profilesPath) else {
            return items
        }

        for profile in profiles {
            let profilePath = "\(profilesPath)/\(profile)"

            // Only process directories that look like profiles
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: profilePath, isDirectory: &isDir), isDir.boolValue else {
                continue
            }

            // History (places.sqlite)
            let historyPath = "\(profilePath)/places.sqlite"
            if let size = getFileSize(at: historyPath), size > 0 {
                items.append(BrowserDataItem(
                    browser: .firefox,
                    dataType: .history,
                    path: URL(fileURLWithPath: historyPath),
                    size: size
                ))
            }

            // Cookies
            let cookiesPath = "\(profilePath)/cookies.sqlite"
            if let size = getFileSize(at: cookiesPath), size > 0 {
                items.append(BrowserDataItem(
                    browser: .firefox,
                    dataType: .cookies,
                    path: URL(fileURLWithPath: cookiesPath),
                    size: size
                ))
            }

            // Cache
            let cachePath = "\(profilePath)/cache2"
            if let size = getDirectorySize(at: cachePath), size > 0 {
                items.append(BrowserDataItem(
                    browser: .firefox,
                    dataType: .cache,
                    path: URL(fileURLWithPath: cachePath),
                    size: size
                ))
            }

            // Local Storage
            let localStoragePath = "\(profilePath)/webappsstore.sqlite"
            if let size = getFileSize(at: localStoragePath), size > 0 {
                items.append(BrowserDataItem(
                    browser: .firefox,
                    dataType: .localStorage,
                    path: URL(fileURLWithPath: localStoragePath),
                    size: size
                ))
            }

            // Session data
            let sessionPath = "\(profilePath)/sessionstore.jsonlz4"
            if let size = getFileSize(at: sessionPath), size > 0 {
                items.append(BrowserDataItem(
                    browser: .firefox,
                    dataType: .sessionData,
                    path: URL(fileURLWithPath: sessionPath),
                    size: size
                ))
            }
        }

        // Firefox cache in Library/Caches
        let libraryCachePath = "\(home)/Library/Caches/Firefox"
        if let size = getDirectorySize(at: libraryCachePath), size > 0 {
            items.append(BrowserDataItem(
                browser: .firefox,
                dataType: .cache,
                path: URL(fileURLWithPath: libraryCachePath),
                size: size
            ))
        }

        return items
    }

    // MARK: - Cleaning

    /// Clean selected browser data items
    func cleanItems(_ items: [BrowserDataItem]) async -> (cleaned: Int, freedSpace: Int64, errors: [Error]) {
        var cleaned = 0
        var freedSpace: Int64 = 0
        var errors: [Error] = []

        for item in items where item.isSelected {
            do {
                // For databases that might be locked, we need special handling
                if item.dataType == .history || item.dataType == .cookies {
                    // Try to remove the file
                    try FileManager.default.removeItem(at: item.path)
                } else if item.path.hasDirectoryPath || FileManager.default.fileExists(atPath: item.path.path) {
                    // For directories, remove contents
                    if let isDir = try? item.path.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDir {
                        let contents = try FileManager.default.contentsOfDirectory(at: item.path, includingPropertiesForKeys: nil)
                        for content in contents {
                            try FileManager.default.removeItem(at: content)
                        }
                    } else {
                        try FileManager.default.removeItem(at: item.path)
                    }
                }

                cleaned += 1
                freedSpace += item.size
            } catch {
                errors.append(error)
            }
        }

        return (cleaned, freedSpace, errors)
    }

    // MARK: - Helpers

    private func getFileSize(at path: String) -> Int64? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path) else { return nil }
        return attrs[.size] as? Int64
    }

    private func getDirectorySize(at path: String) -> Int64? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        let url = URL(fileURLWithPath: path)
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        var totalSize: Int64 = 0
        while let fileURL = enumerator.nextObject() as? URL {
            if let size = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize {
                totalSize += Int64(size)
            }
        }

        return totalSize > 0 ? totalSize : nil
    }

    // MARK: - Summary

    /// Get summary of browser data by type
    func getSummary(for items: [BrowserDataItem]) -> [BrowserDataType: Int64] {
        var summary: [BrowserDataType: Int64] = [:]

        for item in items {
            summary[item.dataType, default: 0] += item.size
        }

        return summary
    }

    /// Get summary of browser data by browser
    func getBrowserSummary(for items: [BrowserDataItem]) -> [BrowserType: Int64] {
        var summary: [BrowserType: Int64] = [:]

        for item in items {
            summary[item.browser, default: 0] += item.size
        }

        return summary
    }
}
