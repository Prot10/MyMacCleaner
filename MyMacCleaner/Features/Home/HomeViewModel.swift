import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var currentScanCategory: ScanCategory?
    @Published var scanResults: [ScanResult] = []
    @Published var showScanResults = false
    @Published var scanError: String?

    // Permission state
    @Published var showPermissionPrompt = false
    @Published var hasFullDiskAccess = false

    // System stats
    @Published var storageUsed: String = "0 GB"
    @Published var storageTotal: String = "0 GB"
    @Published var storageFree: String = "0 GB"
    @Published var memoryUsed: String = "0 GB"
    @Published var junkSize: String = "0 MB"
    @Published var appCount: Int = 0

    // System health
    @Published var systemHealthStatus: String = L("home.health.healthy")
    @Published var systemHealthColor: Color = .green

    // Cleaning state
    @Published var isCleaning = false
    @Published var cleaningProgress: Double = 0
    @Published var cleaningCategory: String = ""

    // Toast notification
    @Published var showToast = false
    @Published var toastMessage: String = ""
    @Published var toastType: ToastType = .success

    // Navigation callback - set by parent view to handle navigation requests
    var onNavigateToSection: ((String) -> Void)?

    // MARK: - Private Properties

    private let fileScanner = FileScanner.shared
    private let permissionsService = PermissionsService.shared

    // MARK: - Initialization

    init() {
        Task {
            await loadSystemStats()
            await checkPermissions()
            await performQuickEstimate()
        }
    }

    // MARK: - Public Methods

    func startSmartScan() {
        guard !isScanning else { return }

        // Check if we should prompt for permissions
        if !hasFullDiskAccess && !showPermissionPrompt {
            showPermissionPrompt = true
            return
        }

        performScan()
    }

    func continueWithLimitedScan() {
        showPermissionPrompt = false
        performScan()
    }

    func dismissPermissionPrompt() {
        showPermissionPrompt = false
    }

    func refreshPermissions() {
        Task {
            await checkPermissions()
        }
    }

    func emptyTrash() {
        // Check FDA permission first - emptying trash requires it for complete cleanup
        if !hasFullDiskAccess {
            // Show permission prompt instead of failing silently
            showPermissionPrompt = true
            return
        }

        Task {
            let trashSize = await fileScanner.getTrashSize()
            if trashSize == 0 {
                showToastMessage(L("home.toast.trashEmpty"), type: .info)
                return
            }

            let result = await fileScanner.emptyTrash()

            // Refresh stats after emptying
            await loadSystemStats()
            await performQuickEstimate()

            if result.errors.isEmpty {
                showToastMessage(L("home.toast.trashSuccess"), type: .success)
            } else if result.deletedCount > 0 {
                let freedFormatted = ByteCountFormatter.string(fromByteCount: result.freedSpace, countStyle: .file)
                showToastMessage(LFormat("home.toast.cleanPartial %@ %lld", freedFormatted, Int64(result.failedCount)), type: .info)
            } else {
                let errorMsg = result.errors.first?.localizedDescription ?? "Unknown error"
                showToastMessage(LFormat("home.toast.trashFailed %@", errorMsg), type: .error)
            }
        }
    }

    func freeMemory() {
        // Navigate to Performance section where user can use Purge Disk Cache
        onNavigateToSection?("performance")
    }

    func viewLargeFiles() {
        // Navigate to Disk Cleaner section (Space Lens tab)
        onNavigateToSection?("diskCleaner")
    }

    func cleanSelectedItems() {
        guard !isCleaning, !scanResults.isEmpty else { return }

        isCleaning = true
        cleaningProgress = 0
        cleaningCategory = ""

        Task {
            var totalFreed: Int64 = 0
            var failedCount = 0
            // Only include items from selected categories
            let selectedCategories = scanResults.filter { $0.isSelected }
            let allItems = selectedCategories.flatMap { $0.items }
            let selectedItems = allItems.filter { $0.isSelected }
            let totalItems = selectedItems.count

            guard totalItems > 0 else {
                isCleaning = false
                showToastMessage(L("home.toast.noItemsSelected"), type: .info)
                return
            }

            for (index, item) in selectedItems.enumerated() {
                cleaningCategory = item.category.localizedName
                cleaningProgress = Double(index) / Double(totalItems)

                let result = await fileScanner.trashItems([item])
                totalFreed += result.freedSpace
                failedCount += result.failedCount

                // Small delay for visual feedback
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            }

            cleaningProgress = 1.0

            // Small delay to show 100%
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

            // Refresh after cleaning
            scanResults = []
            showScanResults = false
            isCleaning = false
            cleaningCategory = ""

            await loadSystemStats()
            await performQuickEstimate()

            // Show result toast
            let freedFormatted = ByteCountFormatter.string(fromByteCount: totalFreed, countStyle: .file)
            if failedCount == 0 {
                showToastMessage(LFormat("home.toast.cleanSuccess %@", freedFormatted), type: .success)
            } else if failedCount < totalItems {
                showToastMessage(LFormat("home.toast.cleanPartial %@ %lld", freedFormatted, Int64(failedCount)), type: .info)
            } else {
                showToastMessage(L("home.toast.cleanFailed"), type: .error)
            }
        }
    }

    func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }

    func dismissToast() {
        showToast = false
    }

    // MARK: - Private Methods

    private func performScan() {
        isScanning = true
        scanProgress = 0
        scanResults = []
        scanError = nil

        Task {
            do {
                let results = try await fileScanner.scanAllCategories { [weak self] progress, category in
                    self?.scanProgress = progress
                    self?.currentScanCategory = category
                }

                scanResults = results
                showScanResults = !results.isEmpty

                // Update junk size with actual results
                let totalJunk = results.reduce(0) { $0 + $1.totalSize }
                junkSize = formatBytes(totalJunk)

            } catch {
                scanError = "Scan failed: \(error.localizedDescription)"
            }

            isScanning = false
            currentScanCategory = nil
        }
    }

    private func checkPermissions() async {
        permissionsService.checkFullDiskAccess()
        hasFullDiskAccess = permissionsService.hasFullDiskAccess
    }

    private func performQuickEstimate() async {
        let estimates = await fileScanner.quickEstimate()
        let total = estimates.values.reduce(0, +)
        if total > 0 {
            junkSize = formatBytes(total)
        } else {
            junkSize = L("home.stats.scanToCheck")
        }
    }

    private func loadSystemStats() async {
        // Get disk space
        let diskStats = getDiskSpace()
        storageUsed = formatBytes(diskStats.used)
        storageTotal = formatBytes(diskStats.total)
        storageFree = formatBytes(diskStats.free)

        // Get memory stats
        let memoryStats = getMemoryStats()
        memoryUsed = formatBytes(memoryStats.used)

        // Count installed apps
        appCount = countInstalledApps()

        // Determine system health
        updateSystemHealth(diskStats: diskStats, memoryStats: memoryStats)
    }

    private func getDiskSpace() -> (total: Int64, used: Int64, free: Int64) {
        do {
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            let values = try homeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let used = total - available

            return (total, used, available)
        } catch {
            return (0, 0, 0)
        }
    }

    private func getMemoryStats() -> (total: UInt64, used: UInt64, free: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory

        // Get actual memory usage via host_statistics64
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            let free = UInt64(stats.free_count) * pageSize
            let active = UInt64(stats.active_count) * pageSize
            let inactive = UInt64(stats.inactive_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize

            let used = active + wired + compressed
            return (total, used, free + inactive)
        }

        // Fallback estimate
        let used = UInt64(Double(total) * 0.6)
        return (total, used, total - used)
    }

    private func countInstalledApps() -> Int {
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: applicationsURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            return contents.filter { $0.pathExtension == "app" }.count
        } catch {
            return 0
        }
    }

    private func updateSystemHealth(
        diskStats: (total: Int64, used: Int64, free: Int64),
        memoryStats: (total: UInt64, used: UInt64, free: UInt64)
    ) {
        let diskUsagePercent = diskStats.total > 0 ? Double(diskStats.used) / Double(diskStats.total) : 0
        let memoryUsagePercent = memoryStats.total > 0 ? Double(memoryStats.used) / Double(memoryStats.total) : 0

        if diskUsagePercent > 0.9 || memoryUsagePercent > 0.9 {
            systemHealthStatus = L("home.health.needsAttention")
            systemHealthColor = .red
        } else if diskUsagePercent > 0.75 || memoryUsagePercent > 0.8 {
            systemHealthStatus = L("home.health.fair")
            systemHealthColor = .yellow
        } else {
            systemHealthStatus = L("home.health.healthy")
            systemHealthColor = .green
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        formatBytes(Int64(bytes))
    }
}
