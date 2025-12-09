import Foundation

/// Defines paths and patterns for cleanup operations
/// Based on mac-cleanup-py and common cleanup utilities
public enum CleanupPaths {

    // MARK: - System Caches

    public static let systemCaches: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/Library/Caches/*",
            category: .userCaches,
            description: "User application caches",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/Library/Caches/*",
            category: .systemCaches,
            description: "System-wide caches",
            requiresRoot: true,
            safeToClean: true
        ),
    ]

    // MARK: - Logs

    public static let logs: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/Library/Logs/*",
            category: .logs,
            description: "User application logs",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/Library/Logs/*",
            category: .logs,
            description: "System logs",
            requiresRoot: true,
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/private/var/log/*",
            category: .logs,
            description: "System log files",
            requiresRoot: true,
            safeToClean: false // Some system logs are important
        ),
    ]

    // MARK: - Xcode

    public static let xcode: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/Library/Developer/Xcode/DerivedData/*",
            category: .xcodeDerivedData,
            description: "Xcode build artifacts and indexes",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "~/Library/Developer/Xcode/Archives/*",
            category: .xcodeArchives,
            description: "Xcode app archives",
            safeToClean: false // User may want to keep these
        ),
        CleanupPathDefinition(
            pattern: "~/Library/Developer/Xcode/iOS DeviceSupport/*",
            category: .xcodeDeviceSupport,
            description: "iOS device debug symbols",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "~/Library/Developer/CoreSimulator/Devices/*/data/Caches/*",
            category: .xcodeDerivedData,
            description: "Simulator caches",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "~/Library/Developer/CoreSimulator/Caches/*",
            category: .xcodeDerivedData,
            description: "CoreSimulator caches",
            safeToClean: true
        ),
    ]

    // MARK: - Package Managers

    public static let homebrew: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/Library/Caches/Homebrew/*",
            category: .homebrew,
            description: "Homebrew downloaded packages",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/opt/homebrew/Caskroom/*/.metadata",
            category: .homebrew,
            description: "Homebrew Cask metadata",
            requiresRoot: false,
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/usr/local/Caskroom/*/.metadata",
            category: .homebrew,
            description: "Homebrew Cask metadata (Intel)",
            requiresRoot: false,
            safeToClean: true
        ),
    ]

    public static let npm: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/.npm/_cacache/*",
            category: .npm,
            description: "npm package cache",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "~/.npm/_logs/*",
            category: .npm,
            description: "npm log files",
            safeToClean: true
        ),
    ]

    public static let pip: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/Library/Caches/pip/*",
            category: .pip,
            description: "Python pip cache",
            safeToClean: true
        ),
    ]

    // MARK: - Other Caches

    public static let otherCaches: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/.cache/*",
            category: .userCaches,
            description: "XDG cache directory",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "~/Library/Containers/*/Data/Library/Caches/*",
            category: .userCaches,
            description: "Sandboxed app caches",
            safeToClean: true
        ),
    ]

    // MARK: - Trash

    public static let trash: [CleanupPathDefinition] = [
        CleanupPathDefinition(
            pattern: "~/.Trash/*",
            category: .trash,
            description: "User Trash",
            safeToClean: true
        ),
        CleanupPathDefinition(
            pattern: "/Volumes/*/.Trashes/*",
            category: .trash,
            description: "External drive trash",
            requiresRoot: true,
            safeToClean: true
        ),
    ]

    // MARK: - All Paths

    public static var all: [CleanupPathDefinition] {
        systemCaches + logs + xcode + homebrew + npm + pip + otherCaches + trash
    }

    public static var safeToClean: [CleanupPathDefinition] {
        all.filter(\.safeToClean)
    }

    public static func paths(for category: CleanupCategory) -> [CleanupPathDefinition] {
        all.filter { $0.category == category }
    }
}

// MARK: - Path Definition

public struct CleanupPathDefinition: Sendable {
    public let pattern: String
    public let category: CleanupCategory
    public let description: String
    public let requiresRoot: Bool
    public let safeToClean: Bool

    public init(
        pattern: String,
        category: CleanupCategory,
        description: String,
        requiresRoot: Bool = false,
        safeToClean: Bool = true
    ) {
        self.pattern = pattern
        self.category = category
        self.description = description
        self.requiresRoot = requiresRoot
        self.safeToClean = safeToClean
    }

    /// Expands the pattern to actual file paths
    public func expandedPaths() -> [String] {
        let expandedPattern: String
        if pattern.hasPrefix("~") {
            expandedPattern = (pattern as NSString).expandingTildeInPath
        } else {
            expandedPattern = pattern
        }

        // Handle glob patterns
        if expandedPattern.contains("*") {
            return expandGlob(expandedPattern)
        } else {
            return FileManager.default.fileExists(atPath: expandedPattern) ? [expandedPattern] : []
        }
    }

    private func expandGlob(_ pattern: String) -> [String] {
        var results: [String] = []

        // Split pattern into base path and remaining pattern
        let components = pattern.components(separatedBy: "*")
        guard let basePath = components.first else { return [] }

        let fm = FileManager.default
        let cleanBasePath = basePath.hasSuffix("/") ? String(basePath.dropLast()) : basePath

        guard fm.fileExists(atPath: cleanBasePath) else { return [] }

        do {
            let contents = try fm.contentsOfDirectory(atPath: cleanBasePath)
            for item in contents {
                let fullPath = (cleanBasePath as NSString).appendingPathComponent(item)
                results.append(fullPath)
            }
        } catch {
            // Directory doesn't exist or can't be read
        }

        return results
    }
}

// MARK: - Leftover Search Paths

/// Paths to search for application leftovers
public enum LeftoverSearchPaths {

    public static func userLibraryPaths() -> [(path: String, category: LeftoverCategory)] {
        let home = NSHomeDirectory()
        return [
            ("\(home)/Library/Application Support", .applicationSupport),
            ("\(home)/Library/Preferences", .preferences),
            ("\(home)/Library/Caches", .cache),
            ("\(home)/Library/Containers", .container),
            ("\(home)/Library/Logs", .logs),
            ("\(home)/Library/Saved Application State", .savedState),
            ("\(home)/Library/Cookies", .cookies),
            ("\(home)/Library/WebKit", .webkit),
            ("\(home)/Library/HTTPStorages", .cache),
            ("\(home)/Library/Group Containers", .container),
            ("\(home)/Library/Application Scripts", .other),
        ]
    }

    public static func systemLibraryPaths() -> [(path: String, category: LeftoverCategory)] {
        return [
            ("/Library/Application Support", .applicationSupport),
            ("/Library/Preferences", .preferences),
            ("/Library/Caches", .cache),
            ("/Library/LaunchAgents", .launchItem),
            ("/Library/LaunchDaemons", .launchItem),
            ("/Library/PrivilegedHelperTools", .other),
            ("/Library/Logs/DiagnosticReports", .crashReports),
        ]
    }

    public static var allPaths: [(path: String, category: LeftoverCategory)] {
        userLibraryPaths() + systemLibraryPaths()
    }
}
