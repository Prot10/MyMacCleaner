import Foundation
import SwiftUI

@Observable
final class CleanerViewModel {
    var categories: [CleanerCategory] = []
    var isScanning = false
    var isCleaning = false
    var cleaningError: String?

    var totalSelectedSize: Int64 {
        categories.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    /// Initialize with preloaded data if available
    @MainActor
    func loadData(from preloadedData: CleanerData?) {
        if let data = preloadedData {
            // Convert preloaded CleanerCategoryData to CleanerCategory
            categories = data.categories.map { categoryData in
                CleanerCategory(
                    name: categoryData.name,
                    icon: categoryData.icon,
                    color: colorForCategory(categoryData.name),
                    sizeBytes: categoryData.sizeBytes,
                    itemCount: categoryData.itemCount,
                    paths: categoryData.paths
                )
            }
        }
    }

    private func colorForCategory(_ name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("cache"): return .cleanBlue
        case let n where n.contains("log"): return .cleanOrange
        case let n where n.contains("xcode"): return .cleanPurple
        case let n where n.contains("homebrew"): return .brown
        case let n where n.contains("npm"): return .cleanRed
        case let n where n.contains("pip"): return .yellow
        case let n where n.contains("trash"): return .gray
        default: return .gray
        }
    }

    @MainActor
    func scan() async {
        isScanning = true
        categories = []
        cleaningError = nil

        // Define cleanup categories with their paths
        let categoryDefinitions: [(name: String, icon: String, color: Color, paths: [CleanupPathDefinition])] = [
            ("User Caches", "folder.fill", .cleanBlue, CleanupPaths.systemCaches.filter { !$0.requiresRoot }),
            ("Application Logs", "doc.text.fill", .cleanOrange, CleanupPaths.logs.filter { !$0.requiresRoot }),
            ("Xcode Derived Data", "hammer.fill", .cleanPurple, CleanupPaths.xcode),
            ("Homebrew Cache", "cup.and.saucer.fill", .brown, CleanupPaths.homebrew),
            ("npm Cache", "shippingbox.fill", .cleanRed, CleanupPaths.npm),
            ("pip Cache", "cube.fill", .yellow, CleanupPaths.pip),
            ("Trash", "trash.fill", .gray, CleanupPaths.trash.filter { !$0.requiresRoot }),
        ]

        for (name, icon, color, pathDefs) in categoryDefinitions {
            var totalSize: Int64 = 0
            var itemCount = 0
            var allPaths: [String] = []

            for pathDef in pathDefs {
                let expandedPaths = pathDef.expandedPaths()
                for path in expandedPaths {
                    if let size = try? calculateSize(at: path) {
                        totalSize += size
                        itemCount += 1
                        allPaths.append(path)
                    }
                }
            }

            // Only add category if it has content
            if totalSize > 0 {
                categories.append(CleanerCategory(
                    name: name,
                    icon: icon,
                    color: color,
                    sizeBytes: totalSize,
                    itemCount: itemCount,
                    paths: allPaths
                ))
            }

            // Small delay to show progress
            try? await Task.sleep(for: .milliseconds(100))
        }

        // Sort by size descending
        categories.sort { $0.sizeBytes > $1.sizeBytes }

        isScanning = false
    }

    @MainActor
    func clean() async {
        isCleaning = true
        cleaningError = nil

        let selectedCategories = categories.filter(\.isSelected)
        var failedPaths: [String] = []

        for category in selectedCategories {
            for path in category.paths {
                do {
                    // Move to Trash instead of permanent delete for safety
                    try await moveToTrash(path: path)
                } catch {
                    failedPaths.append(path)
                }
            }
        }

        if !failedPaths.isEmpty {
            cleaningError = "Some files could not be deleted. You may need Full Disk Access."
        }

        // Remove successfully cleaned categories
        categories.removeAll { $0.isSelected && !failedPaths.contains(where: { $0.hasPrefix($0) }) }

        // Rescan to update sizes
        await scan()

        isCleaning = false
    }

    // MARK: - Private Helpers

    private func calculateSize(at path: String) throws -> Int64 {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false

        guard fm.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return 0
        }

        if isDirectory.boolValue {
            var totalSize: Int64 = 0
            if let enumerator = fm.enumerator(atPath: path) {
                for case let file as String in enumerator {
                    let filePath = (path as NSString).appendingPathComponent(file)
                    if let attrs = try? fm.attributesOfItem(atPath: filePath),
                       let size = attrs[.size] as? Int64 {
                        totalSize += size
                    }
                }
            }
            return totalSize
        } else {
            if let attrs = try? fm.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                return size
            }
            return 0
        }
    }

    private func moveToTrash(path: String) async throws {
        let fileURL = URL(fileURLWithPath: path)
        var resultingURL: NSURL?

        try FileManager.default.trashItem(at: fileURL, resultingItemURL: &resultingURL)
    }
}

// MARK: - Types

struct CleanerCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let sizeBytes: Int64
    let itemCount: Int
    let paths: [String]
    var isSelected: Bool = true

    init(name: String, icon: String, color: Color, sizeBytes: Int64, itemCount: Int, paths: [String] = [], isSelected: Bool = true) {
        self.name = name
        self.icon = icon
        self.color = color
        self.sizeBytes = sizeBytes
        self.itemCount = itemCount
        self.paths = paths
        self.isSelected = isSelected
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}
