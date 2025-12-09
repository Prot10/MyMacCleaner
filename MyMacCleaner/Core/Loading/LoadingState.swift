import Foundation
import SwiftUI

// MARK: - Loading State

/// Represents the loading state of async data with associated values
enum LoadingState<T: Sendable>: Sendable {
    case idle
    case loading
    case loaded(T)
    case failed(Error)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var data: T? {
        if case .loaded(let data) = self { return data }
        return nil
    }

    var error: Error? {
        if case .failed(let error) = self { return error }
        return nil
    }
}

// MARK: - Page Loading State

/// Tracks loading state for each page/section of the app
@Observable
final class PageLoadingState {
    var dashboard: LoadingState<DashboardData> = .idle
    var cleaner: LoadingState<CleanerData> = .idle
    var uninstaller: LoadingState<UninstallerData> = .idle
    var optimizer: LoadingState<OptimizerData> = .idle

    /// Overall preload progress (0.0 to 1.0)
    var preloadProgress: Double {
        var loaded = 0
        let total = 4

        if dashboard.isLoaded { loaded += 1 }
        if cleaner.isLoaded { loaded += 1 }
        if uninstaller.isLoaded { loaded += 1 }
        if optimizer.isLoaded { loaded += 1 }

        return Double(loaded) / Double(total)
    }

    var isFullyLoaded: Bool {
        preloadProgress >= 1.0
    }

    func state(for item: NavigationItem) -> Bool {
        switch item {
        case .dashboard: return dashboard.isLoaded
        case .cleaner: return cleaner.isLoaded
        case .uninstaller: return uninstaller.isLoaded
        case .optimizer: return optimizer.isLoaded
        case .settings: return true // Settings doesn't need preloading
        }
    }
}

// MARK: - Preloaded Data Types

/// Dashboard data with optional fields for progressive loading
struct DashboardData: Sendable {
    var memoryStats: MemoryStats?
    var diskUsage: DiskUsage?
    var cpuUsage: Double?
    var diskCategories: [DiskCategory]?

    var hasBasicStats: Bool {
        memoryStats != nil && diskUsage != nil && cpuUsage != nil
    }

    var isFullyLoaded: Bool {
        hasBasicStats && diskCategories != nil
    }

    init(memoryStats: MemoryStats? = nil, diskUsage: DiskUsage? = nil, cpuUsage: Double? = nil, diskCategories: [DiskCategory]? = nil) {
        self.memoryStats = memoryStats
        self.diskUsage = diskUsage
        self.cpuUsage = cpuUsage
        self.diskCategories = diskCategories
    }
}

struct CleanerData: Sendable {
    let categories: [CleanerCategoryData]
}

struct CleanerCategoryData: Identifiable, Sendable {
    let id: UUID
    let name: String
    let icon: String
    let paths: [String]
    var sizeBytes: Int64
    var itemCount: Int

    init(id: UUID = UUID(), name: String, icon: String, paths: [String], sizeBytes: Int64 = 0, itemCount: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.paths = paths
        self.sizeBytes = sizeBytes
        self.itemCount = itemCount
    }
}

struct UninstallerData: Sendable {
    let apps: [AppInfo]
}

struct OptimizerData: Sendable {
    let memoryStats: MemoryStats
    let launchAgents: [LaunchAgentData]
}

struct LaunchAgentData: Identifiable, Sendable {
    let id: UUID
    let label: String
    let path: String
    var isEnabled: Bool

    init(id: UUID = UUID(), label: String, path: String, isEnabled: Bool) {
        self.id = id
        self.label = label
        self.path = path
        self.isEnabled = isEnabled
    }
}
