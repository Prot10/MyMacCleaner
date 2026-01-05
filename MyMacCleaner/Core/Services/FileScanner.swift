import Foundation

// MARK: - File Scanner Errors

enum FileScannerError: LocalizedError {
    case pathNotAllowed(URL)
    case deletionFailed(URL, Error)
    case trashFailed(URL, Error)
    case emptyTrashFailed(Error)

    var errorDescription: String? {
        switch self {
        case .pathNotAllowed(let url):
            return "Path is not in an allowed directory for deletion: \(url.path)"
        case .deletionFailed(let url, let error):
            return "Failed to delete \(url.lastPathComponent): \(error.localizedDescription)"
        case .trashFailed(let url, let error):
            return "Failed to move \(url.lastPathComponent) to trash: \(error.localizedDescription)"
        case .emptyTrashFailed(let error):
            return "Failed to empty trash: \(error.localizedDescription)"
        }
    }
}

// MARK: - File Scanner

actor FileScanner {
    static let shared = FileScanner()

    /// Allowed base paths for file deletion operations
    /// Files outside these directories will be rejected for safety
    private let allowedDeletionPaths: [String]

    private init() {
        let home = NSHomeDirectory()

        // Only allow deletion from known safe directories
        self.allowedDeletionPaths = [
            // User caches and logs
            "\(home)/Library/Caches",
            "\(home)/Library/Logs",

            // Developer data
            "\(home)/Library/Developer/Xcode/DerivedData",
            "\(home)/Library/Developer/Xcode/Archives",
            "\(home)/Library/Developer/CoreSimulator/Caches",

            // Application support cleanup (be careful)
            "\(home)/Library/Application Support",

            // User trash
            "\(home)/.Trash",

            // Downloads (user-controlled)
            "\(home)/Downloads",

            // System caches (requires FDA)
            "/Library/Caches",
            "/Library/Logs",

            // Mail attachments
            "\(home)/Library/Containers/com.apple.mail/Data/Library/Mail Downloads",

            // Browser caches
            "\(home)/Library/Caches/com.apple.Safari",
            "\(home)/Library/Caches/Google",
            "\(home)/Library/Caches/Firefox"
        ]
    }

    // MARK: - Path Validation

    /// Validates that a path is within an allowed directory for deletion
    /// Returns true if the path is safe to delete, false otherwise
    private func isPathAllowedForDeletion(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path

        // Never allow deletion of the home directory itself
        if path == NSHomeDirectory() {
            return false
        }

        // Never allow deletion of root directories
        let forbiddenPaths = [
            "/",
            "/System",
            "/Library",
            "/Applications",
            "/Users",
            "/usr",
            "/bin",
            "/sbin",
            "/var",
            "/private",
            NSHomeDirectory() + "/Library",
            NSHomeDirectory() + "/Documents",
            NSHomeDirectory() + "/Desktop",
            NSHomeDirectory() + "/Pictures",
            NSHomeDirectory() + "/Music",
            NSHomeDirectory() + "/Movies"
        ]

        for forbidden in forbiddenPaths {
            if path == forbidden {
                return false
            }
        }

        // Check if the path is within an allowed directory
        for allowedPath in allowedDeletionPaths {
            if path.hasPrefix(allowedPath + "/") || path == allowedPath {
                return true
            }
        }

        return false
    }

    /// Validates multiple items and returns those that are safe to delete
    private func validateItemsForDeletion(_ items: [CleanableItem]) -> (valid: [CleanableItem], invalid: [CleanableItem]) {
        var valid: [CleanableItem] = []
        var invalid: [CleanableItem] = []

        for item in items where item.isSelected {
            if isPathAllowedForDeletion(item.path) {
                valid.append(item)
            } else {
                invalid.append(item)
            }
        }

        return (valid, invalid)
    }

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

    /// Deletion result containing success info and any errors encountered
    struct DeletionResult {
        let freedSpace: Int64
        let deletedCount: Int
        let failedCount: Int
        let errors: [FileScannerError]
    }

    /// Delete selected items with path validation
    /// - Parameter items: Items to delete (only selected items will be processed)
    /// - Returns: Result with freed space and any errors
    func deleteItems(_ items: [CleanableItem]) async -> DeletionResult {
        let (validItems, invalidItems) = validateItemsForDeletion(items)

        var freedSpace: Int64 = 0
        var deletedCount = 0
        var errors: [FileScannerError] = []

        // Log invalid items
        for item in invalidItems {
            errors.append(.pathNotAllowed(item.path))
        }

        // Delete valid items
        for item in validItems {
            do {
                try FileManager.default.removeItem(at: item.path)
                freedSpace += item.size
                deletedCount += 1
            } catch {
                errors.append(.deletionFailed(item.path, error))
            }
        }

        return DeletionResult(
            freedSpace: freedSpace,
            deletedCount: deletedCount,
            failedCount: invalidItems.count + (validItems.count - deletedCount),
            errors: errors
        )
    }

    /// Move items to trash instead of permanent deletion (with path validation)
    /// - Parameter items: Items to trash (only selected items will be processed)
    /// - Returns: Result with freed space and any errors
    func trashItems(_ items: [CleanableItem]) async -> DeletionResult {
        let (validItems, invalidItems) = validateItemsForDeletion(items)

        var freedSpace: Int64 = 0
        var deletedCount = 0
        var errors: [FileScannerError] = []

        // Log invalid items
        for item in invalidItems {
            errors.append(.pathNotAllowed(item.path))
        }

        // Trash valid items
        for item in validItems {
            do {
                var trashedURL: NSURL?
                try FileManager.default.trashItem(at: item.path, resultingItemURL: &trashedURL)
                freedSpace += item.size
                deletedCount += 1
            } catch {
                errors.append(.trashFailed(item.path, error))
            }
        }

        return DeletionResult(
            freedSpace: freedSpace,
            deletedCount: deletedCount,
            failedCount: invalidItems.count + (validItems.count - deletedCount),
            errors: errors
        )
    }
}

// MARK: - Trash Size

extension FileScanner {
    /// Get current trash size
    func getTrashSize() async -> Int64 {
        let trashURL = URL(fileURLWithPath: NSHomeDirectory() + "/.Trash")
        return (try? await getDirectorySize(trashURL)) ?? 0
    }

    /// Empty the trash safely
    /// Only empties the current user's trash directory
    func emptyTrash() async -> DeletionResult {
        let trashPath = NSHomeDirectory() + "/.Trash"
        let trashURL = URL(fileURLWithPath: trashPath)

        // Validate that we're actually dealing with the user's trash
        guard trashURL.standardizedFileURL.path == trashPath else {
            return DeletionResult(
                freedSpace: 0,
                deletedCount: 0,
                failedCount: 1,
                errors: [.pathNotAllowed(trashURL)]
            )
        }

        var freedSpace: Int64 = 0
        var deletedCount = 0
        var errors: [FileScannerError] = []

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: [.totalFileAllocatedSizeKey]
            )

            for item in contents {
                do {
                    // Get size before deletion
                    if let size = try? item.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize {
                        freedSpace += Int64(size)
                    }

                    try FileManager.default.removeItem(at: item)
                    deletedCount += 1
                } catch {
                    errors.append(.deletionFailed(item, error))
                }
            }
        } catch {
            errors.append(.emptyTrashFailed(error))
        }

        return DeletionResult(
            freedSpace: freedSpace,
            deletedCount: deletedCount,
            failedCount: errors.count,
            errors: errors
        )
    }
}
