import Foundation
import SwiftUI

@Observable
final class DashboardViewModel {
    // State
    var isScanning = false
    var scanProgress: Double = 0
    var totalCleanableSize: Int64 = 0
    var cleanupCategories: [CleanupCategorySummary] = []
    var diskCategories: [DiskCategory] = []

    // System Stats
    var memoryStats: MemoryStats?
    var diskUsage: DiskUsage?
    var cpuUsage: Double = 0

    // Repositories
    private let systemStatsRepo = SystemStatsRepository()

    // MARK: - Computed Properties

    var memoryUsagePercentage: Double {
        memoryStats?.usagePercentage ?? 0
    }

    var memoryUsageText: String {
        guard let stats = memoryStats else { return "--" }
        let usedGB = Double(stats.used) / 1_073_741_824
        let totalGB = Double(stats.total) / 1_073_741_824
        return String(format: "%.1f / %.1f GB", usedGB, totalGB)
    }

    var memoryColor: Color {
        switch memoryUsagePercentage {
        case 0..<0.5: return .green
        case 0.5..<0.75: return .orange
        default: return .red
        }
    }

    var storageUsagePercentage: Double {
        diskUsage?.usagePercentage ?? 0
    }

    var storageUsageText: String {
        guard let usage = diskUsage else { return "--" }
        return "\(usage.formattedUsed) / \(usage.formattedTotal)"
    }

    var storageColor: Color {
        switch storageUsagePercentage {
        case 0..<0.7: return .green
        case 0.7..<0.85: return .orange
        default: return .red
        }
    }

    var cpuUsagePercentage: Double {
        cpuUsage
    }

    var cpuUsageText: String {
        String(format: "%.0f%%", cpuUsage * 100)
    }

    var cpuColor: Color {
        switch cpuUsage {
        case 0..<0.5: return .green
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }

    // MARK: - Data Loading

    @MainActor
    func loadData() async {
        // Load system stats
        memoryStats = systemStatsRepo.getMemoryStats()
        diskUsage = systemStatsRepo.getDiskUsage()
        cpuUsage = systemStatsRepo.getCPUUsage()

        // Load disk breakdown (async because it can be slow)
        diskCategories = await systemStatsRepo.getDiskUsageBreakdown()

        // Start monitoring for updates
        startMonitoring()
    }

    private var monitoringTask: Task<Void, Never>?

    @MainActor
    private func startMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { break }

                memoryStats = systemStatsRepo.getMemoryStats()
                cpuUsage = systemStatsRepo.getCPUUsage()
            }
        }
    }

    // MARK: - Scanning

    @MainActor
    func startScan() async {
        guard !isScanning else { return }

        isScanning = true
        scanProgress = 0
        totalCleanableSize = 0
        cleanupCategories = []

        // Simulate scanning phases
        let phases: [(name: String, progress: Double, delay: Double)] = [
            ("System Caches", 0.2, 0.5),
            ("User Caches", 0.4, 0.4),
            ("Logs", 0.5, 0.3),
            ("Xcode Data", 0.7, 0.6),
            ("Package Caches", 0.85, 0.4),
            ("Trash", 1.0, 0.3),
        ]

        for phase in phases {
            guard isScanning else { break }

            try? await Task.sleep(for: .seconds(phase.delay))
            scanProgress = phase.progress

            // Add mock data for demonstration
            let size = Int64.random(in: 100_000_000...2_000_000_000)
            totalCleanableSize += size
            cleanupCategories.append(
                CleanupCategorySummary(name: phase.name, sizeBytes: size)
            )
        }

        isScanning = false
    }

    // MARK: - Cleanup

    @MainActor
    func performCleanup() async {
        // TODO: Implement actual cleanup via helper service
        totalCleanableSize = 0
        cleanupCategories = []
    }

    deinit {
        monitoringTask?.cancel()
    }
}

// MARK: - Support Types

struct CleanupCategorySummary: Identifiable {
    let id = UUID()
    let name: String
    let sizeBytes: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

// MemoryStats is defined in SharedKit/Sources/Models/MemoryStats.swift
