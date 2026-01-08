import Foundation
import AppKit

// MARK: - Orphaned File Model

struct OrphanedFile: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let suspectedAppName: String
    let bundleIdPattern: String?
    let size: Int64
    let modificationDate: Date?
    var isSelected: Bool = false

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let date = modificationDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var daysSinceModified: Int? {
        guard let date = modificationDate else { return nil }
        return Int(Date().timeIntervalSince(date) / (24 * 60 * 60))
    }

    var category: OrphanCategory {
        let path = url.path
        if path.contains("Application Support") { return .applicationSupport }
        if path.contains("Preferences") { return .preferences }
        if path.contains("Caches") { return .caches }
        if path.contains("Containers") { return .containers }
        if path.contains("Saved Application State") { return .savedState }
        if path.contains("LaunchAgents") { return .launchAgents }
        if path.contains("Logs") { return .logs }
        return .other
    }
}

enum OrphanCategory: String, CaseIterable {
    case applicationSupport = "Application Support"
    case preferences = "Preferences"
    case caches = "Caches"
    case containers = "Containers"
    case savedState = "Saved State"
    case launchAgents = "Launch Agents"
    case logs = "Logs"
    case other = "Other"

    var icon: String {
        switch self {
        case .applicationSupport: return "folder.fill"
        case .preferences: return "gearshape.fill"
        case .caches: return "archivebox.fill"
        case .containers: return "shippingbox.fill"
        case .savedState: return "doc.on.doc.fill"
        case .launchAgents: return "play.circle.fill"
        case .logs: return "doc.text.fill"
        case .other: return "questionmark.folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .applicationSupport: return .blue
        case .preferences: return .purple
        case .caches: return .orange
        case .containers: return .pink
        case .savedState: return .green
        case .launchAgents: return .red
        case .logs: return .gray
        case .other: return .secondary
        }
    }
}

import SwiftUI

// MARK: - Orphaned Files Scanner

actor OrphanedFilesScanner {
    static let shared = OrphanedFilesScanner()

    private init() {}

    // MARK: - Main Scan

    /// Scan for orphaned files from previously deleted applications
    func scan(progress: @escaping (Double, String) -> Void) async -> [OrphanedFile] {
        var orphanedFiles: [OrphanedFile] = []

        // Step 1: Get all installed app bundle IDs
        await MainActor.run { progress(0.05, "Getting installed apps...") }
        let installedBundleIds = await getInstalledAppBundleIds()
        let installedAppNames = await getInstalledAppNames()

        // Step 2: Scan Library folders
        let home = NSHomeDirectory()
        let libraryPaths: [(String, String)] = [
            ("\(home)/Library/Application Support", "Application Support"),
            ("\(home)/Library/Preferences", "Preferences"),
            ("\(home)/Library/Caches", "Caches"),
            ("\(home)/Library/Containers", "Containers"),
            ("\(home)/Library/Group Containers", "Group Containers"),
            ("\(home)/Library/Saved Application State", "Saved Application State"),
            ("\(home)/Library/LaunchAgents", "LaunchAgents"),
            ("\(home)/Library/Logs", "Logs"),
            ("\(home)/Library/HTTPStorages", "HTTPStorages"),
            ("\(home)/Library/WebKit", "WebKit"),
        ]

        let totalPaths = libraryPaths.count
        var processedPaths = 0

        for (path, category) in libraryPaths {
            processedPaths += 1
            let baseProgress = Double(processedPaths) / Double(totalPaths)
            await MainActor.run { progress(baseProgress * 0.9 + 0.05, "Scanning \(category)...") }

            let url = URL(fileURLWithPath: path)
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.contentModificationDateKey, .totalFileAllocatedSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents {
                // Extract potential bundle ID or app name from the item
                let itemName = itemURL.lastPathComponent
                let extractedBundleId = extractBundleId(from: itemName)
                let extractedAppName = extractAppName(from: itemName)

                // Check if this matches any installed app
                var isOrphan = true

                // Check against bundle IDs
                if let bundleId = extractedBundleId {
                    for installedId in installedBundleIds {
                        if bundleId.lowercased() == installedId.lowercased() ||
                           installedId.lowercased().contains(bundleId.lowercased()) ||
                           bundleId.lowercased().contains(installedId.lowercased()) {
                            isOrphan = false
                            break
                        }
                    }
                }

                // Check against app names
                if isOrphan, let appName = extractedAppName {
                    let normalizedAppName = appName.lowercased().replacingOccurrences(of: " ", with: "")
                    for installedName in installedAppNames {
                        let normalizedInstalledName = installedName.lowercased().replacingOccurrences(of: " ", with: "")
                        if normalizedAppName == normalizedInstalledName ||
                           normalizedAppName.contains(normalizedInstalledName) ||
                           normalizedInstalledName.contains(normalizedAppName) {
                            isOrphan = false
                            break
                        }
                    }
                }

                // Skip system items
                if isSystemItem(itemName) {
                    isOrphan = false
                }

                if isOrphan {
                    // Get file info
                    if let orphanFile = await createOrphanedFile(
                        url: itemURL,
                        suspectedAppName: extractedAppName ?? extractedBundleId ?? itemName,
                        bundleIdPattern: extractedBundleId
                    ) {
                        orphanedFiles.append(orphanFile)
                    }
                }
            }
        }

        await MainActor.run { progress(1.0, "Complete") }

        // Sort by size descending
        return orphanedFiles.sorted { $0.size > $1.size }
    }

    // MARK: - Delete

    /// Delete selected orphaned files
    func deleteFiles(_ files: [OrphanedFile]) async -> (deleted: Int, freedSpace: Int64, errors: [Error]) {
        var deleted = 0
        var freedSpace: Int64 = 0
        var errors: [Error] = []

        for file in files where file.isSelected {
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                deleted += 1
                freedSpace += file.size
            } catch {
                errors.append(error)
            }
        }

        return (deleted, freedSpace, errors)
    }

    // MARK: - Private Helpers

    private func getInstalledAppBundleIds() async -> Set<String> {
        var bundleIds = Set<String>()

        let applicationPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for appPath in applicationPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: appPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents where itemURL.pathExtension == "app" {
                if let bundle = Bundle(url: itemURL),
                   let bundleId = bundle.bundleIdentifier {
                    bundleIds.insert(bundleId)
                }
            }
        }

        return bundleIds
    }

    private func getInstalledAppNames() async -> Set<String> {
        var appNames = Set<String>()

        let applicationPaths = [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for appPath in applicationPaths {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: appPath,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents where itemURL.pathExtension == "app" {
                let appName = itemURL.deletingPathExtension().lastPathComponent
                appNames.insert(appName)
            }
        }

        return appNames
    }

    private func extractBundleId(from name: String) -> String? {
        // Check if name looks like a bundle ID (e.g., com.company.app)
        let components = name.split(separator: ".")
        if components.count >= 2 {
            // Check for common bundle ID patterns
            let firstComponent = String(components[0]).lowercased()
            if ["com", "org", "net", "io", "co", "app", "me", "dev"].contains(firstComponent) {
                return name.replacingOccurrences(of: ".plist", with: "")
                    .replacingOccurrences(of: ".savedState", with: "")
            }
        }

        // Check for group container pattern
        if name.hasPrefix("group.") {
            return String(name.dropFirst(6))
        }

        return nil
    }

    private func extractAppName(from name: String) -> String? {
        // Remove common suffixes
        var cleanName = name
            .replacingOccurrences(of: ".plist", with: "")
            .replacingOccurrences(of: ".savedState", with: "")
            .replacingOccurrences(of: "com.", with: "")
            .replacingOccurrences(of: "org.", with: "")
            .replacingOccurrences(of: "net.", with: "")
            .replacingOccurrences(of: "io.", with: "")
            .replacingOccurrences(of: "group.", with: "")

        // If it still looks like a bundle ID, extract the last component
        if cleanName.contains(".") {
            let components = cleanName.split(separator: ".")
            if let last = components.last {
                cleanName = String(last)
            }
        }

        // Convert camelCase or PascalCase to readable name
        if !cleanName.isEmpty && cleanName.first?.isUppercase == true {
            return cleanName
        }

        return cleanName.isEmpty ? nil : cleanName.capitalized
    }

    private func isSystemItem(_ name: String) -> Bool {
        // List of known system/Apple items to exclude
        let systemPatterns = [
            "apple", "macos", "finder", "safari", "mail.app", "calendar", "contacts",
            "photos", "music", "tv", "news", "stocks", "home", "notes", "reminders",
            "books", "preview", "textedit", "quicktime", "automator", "terminal",
            "console", "activity monitor", "disk utility", "migration assistant",
            "system preferences", "system settings", "font book", "colorsyns",
            "digital color meter", "grapher", "keychain access", "screenshot",
            "voice memos", "bootcamp", "bluetooth", "audio midi setup",
            "launchservices", "com.apple", "loginitems", "startup", "backgrounditems",
            "cloudd", "appstore", "itunes", "xcode", "instruments", "simulator"
        ]

        let lowercaseName = name.lowercased()
        return systemPatterns.contains { lowercaseName.contains($0) }
    }

    private func createOrphanedFile(url: URL, suspectedAppName: String, bundleIdPattern: String?) async -> OrphanedFile? {
        let resourceValues = try? url.resourceValues(forKeys: [
            .contentModificationDateKey,
            .totalFileAllocatedSizeKey,
            .isDirectoryKey
        ])

        let modDate = resourceValues?.contentModificationDate
        var size: Int64 = 0

        // Only include files older than 30 days
        if let modDate = modDate {
            let daysSinceModified = Int(Date().timeIntervalSince(modDate) / (24 * 60 * 60))
            if daysSinceModified < 30 {
                return nil
            }
        }

        // Calculate size
        if resourceValues?.isDirectory == true {
            size = await calculateDirectorySize(url)
        } else {
            size = Int64(resourceValues?.totalFileAllocatedSize ?? 0)
        }

        // Skip tiny items (less than 10KB)
        if size < 10 * 1024 {
            return nil
        }

        return OrphanedFile(
            url: url,
            name: url.lastPathComponent,
            suspectedAppName: suspectedAppName,
            bundleIdPattern: bundleIdPattern,
            size: size,
            modificationDate: modDate
        )
    }

    private func calculateDirectorySize(_ url: URL) async -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var totalSize: Int64 = 0

        while let fileURL = enumerator.nextObject() as? URL {
            if let size = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }
}
