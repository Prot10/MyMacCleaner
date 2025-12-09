import Foundation
import SwiftUI

@Observable
final class UninstallerViewModel {
    var apps: [AppInfo] = []
    var selectedApp: AppInfo?
    var leftovers: [LeftoverInfo] = []
    var searchText = ""
    var isLoading = false
    var isScanningLeftovers = false

    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return apps
        }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleId.localizedCaseInsensitiveContains(searchText)
        }
    }

    /// Load apps from preloaded data if available
    @MainActor
    func loadData(from preloadedData: UninstallerData?) {
        if let data = preloadedData {
            apps = data.apps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }

    @MainActor
    func loadInstalledApps() async {
        isLoading = true

        // Scan /Applications for .app bundles
        let fm = FileManager.default
        let applicationsPath = "/Applications"

        var loadedApps: [AppInfo] = []

        do {
            let contents = try fm.contentsOfDirectory(atPath: applicationsPath)
            for item in contents where item.hasSuffix(".app") {
                let appPath = (applicationsPath as NSString).appendingPathComponent(item)
                let infoPlistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")

                if let plist = NSDictionary(contentsOfFile: infoPlistPath),
                   let bundleId = plist["CFBundleIdentifier"] as? String {
                    let name = (item as NSString).deletingPathExtension
                    let size = try? getDirectorySize(at: appPath)

                    loadedApps.append(AppInfo(
                        name: name,
                        bundleId: bundleId,
                        path: appPath,
                        sizeBytes: size ?? 0
                    ))
                }
            }
        } catch {
            // Handle error silently
        }

        apps = loadedApps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        isLoading = false
    }

    @MainActor
    func scanLeftovers(for app: AppInfo) async {
        isScanningLeftovers = true
        leftovers = []

        // Search for leftover files
        let home = NSHomeDirectory()
        let searchPaths: [(path: String, category: String, icon: String)] = [
            ("\(home)/Library/Application Support", "App Support", "folder"),
            ("\(home)/Library/Preferences", "Preferences", "gearshape"),
            ("\(home)/Library/Caches", "Caches", "folder.badge.gearshape"),
            ("\(home)/Library/Containers", "Containers", "shippingbox"),
            ("\(home)/Library/Logs", "Logs", "doc.text"),
            ("\(home)/Library/Saved Application State", "Saved State", "bookmark"),
        ]

        let fm = FileManager.default

        for searchPath in searchPaths {
            guard fm.fileExists(atPath: searchPath.path) else { continue }

            do {
                let contents = try fm.contentsOfDirectory(atPath: searchPath.path)
                for item in contents {
                    // Match by bundle ID or app name
                    if item.localizedCaseInsensitiveContains(app.bundleId) ||
                       item.localizedCaseInsensitiveContains(app.name) {
                        let fullPath = (searchPath.path as NSString).appendingPathComponent(item)
                        let size = (try? getDirectorySize(at: fullPath)) ?? 0

                        // Determine confidence based on match type
                        let confidence: LeftoverConfidence = item.localizedCaseInsensitiveContains(app.bundleId) ? .high : .medium

                        leftovers.append(LeftoverInfo(
                            name: item,
                            path: fullPath,
                            category: searchPath.category,
                            icon: searchPath.icon,
                            sizeBytes: size,
                            confidence: confidence
                        ))
                    }
                }
            } catch {
                // Skip inaccessible directories
            }

            // Small delay to show progress
            try? await Task.sleep(for: .milliseconds(100))
        }

        isScanningLeftovers = false
    }

    @MainActor
    func uninstallSelectedApp() async {
        guard let app = selectedApp else { return }

        var uninstallErrors: [String] = []

        // 1. Move leftover files to Trash first
        for leftover in leftovers {
            do {
                try moveToTrash(path: leftover.path)
            } catch {
                uninstallErrors.append("Failed to remove: \(leftover.name)")
            }
        }

        // 2. Move the app bundle to Trash
        do {
            try moveToTrash(path: app.path)
        } catch {
            uninstallErrors.append("Failed to move app to Trash: \(app.name)")
        }

        // 3. Update UI
        if uninstallErrors.isEmpty {
            apps.removeAll { $0.id == app.id }
            selectedApp = nil
            leftovers = []
        } else {
            // Rescan leftovers to see what's remaining
            await scanLeftovers(for: app)
        }
    }

    private func moveToTrash(path: String) throws {
        let fileURL = URL(fileURLWithPath: path)
        var resultingURL: NSURL?
        try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultingURL)
    }

    private func getDirectorySize(at path: String) throws -> Int64 {
        let fm = FileManager.default
        var totalSize: Int64 = 0

        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }

        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: filePath),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }
}

// MARK: - Types

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleId: String
    let path: String
    let sizeBytes: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    /// Get the app icon from the file system
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleId)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.bundleId == rhs.bundleId
    }
}

struct LeftoverInfo: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let category: String
    let icon: String
    let sizeBytes: Int64
    let confidence: LeftoverConfidence

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    var confidenceColor: Color {
        switch confidence {
        case .high: return Color.cleanGreen
        case .medium: return Color.cleanOrange
        case .low: return Color.cleanRed
        }
    }
}
