import Foundation

@Observable
final class OptimizerViewModel {
    var memoryStats: MemoryDisplayStats?
    var launchAgents: [LaunchAgentInfo] = []
    var isPurging = false

    private let systemStatsRepo = SystemStatsRepository()

    @MainActor
    func loadData() async {
        // Load memory stats
        let stats = systemStatsRepo.getMemoryStats()
        memoryStats = MemoryDisplayStats(from: stats)

        // Load launch agents
        await loadLaunchAgents()

        // Start monitoring
        startMonitoring()
    }

    private var monitoringTask: Task<Void, Never>?

    @MainActor
    private func startMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }

                let stats = systemStatsRepo.getMemoryStats()
                memoryStats = MemoryDisplayStats(from: stats)
            }
        }
    }

    @MainActor
    func purgeMemory() async {
        isPurging = true

        // TODO: Call helper service to run `purge`
        // For now, simulate the operation
        try? await Task.sleep(for: .seconds(2))

        // Refresh stats
        let stats = systemStatsRepo.getMemoryStats()
        memoryStats = MemoryDisplayStats(from: stats)

        isPurging = false
    }

    @MainActor
    private func loadLaunchAgents() async {
        let fm = FileManager.default
        let home = NSHomeDirectory()

        let paths = [
            "\(home)/Library/LaunchAgents",
            "/Library/LaunchAgents",
        ]

        var agents: [LaunchAgentInfo] = []

        for basePath in paths {
            guard fm.fileExists(atPath: basePath) else { continue }

            do {
                let contents = try fm.contentsOfDirectory(atPath: basePath)
                for item in contents where item.hasSuffix(".plist") {
                    let fullPath = (basePath as NSString).appendingPathComponent(item)

                    if let plist = NSDictionary(contentsOfFile: fullPath),
                       let label = plist["Label"] as? String {
                        let disabled = plist["Disabled"] as? Bool ?? false

                        agents.append(LaunchAgentInfo(
                            label: label,
                            path: fullPath,
                            isEnabled: !disabled
                        ))
                    }
                }
            } catch {
                // Skip inaccessible directories
            }
        }

        launchAgents = agents.sorted { $0.label.localizedCompare($1.label) == .orderedAscending }
    }

    @MainActor
    func toggleAgent(_ agent: LaunchAgentInfo) async {
        // TODO: Implement via helper service for system-level agents
        // For now, just toggle the local state

        if let index = launchAgents.firstIndex(where: { $0.id == agent.id }) {
            launchAgents[index].isEnabled.toggle()
        }
    }

    deinit {
        monitoringTask?.cancel()
    }
}

// MARK: - Types

struct MemoryDisplayStats {
    let total: UInt64
    let wired: UInt64
    let active: UInt64
    let compressed: UInt64
    let inactive: UInt64
    let free: UInt64

    var wiredPercentage: Double {
        Double(wired) / Double(total)
    }

    var activePercentage: Double {
        Double(active) / Double(total)
    }

    var compressedPercentage: Double {
        Double(compressed) / Double(total)
    }

    var inactivePercentage: Double {
        Double(inactive) / Double(total)
    }

    var freePercentage: Double {
        Double(free) / Double(total)
    }

    var wiredText: String {
        formatBytes(wired)
    }

    var activeText: String {
        formatBytes(active)
    }

    var compressedText: String {
        formatBytes(compressed)
    }

    var freeText: String {
        formatBytes(free + inactive)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    init(from stats: MemoryStats) {
        self.total = stats.total
        self.wired = stats.wired
        self.active = stats.active
        self.compressed = stats.compressed
        self.inactive = stats.inactive
        self.free = stats.free
    }
}

struct LaunchAgentInfo: Identifiable {
    let id = UUID()
    let label: String
    let path: String
    var isEnabled: Bool
}
