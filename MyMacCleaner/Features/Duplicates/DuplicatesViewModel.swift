import SwiftUI

@MainActor
class DuplicatesViewModel: ObservableObject {
    // MARK: - Published State

    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var scanProgress: Double = 0
    @Published var currentScanStatus: String = ""

    @Published var duplicateGroups: [DuplicateGroup] = []

    @Published var showCleanConfirmation = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    @Published var searchText = ""
    @Published var filterType: FileType?
    @Published var sortOrder: SortOrder = .wastedSizeDescending

    @Published var scanPath: URL = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - Enums

    enum SortOrder: String, CaseIterable {
        case wastedSizeDescending = "Wasted Space (Most)"
        case wastedSizeAscending = "Wasted Space (Least)"
        case fileSizeDescending = "File Size (Largest)"
        case fileSizeAscending = "File Size (Smallest)"
        case duplicateCountDescending = "Copies (Most)"

        var localizedName: String {
            switch self {
            case .wastedSizeDescending: return L("duplicates.sort.wastedMost")
            case .wastedSizeAscending: return L("duplicates.sort.wastedLeast")
            case .fileSizeDescending: return L("duplicates.sort.sizeLargest")
            case .fileSizeAscending: return L("duplicates.sort.sizeSmallest")
            case .duplicateCountDescending: return L("duplicates.sort.copiesMost")
            }
        }
    }

    // MARK: - Computed Properties

    var filteredGroups: [DuplicateGroup] {
        var result = duplicateGroups

        // Apply search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { group in
                group.files.contains { file in
                    file.name.lowercased().contains(query) ||
                    file.url.path.lowercased().contains(query)
                }
            }
        }

        // Apply file type filter
        if let typeFilter = filterType {
            result = result.filter { $0.fileType == typeFilter }
        }

        // Apply sort
        switch sortOrder {
        case .wastedSizeDescending:
            result.sort { $0.wastedSize > $1.wastedSize }
        case .wastedSizeAscending:
            result.sort { $0.wastedSize < $1.wastedSize }
        case .fileSizeDescending:
            result.sort { $0.fileSize > $1.fileSize }
        case .fileSizeAscending:
            result.sort { $0.fileSize < $1.fileSize }
        case .duplicateCountDescending:
            result.sort { $0.files.count > $1.files.count }
        }

        return result
    }

    var totalWastedSize: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.wastedSize }
    }

    var selectedSize: Int64 {
        var total: Int64 = 0
        for group in duplicateGroups {
            for file in group.files where file.isSelected && !file.isKept {
                total += file.size
            }
        }
        return total
    }

    var selectedCount: Int {
        var count = 0
        for group in duplicateGroups {
            for file in group.files where file.isSelected && !file.isKept {
                count += 1
            }
        }
        return count
    }

    var totalGroupCount: Int {
        duplicateGroups.count
    }

    var totalDuplicateFileCount: Int {
        duplicateGroups.reduce(0) { $0 + $1.files.count - 1 } // Count all but one in each group
    }

    var formattedTotalWastedSize: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSize, countStyle: .file)
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    var fileTypeStats: [(FileType, Int, Int64)] {
        var stats: [FileType: (count: Int, size: Int64)] = [:]

        for group in duplicateGroups {
            let type = group.fileType
            let existing = stats[type] ?? (0, 0)
            stats[type] = (existing.count + 1, existing.size + group.wastedSize)
        }

        return stats.map { ($0.key, $0.value.count, $0.value.size) }
            .sorted { $0.2 > $1.2 }
    }

    // MARK: - Scanner

    private let scanner = DuplicateScanner.shared

    // MARK: - Actions

    func chooseScanLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = L("duplicates.chooseFolderMessage")
        panel.prompt = L("duplicates.chooseFolderButton")

        if panel.runModal() == .OK, let url = panel.url {
            scanPath = url
        }
    }

    func startScan() {
        isScanning = true
        hasScanned = false
        scanProgress = 0
        duplicateGroups = []

        Task {
            let results = await scanner.scan(at: scanPath, minSize: 1024) { [weak self] progress, status in
                Task { @MainActor in
                    self?.scanProgress = progress
                    self?.currentScanStatus = status
                }
            }

            duplicateGroups = results
            isScanning = false
            hasScanned = true

            // Show toast if no duplicates found
            if results.isEmpty && scanProgress >= 1.0 {
                toastMessage = L("duplicates.noDuplicatesFound")
                toastType = .info
                showToast = true

                try? await Task.sleep(for: .seconds(3))
                showToast = false
            }
        }
    }

    func cancelScan() {
        Task {
            await scanner.cancel()
            isScanning = false
            hasScanned = false
            scanProgress = 0
            currentScanStatus = ""

            toastMessage = L("duplicates.scan.cancelled")
            toastType = .info
            showToast = true

            try? await Task.sleep(for: .seconds(2))
            showToast = false
        }
    }

    func toggleFileSelection(_ file: DuplicateFile, in group: DuplicateGroup) {
        guard let groupIndex = duplicateGroups.firstIndex(where: { $0.id == group.id }),
              let fileIndex = duplicateGroups[groupIndex].files.firstIndex(where: { $0.id == file.id }) else {
            return
        }

        // Don't allow selecting the kept file
        guard !duplicateGroups[groupIndex].files[fileIndex].isKept else { return }

        duplicateGroups[groupIndex].files[fileIndex].isSelected.toggle()
    }

    func setKeptFile(_ file: DuplicateFile, in group: DuplicateGroup) {
        guard let groupIndex = duplicateGroups.firstIndex(where: { $0.id == group.id }),
              let fileIndex = duplicateGroups[groupIndex].files.firstIndex(where: { $0.id == file.id }) else {
            return
        }

        // Clear all kept flags in this group
        for i in duplicateGroups[groupIndex].files.indices {
            duplicateGroups[groupIndex].files[i].isKept = false
            duplicateGroups[groupIndex].files[i].isSelected = false
        }

        // Set the new kept file
        duplicateGroups[groupIndex].files[fileIndex].isKept = true
    }

    func selectAllDuplicates() {
        for groupIndex in duplicateGroups.indices {
            for fileIndex in duplicateGroups[groupIndex].files.indices {
                if !duplicateGroups[groupIndex].files[fileIndex].isKept {
                    duplicateGroups[groupIndex].files[fileIndex].isSelected = true
                }
            }
        }
    }

    func deselectAll() {
        for groupIndex in duplicateGroups.indices {
            for fileIndex in duplicateGroups[groupIndex].files.indices {
                duplicateGroups[groupIndex].files[fileIndex].isSelected = false
            }
        }
    }

    func selectOldestInEachGroup() {
        for groupIndex in duplicateGroups.indices {
            // First, clear all selections and kept flags
            for fileIndex in duplicateGroups[groupIndex].files.indices {
                duplicateGroups[groupIndex].files[fileIndex].isSelected = false
                duplicateGroups[groupIndex].files[fileIndex].isKept = false
            }

            // Find the newest file and mark it as kept
            if let newestIndex = duplicateGroups[groupIndex].files.indices.max(by: {
                (duplicateGroups[groupIndex].files[$0].modificationDate ?? .distantPast) <
                (duplicateGroups[groupIndex].files[$1].modificationDate ?? .distantPast)
            }) {
                duplicateGroups[groupIndex].files[newestIndex].isKept = true
            }

            // Select all others for deletion
            for fileIndex in duplicateGroups[groupIndex].files.indices {
                if !duplicateGroups[groupIndex].files[fileIndex].isKept {
                    duplicateGroups[groupIndex].files[fileIndex].isSelected = true
                }
            }
        }
    }

    func prepareClean() {
        guard selectedCount > 0 else { return }
        showCleanConfirmation = true
    }

    func confirmClean() {
        showCleanConfirmation = false

        Task {
            let result = await scanner.deleteFiles(duplicateGroups)

            if result.errors.isEmpty {
                toastMessage = LFormat("duplicates.clean.success %lld %@", Int64(result.deleted), ByteCountFormatter.string(fromByteCount: result.freedSpace, countStyle: .file))
                toastType = .success
            } else {
                toastMessage = LFormat("duplicates.clean.partial %lld %lld", Int64(result.deleted), Int64(result.errors.count))
                toastType = .error
            }

            showToast = true

            // Rescan to update list
            startScan()

            // Auto-dismiss toast
            try? await Task.sleep(for: .seconds(3))
            showToast = false
        }
    }

    func cancelClean() {
        showCleanConfirmation = false
    }

    func revealInFinder(_ file: DuplicateFile) {
        NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: file.url.deletingLastPathComponent().path)
    }

    func dismissToast() {
        showToast = false
    }

    func clearFilter() {
        filterType = nil
        searchText = ""
    }
}
