import SwiftUI
import AppKit

// MARK: - Applications View Model

@MainActor
class ApplicationsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var applications: [AppInfo] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var sortOrder: SortOrder = .name
    @Published var selectedApp: AppInfo?

    @Published var showUninstallConfirmation = false
    @Published var appToUninstall: AppInfo?
    @Published var relatedFiles: [URL] = []
    @Published var isScanning = false

    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case size = "Size"
        case date = "Date Added"
    }

    enum ToastType {
        case success, error, info
    }

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
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    // MARK: - Initialization

    init() {
        loadApplications()
    }

    // MARK: - Public Methods

    func loadApplications() {
        isLoading = true

        Task {
            let apps = await scanApplications()

            applications = apps
            isLoading = false
        }
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

    private func scanApplications() async -> [AppInfo] {
        var apps: [AppInfo] = []

        let applicationPaths = [
            "/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        for path in applicationPaths {
            let url = URL(fileURLWithPath: path)

            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .addedToDirectoryDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for itemURL in contents {
                guard itemURL.pathExtension == "app" else { continue }

                if let appInfo = await createAppInfo(from: itemURL) {
                    apps.append(appInfo)
                }
            }
        }

        return apps
    }

    private func createAppInfo(from url: URL) async -> AppInfo? {
        let name = url.deletingPathExtension().lastPathComponent

        // Get app icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)

        // Get bundle info
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String

        // Get size
        let size = await calculateDirectorySize(url)

        // Get dates
        let resourceValues = try? url.resourceValues(forKeys: [.contentModificationDateKey, .addedToDirectoryDateKey])
        let dateModified = resourceValues?.contentModificationDate
        let dateAdded = resourceValues?.addedToDirectoryDate

        return AppInfo(
            name: name,
            url: url,
            bundleId: bundleId,
            version: version,
            icon: icon,
            size: size,
            dateModified: dateModified,
            dateAdded: dateAdded
        )
    }

    private func calculateDirectorySize(_ url: URL) async -> Int64 {
        var totalSize: Int64 = 0

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .totalFileAllocatedSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .totalFileAllocatedSizeKey]) else {
                continue
            }

            totalSize += Int64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileSize ?? 0)
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
    let size: Int64
    let dateModified: Date?
    let dateAdded: Date?

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
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
