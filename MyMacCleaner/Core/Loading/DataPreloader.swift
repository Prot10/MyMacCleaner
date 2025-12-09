import Foundation
import SwiftUI

// MARK: - Data Preloader

/// Service responsible for preloading all app data in the background on launch
/// Uses Swift Concurrency with TaskGroup for parallel loading
@Observable
final class DataPreloader {
    private let systemStatsRepo = SystemStatsRepository()
    private(set) var loadingState = PageLoadingState()
    private(set) var isPreloading = false
    private(set) var currentLoadingMessage: String = ""

    // MARK: - Preload All Data

    /// Starts background preloading of all page data
    /// Called once when the app launches
    @MainActor
    func startPreloading(toastManager: ToastManager? = nil) async {
        guard !isPreloading else { return }
        isPreloading = true

        // Load pages in parallel using TaskGroup
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.preloadDashboard(toastManager: toastManager) }
            group.addTask { await self.preloadCleaner(toastManager: toastManager) }
            group.addTask { await self.preloadUninstaller(toastManager: toastManager) }
            group.addTask { await self.preloadOptimizer(toastManager: toastManager) }
        }

        isPreloading = false
    }

    // MARK: - Individual Page Preloaders

    @MainActor
    private func preloadDashboard(toastManager: ToastManager? = nil) async {
        loadingState.dashboard = .loading

        // Progressive loading: First load quick stats
        let memoryStats = systemStatsRepo.getMemoryStats()
        let diskUsage = systemStatsRepo.getDiskUsage()
        let cpuUsage = systemStatsRepo.getCPUUsage()

        // Update immediately with basic stats
        let partialData = DashboardData(
            memoryStats: memoryStats,
            diskUsage: diskUsage,
            cpuUsage: cpuUsage,
            diskCategories: nil
        )
        loadingState.dashboard = .loaded(partialData)
        toastManager?.showLoading("Analyzing system stats...")

        // Then load slower disk categories
        let diskCategories = await systemStatsRepo.getDiskUsageBreakdown()

        let fullData = DashboardData(
            memoryStats: memoryStats,
            diskUsage: diskUsage,
            cpuUsage: cpuUsage,
            diskCategories: diskCategories
        )
        loadingState.dashboard = .loaded(fullData)
    }

    @MainActor
    private func preloadCleaner(toastManager: ToastManager? = nil) async {
        loadingState.cleaner = .loading
        toastManager?.showLoading("Scanning cleanup categories...")

        // Progressive loading: scan categories one by one
        let categories = await scanCleanupCategoriesProgressively()
        loadingState.cleaner = .loaded(CleanerData(categories: categories))
    }

    @MainActor
    private func preloadUninstaller(toastManager: ToastManager? = nil) async {
        loadingState.uninstaller = .loading
        toastManager?.showLoading("Loading installed applications...")

        let apps = await loadInstalledApps()
        loadingState.uninstaller = .loaded(UninstallerData(apps: apps))
    }

    @MainActor
    private func preloadOptimizer(toastManager: ToastManager? = nil) async {
        loadingState.optimizer = .loading
        toastManager?.showLoading("Analyzing system optimization...")

        let memoryStats = systemStatsRepo.getMemoryStats()
        let agents = await loadLaunchAgents()
        loadingState.optimizer = .loaded(OptimizerData(
            memoryStats: memoryStats,
            launchAgents: agents
        ))
    }

    // MARK: - Data Scanning Helpers

    /// Progressive scanning that yields results as they're found
    private func scanCleanupCategoriesProgressively() async -> [CleanerCategoryData] {
        let home = NSHomeDirectory()
        let fm = FileManager.default

        let categoryDefinitions: [(name: String, icon: String, paths: [String])] = [
            ("System Caches", "folder.badge.gearshape", [
                "\(home)/Library/Caches"
            ]),
            ("Application Logs", "doc.text", [
                "\(home)/Library/Logs"
            ]),
            ("Xcode Derived Data", "hammer", [
                "\(home)/Library/Developer/Xcode/DerivedData"
            ]),
            ("Homebrew Cache", "shippingbox", [
                "\(home)/Library/Caches/Homebrew"
            ]),
            ("npm Cache", "cube.box", [
                "\(home)/.npm/_cacache"
            ]),
            ("Trash", "trash", [
                "\(home)/.Trash"
            ])
        ]

        var results: [CleanerCategoryData] = []

        for def in categoryDefinitions {
            var totalSize: Int64 = 0
            var itemCount = 0

            for path in def.paths {
                if fm.fileExists(atPath: path) {
                    if let (size, count) = try? await calculateDirectoryInfoFast(at: path) {
                        totalSize += size
                        itemCount += count
                    }
                }
            }

            results.append(CleanerCategoryData(
                name: def.name,
                icon: def.icon,
                paths: def.paths,
                sizeBytes: totalSize,
                itemCount: itemCount
            ))

            // Yield after each category for responsiveness
            await Task.yield()
        }

        return results
    }

    /// Faster directory size calculation (limits depth for speed)
    private func calculateDirectoryInfoFast(at path: String) async throws -> (Int64, Int) {
        let fm = FileManager.default
        var totalSize: Int64 = 0
        var count = 0

        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return (0, 0)
        }

        // Limit to first 500 items for speed during initial load
        let maxItems = 500
        for case let fileURL as URL in enumerator {
            guard count < maxItems else { break }

            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               let isDirectory = values.isDirectory,
               !isDirectory,
               let size = values.fileSize {
                totalSize += Int64(size)
                count += 1
            }

            if count % 50 == 0 {
                await Task.yield()
            }
        }

        return (totalSize, count)
    }

    private func scanCleanupCategories() async -> [CleanerCategoryData] {
        let home = NSHomeDirectory()
        let fm = FileManager.default

        let categoryDefinitions: [(name: String, icon: String, paths: [String])] = [
            ("System Caches", "folder.badge.gearshape", [
                "\(home)/Library/Caches"
            ]),
            ("Application Logs", "doc.text", [
                "\(home)/Library/Logs"
            ]),
            ("Xcode Derived Data", "hammer", [
                "\(home)/Library/Developer/Xcode/DerivedData"
            ]),
            ("Homebrew Cache", "shippingbox", [
                "\(home)/Library/Caches/Homebrew"
            ]),
            ("npm Cache", "cube.box", [
                "\(home)/.npm/_cacache"
            ]),
            ("Trash", "trash", [
                "\(home)/.Trash"
            ])
        ]

        var results: [CleanerCategoryData] = []

        for def in categoryDefinitions {
            var totalSize: Int64 = 0
            var itemCount = 0

            for path in def.paths {
                if fm.fileExists(atPath: path) {
                    if let (size, count) = try? await calculateDirectoryInfo(at: path) {
                        totalSize += size
                        itemCount += count
                    }
                }
            }

            results.append(CleanerCategoryData(
                name: def.name,
                icon: def.icon,
                paths: def.paths,
                sizeBytes: totalSize,
                itemCount: itemCount
            ))
        }

        return results
    }

    private func calculateDirectoryInfo(at path: String) async throws -> (Int64, Int) {
        let fm = FileManager.default
        var totalSize: Int64 = 0
        var count = 0

        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return (0, 0)
        }

        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               let isDirectory = values.isDirectory,
               !isDirectory,
               let size = values.fileSize {
                totalSize += Int64(size)
                count += 1
            }

            // Yield to prevent blocking
            if count % 100 == 0 {
                await Task.yield()
            }
        }

        return (totalSize, count)
    }

    private func loadInstalledApps() async -> [AppInfo] {
        let fm = FileManager.default
        let applicationsPath = "/Applications"

        var apps: [AppInfo] = []

        do {
            let contents = try fm.contentsOfDirectory(atPath: applicationsPath)

            for item in contents where item.hasSuffix(".app") {
                let appPath = (applicationsPath as NSString).appendingPathComponent(item)
                let plistPath = (appPath as NSString).appendingPathComponent("Contents/Info.plist")

                if let plist = NSDictionary(contentsOfFile: plistPath),
                   let bundleId = plist["CFBundleIdentifier"] as? String {
                    let name = (item as NSString).deletingPathExtension
                    let size = (try? await calculateDirectoryInfo(at: appPath).0) ?? 0

                    apps.append(AppInfo(
                        name: name,
                        bundleId: bundleId,
                        path: appPath,
                        sizeBytes: size
                    ))
                }

                // Yield periodically
                await Task.yield()
            }
        } catch {
            // Ignore errors, return what we have
        }

        return apps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private func loadLaunchAgents() async -> [LaunchAgentData] {
        let fm = FileManager.default
        let home = NSHomeDirectory()

        let paths = [
            "\(home)/Library/LaunchAgents",
            "/Library/LaunchAgents"
        ]

        var agents: [LaunchAgentData] = []

        for basePath in paths {
            guard fm.fileExists(atPath: basePath) else { continue }

            do {
                let contents = try fm.contentsOfDirectory(atPath: basePath)
                for item in contents where item.hasSuffix(".plist") {
                    let fullPath = (basePath as NSString).appendingPathComponent(item)

                    if let plist = NSDictionary(contentsOfFile: fullPath),
                       let label = plist["Label"] as? String {
                        let disabled = plist["Disabled"] as? Bool ?? false

                        agents.append(LaunchAgentData(
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

        return agents.sorted { $0.label.localizedCompare($1.label) == .orderedAscending }
    }

    // MARK: - Refresh Individual Pages

    @MainActor
    func refreshDashboard() async {
        await preloadDashboard()
    }

    @MainActor
    func refreshCleaner() async {
        await preloadCleaner()
    }

    @MainActor
    func refreshUninstaller() async {
        await preloadUninstaller()
    }

    @MainActor
    func refreshOptimizer() async {
        await preloadOptimizer()
    }
}
