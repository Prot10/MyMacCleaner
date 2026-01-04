import SwiftUI
import AppKit

// MARK: - Applications View Model

@MainActor
class ApplicationsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var applications: [AppInfo] = []
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .name
    @Published var selectedApp: AppInfo?

    // Scan states
    @Published var discoveryState: DiscoveryState = .idle
    @Published var analysisState: AnalysisState = .idle
    @Published var analysisProgress: Double = 0
    @Published var currentAppBeingAnalyzed: String = ""

    // Uninstall
    @Published var showUninstallConfirmation = false
    @Published var appToUninstall: AppInfo?
    @Published var relatedFiles: [URL] = []
    @Published var isScanning = false

    // Toast
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    enum DiscoveryState {
        case idle
        case discovering
        case completed
    }

    enum AnalysisState {
        case idle
        case analyzing
        case completed
    }

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case date = "Date Added"
    }

    enum ToastType {
        case success, error, info
    }

    // MARK: - Private Properties

    private var discoveryTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?

    // MARK: - Computed Properties

    var filteredApps: [AppInfo] {
        var apps = applications

        if !searchText.isEmpty {
            apps = apps.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .name:
            apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            apps.sort { $0.size > $1.size }
        case .date:
            apps.sort { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
        }

        return apps
    }

    var totalSize: Int64 {
        applications.reduce(0) { $0 + $1.size }
    }

    var formattedTotalSize: String {
        if analysisState == .completed {
            return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        } else {
            return "—"
        }
    }

    var appsWithSizeCalculated: Int {
        applications.filter { $0.sizeCalculated }.count
    }

    var isAnalyzing: Bool {
        analysisState == .analyzing
    }

    var hasStartedDiscovery: Bool {
        discoveryState != .idle
    }

    // MARK: - Initialization

    init() {
        // Don't auto-start - will be triggered by view
    }

    // MARK: - Public Methods

    /// Start low-priority background discovery (just find apps, no size calculation)
    func startBackgroundDiscovery() {
        guard discoveryState == .idle else { return }

        discoveryState = .discovering

        discoveryTask = Task(priority: .background) {
            await discoverApplications()

            await MainActor.run {
                discoveryState = .completed
            }
        }
    }

    /// Start full analysis with size calculation (user-initiated, higher priority)
    func startFullAnalysis() {
        guard analysisState == .idle else { return }

        // If discovery hasn't finished, wait for it
        if discoveryState == .discovering {
            // Cancel low-priority discovery and restart with high priority
            discoveryTask?.cancel()
        }

        analysisState = .analyzing
        analysisProgress = 0

        analysisTask = Task(priority: .userInitiated) {
            // If we don't have apps yet, discover them first
            if applications.isEmpty {
                await discoverApplications()
            }

            // Now calculate sizes for all apps
            await calculateAllSizes()

            await MainActor.run {
                discoveryState = .completed
                analysisState = .completed
            }
        }
    }

    func refresh() {
        // Reset states
        discoveryTask?.cancel()
        analysisTask?.cancel()

        applications = []
        discoveryState = .idle
        analysisState = .idle
        analysisProgress = 0

        // Restart
        startBackgroundDiscovery()
    }

    func prepareUninstall(_ app: AppInfo) {
        appToUninstall = app
        isScanning = true

        Task {
            relatedFiles = await findRelatedFiles(for: app)
            isScanning = false
            showUninstallConfirmation = true
        }
    }

    func confirmUninstall() {
        guard let app = appToUninstall else { return }

        Task {
            do {
                // Move app to trash
                try FileManager.default.trashItem(at: app.url, resultingItemURL: nil)

                // Move related files to trash
                for file in relatedFiles {
                    try? FileManager.default.trashItem(at: file, resultingItemURL: nil)
                }

                // Remove from list
                applications.removeAll { $0.id == app.id }

                showUninstallConfirmation = false
                appToUninstall = nil
                relatedFiles = []

                showToastMessage("\(app.name) uninstalled successfully", type: .success)

            } catch {
                showToastMessage("Failed to uninstall: \(error.localizedDescription)", type: .error)
            }
        }
    }

    func cancelUninstall() {
        showUninstallConfirmation = false
        appToUninstall = nil
        relatedFiles = []
    }

    func revealInFinder(_ app: AppInfo) {
        NSWorkspace.shared.selectFile(app.url.path, inFileViewerRootedAtPath: app.url.deletingLastPathComponent().path)
    }

    func openApp(_ app: AppInfo) {
        NSWorkspace.shared.open(app.url)
    }

    func dismissToast() {
        showToast = false
    }

    // MARK: - Private Methods

    /// Quick discovery - just find apps without calculating sizes
    private func discoverApplications() async {
        let applicationPaths = [
            "/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for path in applicationPaths {
            let url = URL(fileURLWithPath: path)

            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.contentModificationDateKey, .addedToDirectoryDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents {
                // Check if cancelled
                if Task.isCancelled { return }

                guard itemURL.pathExtension == "app" else { continue }

                if let appInfo = await createAppInfoQuick(from: itemURL) {
                    await MainActor.run {
                        // Only add if not already present
                        if !applications.contains(where: { $0.url == appInfo.url }) {
                            applications.append(appInfo)
                        }
                    }
                }

                // Small yield to keep UI responsive
                await Task.yield()
            }
        }
    }

    /// Quick app info - just basic info, no size calculation
    private func createAppInfoQuick(from url: URL) async -> AppInfo? {
        let name = url.deletingPathExtension().lastPathComponent

        // Get app icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)

        // Get bundle info
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String

        // Get dates (quick)
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .addedToDirectoryDateKey])
        let dateModified = resourceValues?.contentModificationDate
        let dateAdded = resourceValues?.addedToDirectoryDate

        return AppInfo(
            name: name,
            url: url,
            bundleId: bundleId,
            version: version,
            icon: icon,
            size: 0, // Not calculated yet
            sizeCalculated: false,
            dateModified: dateModified,
            dateAdded: dateAdded
        )
    }

    /// Calculate sizes for all apps
    private func calculateAllSizes() async {
        let totalApps = applications.count
        guard totalApps > 0 else { return }

        for (index, app) in applications.enumerated() {
            if Task.isCancelled { return }

            await MainActor.run {
                currentAppBeingAnalyzed = app.name
                analysisProgress = Double(index) / Double(totalApps)
            }

            // Calculate size
            let size = await calculateDirectorySize(app.url)

            await MainActor.run {
                if let appIndex = applications.firstIndex(where: { $0.id == app.id }) {
                    applications[appIndex].size = size
                    applications[appIndex].sizeCalculated = true
                }
            }
        }

        await MainActor.run {
            analysisProgress = 1.0
            currentAppBeingAnalyzed = ""
        }
    }

    private func calculateDirectorySize(_ url: URL) async -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var fileCount = 0
        for case let fileURL as URL in enumerator {
            if Task.isCancelled { return totalSize }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey]) else {
                continue
            }

            totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)

            // Yield occasionally to keep responsive
            fileCount += 1
            if fileCount % 100 == 0 {
                await Task.yield()
            }
        }

        return totalSize
    }

    private func findRelatedFiles(for app: AppInfo) async -> [URL] {
        var relatedFiles: [URL] = []

        guard let bundleId = app.bundleId else { return relatedFiles }

        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        // Common locations for app-related files
        let searchPaths: [(URL, String)] = [
            (homeDir.appendingPathComponent("Library/Application Support"), bundleId),
            (homeDir.appendingPathComponent("Library/Application Support"), app.name),
            (homeDir.appendingPathComponent("Library/Preferences"), bundleId),
            (homeDir.appendingPathComponent("Library/Caches"), bundleId),
            (homeDir.appendingPathComponent("Library/Caches"), app.name),
            (homeDir.appendingPathComponent("Library/Logs"), bundleId),
            (homeDir.appendingPathComponent("Library/Logs"), app.name),
            (homeDir.appendingPathComponent("Library/Containers"), bundleId),
            (homeDir.appendingPathComponent("Library/Group Containers"), bundleId),
            (homeDir.appendingPathComponent("Library/Saved Application State"), "\(bundleId).savedState"),
            (homeDir.appendingPathComponent("Library/WebKit"), bundleId),
        ]

        for (basePath, searchTerm) in searchPaths {
            // Check for exact match
            let exactPath = basePath.appendingPathComponent(searchTerm)
            if FileManager.default.fileExists(atPath: exactPath.path) {
                relatedFiles.append(exactPath)
            }

            // Check for plist files
            if basePath.lastPathComponent == "Preferences" {
                let plistPath = basePath.appendingPathComponent("\(searchTerm).plist")
                if FileManager.default.fileExists(atPath: plistPath.path) {
                    relatedFiles.append(plistPath)
                }
            }
        }

        return relatedFiles
    }

    private func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }
}

// MARK: - App Info Model

struct AppInfo: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let url: URL
    let bundleId: String?
    let version: String?
    let icon: NSImage
    var size: Int64
    var sizeCalculated: Bool
    let dateModified: Date?
    let dateAdded: Date?

    var formattedSize: String {
        if sizeCalculated {
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        } else {
            return "—"
        }
    }

    var formattedDate: String {
        guard let date = dateAdded ?? dateModified else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}
