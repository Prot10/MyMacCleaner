import SwiftUI

@MainActor
class DiskCleanerViewModel: ObservableObject {
    // MARK: - Published Properties

    // Scanning state
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentScanCategory: ScanCategory?

    // Results
    @Published var scanResults: [ScanResult] = []
    @Published var hasScanned = false

    // Selection
    @Published var expandedCategory: ScanCategory?
    @Published var selectedCategory: ScanResult?
    @Published var showCategoryDetail = false

    // Cleaning
    @Published var isCleaning = false
    @Published var cleaningProgress: Double = 0
    @Published var cleaningCategory: String = ""
    @Published var showCleanConfirmation = false
    @Published var itemsToClean: [CleanableItem] = []

    // Toast
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    // Trash
    @Published var trashSize: Int64 = 0
    @Published var isEmptyingTrash = false
    @Published var showEmptyTrashConfirmation = false

    // Errors
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var totalCleanableSize: Int64 {
        scanResults.reduce(0) { $0 + $1.totalSize }
    }

    var selectedSize: Int64 {
        scanResults.reduce(0) { $0 + $1.selectedSize }
    }

    var totalItemCount: Int {
        scanResults.reduce(0) { $0 + $1.itemCount }
    }

    var selectedItemCount: Int {
        scanResults.reduce(0) { result, scanResult in
            result + scanResult.items.filter { $0.isSelected }.count
        }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalCleanableSize, countStyle: .file)
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    var formattedTrashSize: String {
        ByteCountFormatter.string(fromByteCount: trashSize, countStyle: .file)
    }

    var hasFullDiskAccess: Bool {
        permissionsService.hasFullDiskAccess
    }

    // MARK: - Private Properties

    private let fileScanner = FileScanner.shared
    private let permissionsService = PermissionsService.shared

    // MARK: - Public Methods

    func startScan() {
        guard !isScanning else { return }

        isScanning = true
        scanProgress = 0
        scanResults = []
        errorMessage = nil

        Task {
            do {
                let results = try await fileScanner.scanAllCategories { [weak self] progress, category in
                    self?.scanProgress = progress
                    self?.currentScanCategory = category
                }

                scanResults = results
                hasScanned = true

            } catch {
                errorMessage = LFormat("diskCleaner.toast.scanFailed %@", error.localizedDescription)
            }

            isScanning = false
            currentScanCategory = nil
        }
    }

    func toggleCategoryExpansion(_ category: ScanCategory) {
        withAnimation(Theme.Animation.spring) {
            if expandedCategory == category {
                expandedCategory = nil
            } else {
                expandedCategory = category
            }
        }
    }

    func showDetails(for result: ScanResult) {
        selectedCategory = result
        showCategoryDetail = true
    }

    func toggleItemSelection(_ item: CleanableItem, in category: ScanCategory) {
        guard let resultIndex = scanResults.firstIndex(where: { $0.category == category }),
              let itemIndex = scanResults[resultIndex].items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        scanResults[resultIndex].items[itemIndex].isSelected.toggle()
    }

    func toggleCategorySelection(_ category: ScanCategory) {
        guard let resultIndex = scanResults.firstIndex(where: { $0.category == category }) else {
            return
        }

        let allSelected = scanResults[resultIndex].items.allSatisfy { $0.isSelected }

        // Create a mutable copy to ensure @Published triggers properly
        var updatedResults = scanResults
        for i in updatedResults[resultIndex].items.indices {
            updatedResults[resultIndex].items[i].isSelected = !allSelected
        }
        scanResults = updatedResults
    }

    func selectAll() {
        // Create a mutable copy to ensure @Published triggers properly and avoid mutation during iteration
        var updatedResults = scanResults
        for resultIndex in updatedResults.indices {
            for itemIndex in updatedResults[resultIndex].items.indices {
                updatedResults[resultIndex].items[itemIndex].isSelected = true
            }
        }
        scanResults = updatedResults
    }

    func deselectAll() {
        // Create a mutable copy to ensure @Published triggers properly and avoid mutation during iteration
        var updatedResults = scanResults
        for resultIndex in updatedResults.indices {
            for itemIndex in updatedResults[resultIndex].items.indices {
                updatedResults[resultIndex].items[itemIndex].isSelected = false
            }
        }
        scanResults = updatedResults
    }

    func prepareClean() {
        itemsToClean = scanResults.flatMap { $0.items }.filter { $0.isSelected }
        if !itemsToClean.isEmpty {
            showCleanConfirmation = true
        }
    }

    func confirmClean() {
        showCleanConfirmation = false
        performClean()
    }

    func cancelClean() {
        showCleanConfirmation = false
        itemsToClean = []
    }

    private func performClean() {
        guard !isCleaning, !itemsToClean.isEmpty else { return }

        isCleaning = true
        cleaningProgress = 0
        cleaningCategory = ""

        Task {
            var totalFreed: Int64 = 0
            var failedCount = 0
            let totalItems = itemsToClean.count

            for (index, item) in itemsToClean.enumerated() {
                cleaningCategory = item.category.localizedName
                cleaningProgress = Double(index) / Double(totalItems)

                let result = await fileScanner.trashItems([item])
                totalFreed += result.freedSpace
                failedCount += result.failedCount

                try? await Task.sleep(nanoseconds: 50_000_000)
            }

            cleaningProgress = 1.0
            try? await Task.sleep(nanoseconds: 300_000_000)

            // Remove cleaned items from results
            for resultIndex in scanResults.indices {
                scanResults[resultIndex].items.removeAll { item in
                    itemsToClean.contains { $0.id == item.id } && item.isSelected
                }
            }

            // Remove empty categories
            scanResults.removeAll { $0.items.isEmpty }

            isCleaning = false
            cleaningCategory = ""
            itemsToClean = []

            // Show result
            let freedFormatted = ByteCountFormatter.string(fromByteCount: totalFreed, countStyle: .file)
            if failedCount == 0 {
                showToastMessage(LFormat("diskCleaner.toast.cleanSuccess %@", freedFormatted), type: .success)
            } else if failedCount < totalItems {
                showToastMessage(LFormat("diskCleaner.toast.cleanPartial %@ %lld", freedFormatted, Int64(failedCount)), type: .info)
            } else {
                showToastMessage(L("diskCleaner.toast.cleanFailed"), type: .error)
            }
        }
    }

    func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }

    func dismissToast() {
        showToast = false
    }

    // MARK: - Trash Methods

    func refreshTrashSize() {
        Task {
            trashSize = await fileScanner.getTrashSize()
        }
    }

    func prepareEmptyTrash() {
        // Check FDA permission first
        if !hasFullDiskAccess {
            showToastMessage(L("diskCleaner.toast.needFDA"), type: .info)
            permissionsService.openFullDiskAccessSettings()
            return
        }

        if trashSize == 0 {
            showToastMessage(L("diskCleaner.toast.trashEmpty"), type: .info)
            return
        }

        showEmptyTrashConfirmation = true
    }

    func confirmEmptyTrash() {
        showEmptyTrashConfirmation = false

        Task {
            isEmptyingTrash = true

            let result = await fileScanner.emptyTrash()

            isEmptyingTrash = false

            // Refresh trash size
            trashSize = await fileScanner.getTrashSize()

            if result.errors.isEmpty {
                let freedFormatted = ByteCountFormatter.string(fromByteCount: result.freedSpace, countStyle: .file)
                showToastMessage(LFormat("diskCleaner.toast.trashSuccess %@", freedFormatted), type: .success)
            } else if result.deletedCount > 0 {
                let freedFormatted = ByteCountFormatter.string(fromByteCount: result.freedSpace, countStyle: .file)
                showToastMessage(LFormat("diskCleaner.toast.trashPartial %@ %lld", freedFormatted, Int64(result.failedCount)), type: .info)
            } else {
                showToastMessage(L("diskCleaner.toast.trashFailed"), type: .error)
            }
        }
    }

    func cancelEmptyTrash() {
        showEmptyTrashConfirmation = false
    }

    // MARK: - Helpers

    func result(for category: ScanCategory) -> ScanResult? {
        scanResults.first { $0.category == category }
    }
}
