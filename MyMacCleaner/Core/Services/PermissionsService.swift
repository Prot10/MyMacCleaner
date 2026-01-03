import Foundation
import AppKit
import SwiftUI

// MARK: - Permissions Service

@MainActor
class PermissionsService: ObservableObject {
    static let shared = PermissionsService()

    @Published var hasFullDiskAccess: Bool = false
    @Published var isCheckingPermissions: Bool = false

    private init() {
        checkFullDiskAccess()
    }

    // MARK: - Full Disk Access

    /// Check if the app has Full Disk Access permission
    func checkFullDiskAccess() {
        isCheckingPermissions = true

        // Test by trying to read a protected file
        // Safari's bookmarks is a common test file
        let testPaths = [
            NSHomeDirectory() + "/Library/Safari/Bookmarks.plist",
            NSHomeDirectory() + "/Library/Safari/CloudTabs.db",
            "/Library/Application Support/com.apple.TCC/TCC.db"
        ]

        var hasAccess = false

        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                hasAccess = true
                break
            }
        }

        // Alternative: try to list contents of a protected directory
        if !hasAccess {
            let protectedURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Mail")
            do {
                _ = try FileManager.default.contentsOfDirectory(at: protectedURL, includingPropertiesForKeys: nil)
                hasAccess = true
            } catch {
                // Access denied
            }
        }

        hasFullDiskAccess = hasAccess
        isCheckingPermissions = false
    }

    /// Open System Preferences to Full Disk Access pane
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Open System Preferences to Automation pane
    func openAutomationSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Permission Descriptions

    struct PermissionInfo {
        let name: String
        let description: String
        let isRequired: Bool
        let features: [String]
    }

    static let fullDiskAccessInfo = PermissionInfo(
        name: "Full Disk Access",
        description: "Allows scanning system caches, logs, and application data for cleanup.",
        isRequired: false,
        features: [
            "Scan system caches",
            "Scan application logs",
            "Detect app leftovers during uninstall",
            "Access Mail attachments",
            "Complete Space Lens visualization"
        ]
    )
}

// MARK: - Permission Status

enum PermissionStatus {
    case granted
    case denied
    case notDetermined
    case restricted

    var color: Color {
        switch self {
        case .granted: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        case .restricted: return .gray
        }
    }

    var icon: String {
        switch self {
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        case .restricted: return "lock.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .granted: return "Granted"
        case .denied: return "Not Granted"
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        }
    }
}
