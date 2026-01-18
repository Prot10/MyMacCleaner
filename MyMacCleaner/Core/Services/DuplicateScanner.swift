import Foundation
import CryptoKit
import SwiftUI

// MARK: - Duplicate Group Model

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    var files: [DuplicateFile]

    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    var wastedSize: Int64 {
        // Size that could be reclaimed (all but one copy)
        guard files.count > 1 else { return 0 }
        return Int64(files.count - 1) * (files.first?.size ?? 0)
    }

    var fileSize: Int64 {
        files.first?.size ?? 0
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedWastedSize: String {
        ByteCountFormatter.string(fromByteCount: wastedSize, countStyle: .file)
    }

    var fileType: FileType {
        guard let ext = files.first?.url.pathExtension.lowercased() else { return .other }
        return FileType.from(extension: ext)
    }
}

struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let modificationDate: Date?
    var isSelected: Bool = false
    var isKept: Bool = false  // The one to keep

    var name: String {
        url.lastPathComponent
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let date = modificationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var parentFolder: String {
        url.deletingLastPathComponent().lastPathComponent
    }

    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum FileType: String, CaseIterable {
    case image = "Images"
    case video = "Videos"
    case audio = "Audio"
    case document = "Documents"
    case archive = "Archives"
    case other = "Other"

    var icon: String {
        switch self {
        case .image: return "photo.fill"
        case .video: return "video.fill"
        case .audio: return "music.note"
        case .document: return "doc.fill"
        case .archive: return "archivebox.fill"
        case .other: return "doc.questionmark.fill"
        }
    }

    var color: Color {
        switch self {
        case .image: return .pink
        case .video: return .purple
        case .audio: return .orange
        case .document: return .blue
        case .archive: return .green
        case .other: return .gray
        }
    }

    static func from(extension ext: String) -> FileType {
        let imageExts = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "raw", "cr2", "nef"]
        let videoExts = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "mpeg", "mpg"]
        let audioExts = ["mp3", "wav", "aac", "flac", "m4a", "wma", "ogg", "aiff", "alac"]
        let docExts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers", "key"]
        let archiveExts = ["zip", "rar", "7z", "tar", "gz", "dmg", "iso"]

        if imageExts.contains(ext) { return .image }
        if videoExts.contains(ext) { return .video }
        if audioExts.contains(ext) { return .audio }
        if docExts.contains(ext) { return .document }
        if archiveExts.contains(ext) { return .archive }
        return .other
    }
}

// MARK: - Duplicate Scanner

actor DuplicateScanner {
    static let shared = DuplicateScanner()

    private var isCancelled = false

    // Files to skip during scanning
    private let skipFileNames: Set<String> = [
        ".DS_Store", ".localized", ".Spotlight-V100", ".Trashes",
        ".fseventsd", ".TemporaryItems", "Thumbs.db", "desktop.ini",
        ".git", ".svn", ".hg"
    ]

    // Extensions to skip (system/temp files)
    private let skipExtensions: Set<String> = [
        "tmp", "temp", "swp", "swo", "lock", "pid"
    ]

    private init() {}

    // MARK: - Cancellation

    func cancel() {
        isCancelled = true
    }

    private func resetCancellation() {
        isCancelled = false
    }

    // MARK: - Main Scan

    /// Scan for duplicate files at the given path
    /// - Parameters:
    ///   - path: Directory to scan
    ///   - minSize: Minimum file size to consider (default 1KB)
    ///   - progress: Progress callback (progress 0-1, status string)
    /// - Returns: Array of duplicate groups
    func scan(
        at path: URL,
        minSize: Int64 = 1024,
        progress: @escaping (Double, String) -> Void
    ) async -> [DuplicateGroup] {
        resetCancellation()
        var duplicateGroups: [DuplicateGroup] = []

        await MainActor.run { progress(0.05, L("duplicates.scan.enumerating")) }

        // Step 1: Enumerate all files and group by size
        var sizeGroups: [Int64: [URL]] = [:]
        var totalFiles = 0
        var lastProgressUpdate = Date()

        let resourceKeys: Set<URLResourceKey> = [
            .fileSizeKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .isReadableKey,
            .contentModificationDateKey
        ]

        guard let enumerator = FileManager.default.enumerator(
            at: path,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            await MainActor.run { progress(1.0, L("common.complete")) }
            return []
        }

        // Enumerate files with safety checks
        while let item = enumerator.nextObject() {
            // Check for cancellation
            if isCancelled {
                await MainActor.run { progress(1.0, L("duplicates.scan.cancelled")) }
                return []
            }

            guard let fileURL = item as? URL else { continue }

            // Get resource values safely
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys) else {
                continue
            }

            // Skip directories
            if resourceValues.isDirectory == true {
                continue
            }

            // Skip symbolic links to avoid infinite loops
            if resourceValues.isSymbolicLink == true {
                continue
            }

            // Skip unreadable files
            if resourceValues.isReadable == false {
                continue
            }

            // Skip system files by name
            let fileName = fileURL.lastPathComponent
            if skipFileNames.contains(fileName) {
                continue
            }

            // Skip by extension
            let ext = fileURL.pathExtension.lowercased()
            if skipExtensions.contains(ext) {
                continue
            }

            // Check file size
            guard let fileSize = resourceValues.fileSize,
                  Int64(fileSize) >= minSize else {
                continue
            }

            let size = Int64(fileSize)
            sizeGroups[size, default: []].append(fileURL)
            totalFiles += 1

            // Throttle progress updates to every 100ms
            let now = Date()
            if now.timeIntervalSince(lastProgressUpdate) > 0.1 {
                lastProgressUpdate = now
                let currentProgress = min(0.15, 0.05 + Double(totalFiles) / 100000.0 * 0.1)
                let capturedTotalFiles = totalFiles
                await MainActor.run {
                    progress(currentProgress, LFormat("duplicates.scan.foundFiles %lld", Int64(capturedTotalFiles)))
                }
            }
        }

        if isCancelled {
            await MainActor.run { progress(1.0, L("duplicates.scan.cancelled")) }
            return []
        }

        let finalTotalFiles = totalFiles
        await MainActor.run { progress(0.2, LFormat("duplicates.scan.foundFiles %lld", Int64(finalTotalFiles))) }

        // Filter to only size groups with potential duplicates
        let potentialDuplicates = sizeGroups.filter { $0.value.count > 1 }
        let totalGroupsToProcess = potentialDuplicates.count
        var processedGroups = 0

        if totalGroupsToProcess == 0 {
            await MainActor.run { progress(1.0, L("common.complete")) }
            return []
        }

        // Step 2: For each size group, calculate partial hashes
        for (_, files) in potentialDuplicates {
            // Check for cancellation
            if isCancelled {
                await MainActor.run { progress(1.0, L("duplicates.scan.cancelled")) }
                return []
            }

            processedGroups += 1
            let baseProgress = 0.2 + (Double(processedGroups) / Double(totalGroupsToProcess)) * 0.6

            // Throttle UI updates
            if processedGroups % 10 == 0 || processedGroups == totalGroupsToProcess {
                let capturedProcessedGroups = processedGroups
                await MainActor.run {
                    progress(baseProgress, LFormat("duplicates.scan.comparingFiles %lld %lld", Int64(capturedProcessedGroups), Int64(totalGroupsToProcess)))
                }
            }

            // Calculate partial hash for all files in this size group
            var partialHashGroups: [String: [URL]] = [:]

            for file in files {
                if isCancelled { break }

                if let hash = await safePartialHash(file) {
                    partialHashGroups[hash, default: []].append(file)
                }
            }

            if isCancelled { continue }

            // Step 3: For matching partial hashes, calculate full hash
            for (_, partialGroup) in partialHashGroups where partialGroup.count > 1 {
                if isCancelled { break }

                var fullHashGroups: [String: [URL]] = [:]

                for file in partialGroup {
                    if isCancelled { break }

                    if let hash = await safeFullHash(file) {
                        fullHashGroups[hash, default: []].append(file)
                    }
                }

                if isCancelled { continue }

                // Step 4: Create duplicate groups for matching full hashes
                for (hash, matchingFiles) in fullHashGroups where matchingFiles.count > 1 {
                    var duplicateFiles: [DuplicateFile] = []

                    for fileURL in matchingFiles {
                        let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])

                        duplicateFiles.append(DuplicateFile(
                            url: fileURL,
                            size: Int64(resourceValues?.fileSize ?? 0),
                            modificationDate: resourceValues?.contentModificationDate
                        ))
                    }

                    // Sort by date (newest first)
                    duplicateFiles.sort { ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast) }

                    // Mark the first one (newest) as kept by default
                    if !duplicateFiles.isEmpty {
                        duplicateFiles[0].isKept = true
                    }

                    duplicateGroups.append(DuplicateGroup(hash: hash, files: duplicateFiles))
                }
            }
        }

        if isCancelled {
            await MainActor.run { progress(1.0, L("duplicates.scan.cancelled")) }
            return []
        }

        await MainActor.run { progress(0.95, L("duplicates.scan.finalizing")) }

        // Sort groups by wasted size (largest first)
        duplicateGroups.sort { $0.wastedSize > $1.wastedSize }

        await MainActor.run { progress(1.0, L("common.complete")) }

        return duplicateGroups
    }

    // MARK: - Delete

    /// Delete selected duplicate files
    func deleteFiles(_ groups: [DuplicateGroup]) async -> (deleted: Int, freedSpace: Int64, errors: [Error]) {
        var deleted = 0
        var freedSpace: Int64 = 0
        var errors: [Error] = []

        for group in groups {
            for file in group.files where file.isSelected && !file.isKept {
                do {
                    // Verify file still exists before trying to delete
                    guard FileManager.default.fileExists(atPath: file.url.path) else {
                        continue
                    }

                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    deleted += 1
                    freedSpace += file.size
                } catch {
                    errors.append(error)
                }
            }
        }

        return (deleted, freedSpace, errors)
    }

    // MARK: - Safe Hash Methods

    /// Calculate partial hash with proper error handling
    private func safePartialHash(_ url: URL) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    let result = self.partialHashSync(url)
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// Calculate full hash with proper error handling
    private func safeFullHash(_ url: URL) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                autoreleasepool {
                    let result = self.fullHashSync(url)
                    continuation.resume(returning: result)
                }
            }
        }
    }

    /// Calculate partial hash (first 4KB) for quick comparison - synchronous
    private nonisolated func partialHashSync(_ url: URL) -> String? {
        do {
            // Check file is readable
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                return nil
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            let data = try handle.read(upToCount: 4096) ?? Data()
            guard !data.isEmpty else { return nil }

            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            // Silently fail for unreadable files
            return nil
        }
    }

    /// Calculate full SHA256 hash - synchronous
    private nonisolated func fullHashSync(_ url: URL) -> String? {
        do {
            // Check file is readable
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                return nil
            }

            let handle = try FileHandle(forReadingFrom: url)
            defer {
                try? handle.close()
            }

            var hasher = SHA256()
            let bufferSize = 65536 // 64KB chunks

            var keepReading = true
            while keepReading {
                autoreleasepool {
                    do {
                        if let data = try handle.read(upToCount: bufferSize), !data.isEmpty {
                            hasher.update(data: data)
                        } else {
                            keepReading = false
                        }
                    } catch {
                        keepReading = false
                    }
                }
            }

            let hash = hasher.finalize()
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        } catch {
            // Silently fail for unreadable files
            return nil
        }
    }
}
