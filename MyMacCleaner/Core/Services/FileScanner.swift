import Foundation

// MARK: - File Scanner

actor FileScanner {
    static let shared = FileScanner()

    private init() {}

    // MARK: - Scanning

    /// Scan all categories for cleanable items
    func scanAllCategories(
        progress: @escaping (Double, ScanCategory) -> Void
    ) async throws -> [ScanResult] {
        var results: [ScanResult] = []
        let categories = ScanCategory.allCases

        for (index, category) in categories.enumerated() {
            let categoryProgress = Double(index) / Double(categories.count)
            await MainActor.run {
                progress(categoryProgress, category)
            }

            do {
                let items = try await scanCategory(category)
                if !items.isEmpty {
                    results.append(ScanResult(category: category, items: items))
                }
            } catch {
                // Skip categories that fail (e.g., permission denied)
                print("Failed to scan \(category.rawValue): \(error)")
            }
        }

        await MainActor.run {
            progress(1.0, categories.last!)
        }

        return results
    }

    /// Scan a specific category
    func scanCategory(_ category: ScanCategory) async throws -> [CleanableItem] {
        var items: [CleanableItem] = []

        for pathString in category.paths {
            let url = URL(fileURLWithPath: pathString)

            guard FileManager.default.fileExists(atPath: pathString) else {
                continue
            }

            do {
                let scannedItems = try await scanDirectory(url, category: category)
                items.append(contentsOf: scannedItems)
            } catch {
                // Continue with other paths
                print("Error scanning \(pathString): \(error)")
            }
        }

        return items
    }

    /// Scan a directory recursively
    private func scanDirectory(_ url: URL, category: ScanCategory, maxDepth: Int = 3) async throws -> [CleanableItem] {
        var items: [CleanableItem] = []

        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .totalFileAllocatedSizeKey,
            .isDirectoryKey,
            .contentModificationDateKey,
            .nameKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return items
        }

        for case let fileURL as URL in enumerator {
            // Check depth
            let depth = fileURL.pathComponents.count - url.pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            do {
                let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)

                // Skip directories for item list (but continue enumerating)
                if resourceValues.isDirectory == true {
                    continue
                }

                let size = Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)

                // Skip tiny files (less than 1KB)
                if size < 1024 {
                    continue
                }

                let item = CleanableItem(
                    name: resourceValues.name ?? fileURL.lastPathComponent,
                    path: fileURL,
                    size: size,
                    modificationDate: resourceValues.contentModificationDate,
                    category: category
                )

                items.append(item)
            } catch {
                // Skip files we can't read
                continue
            }
        }

        return items
    }

    // MARK: - Quick Scan

    /// Quick estimate of cleanable space without full enumeration
    func quickEstimate() async -> [ScanCategory: Int64] {
        var estimates: [ScanCategory: Int64] = [:]

        for category in ScanCategory.allCases {
            var totalSize: Int64 = 0

            for pathString in category.paths {
                let url = URL(fileURLWithPath: pathString)

                if let size = try? await getDirectorySize(url) {
                    totalSize += size
                }
            }

            if totalSize > 0 {
                estimates[category] = totalSize
            }
        }

        return estimates
    }

    /// Get total size of a directory (faster than full enumeration)
    private func getDirectorySize(_ url: URL) async throws -> Int64 {
        var totalSize: Int64 = 0

        let resourceKeys: Set<URLResourceKey> = [.totalFileAllocatedSizeKey, .isDirectoryKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                  resourceValues.isDirectory == false else {
                continue
            }

            totalSize += Int64(resourceValues.totalFileAllocatedSize ?? 0)
        }

        return totalSize
    }

    // MARK: - Deletion

    /// Delete selected items
    func deleteItems(_ items: [CleanableItem]) async throws -> Int64 {
        var freedSpace: Int64 = 0

        for item in items where item.isSelected {
            do {
                try FileManager.default.removeItem(at: item.path)
                freedSpace += item.size
            } catch {
                print("Failed to delete \(item.path): \(error)")
                throw error
            }
        }

        return freedSpace
    }

    /// Move items to trash instead of permanent deletion
    func trashItems(_ items: [CleanableItem]) async throws -> Int64 {
        var freedSpace: Int64 = 0

        for item in items where item.isSelected {
            do {
                var trashedURL: NSURL?
                try FileManager.default.trashItem(at: item.path, resultingItemURL: &trashedURL)
                freedSpace += item.size
            } catch {
                print("Failed to trash \(item.path): \(error)")
                throw error
            }
        }

        return freedSpace
    }
}

// MARK: - Trash Size

extension FileScanner {
    /// Get current trash size
    func getTrashSize() async -> Int64 {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory() + "/.Trash")
        return (try? await getDirectorySize(trashURL)) ?? 0
    }

    /// Empty the trash
    func emptyTrash() async throws {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory() + "/.Trash")

        let contents = try FileManager.default.contentsOfDirectory(
            at: trashURL,
            includingPropertiesForKeys: nil
        )

        for item in contents {
            try FileManager.default.removeItem(at: item)
        }
    }
}
