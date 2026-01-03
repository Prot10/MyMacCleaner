import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var scanResults: ScanResults?

    // System stats
    @Published var storageUsed: String = "0 GB"
    @Published var storageTotal: String = "0 GB"
    @Published var memoryUsed: String = "0 GB"
    @Published var junkSize: String = "0 MB"
    @Published var appCount: Int = 0

    // System health
    @Published var systemHealthStatus: String = "Healthy"
    @Published var systemHealthColor: Color = .green

    // MARK: - Initialization

    init() {
        Task {
            await loadSystemStats()
        }
    }

    // MARK: - Public Methods

    func startSmartScan() {
        guard !isScanning else { return }

        isScanning = true
        scanProgress = 0

        Task {
            // Simulate scanning progress
            for i in 1...10 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                scanProgress = Double(i) / 10.0
            }

            // Generate mock results
            scanResults = ScanResults(
                systemJunk: 1_500_000_000,
                userCache: 800_000_000,
                appCache: 500_000_000,
                logs: 200_000_000,
                trash: 300_000_000
            )

            junkSize = formatBytes(scanResults?.totalCleanable ?? 0)

            isScanning = false
        }
    }

    func emptyTrash() {
        // TODO: Implement trash emptying
        print("Empty trash")
    }

    func freeMemory() {
        // TODO: Implement memory freeing
        print("Free memory")
    }

    func viewLargeFiles() {
        // TODO: Navigate to space lens
        print("View large files")
    }

    // MARK: - Private Methods

    private func loadSystemStats() async {
        // Get disk space
        let diskStats = getDiskSpace()
        storageUsed = formatBytes(diskStats.used)
        storageTotal = formatBytes(diskStats.total)

        // Get memory stats
        let memoryStats = getMemoryStats()
        memoryUsed = formatBytes(memoryStats.used)

        // Count installed apps
        appCount = countInstalledApps()

        // Initial junk estimate
        junkSize = "Scan to check"

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

    private func getMemoryStats() -> (total: UInt64, used: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        // Simplified: estimate 60% usage as default
        let used = UInt64(Double(total) * 0.6)
        return (total, used)
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

    private func updateSystemHealth(diskStats: (total: Int64, used: Int64, free: Int64), memoryStats: (total: UInt64, used: UInt64)) {
        let diskUsagePercent = diskStats.total > 0 ? Double(diskStats.used) / Double(diskStats.total) : 0
        let memoryUsagePercent = memoryStats.total > 0 ? Double(memoryStats.used) / Double(memoryStats.total) : 0

        if diskUsagePercent > 0.9 || memoryUsagePercent > 0.9 {
            systemHealthStatus = "Needs Attention"
            systemHealthColor = .red
        } else if diskUsagePercent > 0.75 || memoryUsagePercent > 0.8 {
            systemHealthStatus = "Fair"
            systemHealthColor = .yellow
        } else {
            systemHealthStatus = "Healthy"
            systemHealthColor = .green
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        formatBytes(Int64(bytes))
    }
}

// MARK: - Models

struct ScanResults {
    let systemJunk: Int64
    let userCache: Int64
    let appCache: Int64
    let logs: Int64
    let trash: Int64

    var totalCleanable: Int64 {
        systemJunk + userCache + appCache + logs + trash
    }
}
