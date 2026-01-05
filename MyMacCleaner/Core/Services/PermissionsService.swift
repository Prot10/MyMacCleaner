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
    /// Tests multiple FDA-protected paths to reliably detect permission status
    func checkFullDiskAccess() {
        isCheckingPermissions = true

        var hasAccess = false

        // Method 1: Try to read the user's TCC database (most reliable)
        let tccPath = NSHomeDirectory() + "/Library/Application Support/com.apple.TCC/TCC.db"
        if FileManager.default.isReadableFile(atPath: tccPath) {
            hasAccess = true
        }

        // Method 2: Try Safari bookmarks
        if !hasAccess {
            let safariPath = NSHomeDirectory() + "/Library/Safari/Bookmarks.plist"
            if FileManager.default.fileExists(atPath: safariPath) &&
               FileManager.default.isReadableFile(atPath: safariPath) {
                hasAccess = true
            }
        }

        // Method 3: Try to list ~/Library/Mail contents
        if !hasAccess {
            let mailPath = NSHomeDirectory() + "/Library/Mail"
            if FileManager.default.fileExists(atPath: mailPath) {
                do {
                    _ = try FileManager.default.contentsOfDirectory(atPath: mailPath)
                    hasAccess = true
                } catch {
                    // Access denied
                }
            }
        }

        // Method 4: Try to actually READ a protected file (not just check isReadableFile)
        if !hasAccess {
            let safariPath = NSHomeDirectory() + "/Library/Safari/Bookmarks.plist"
            do {
                _ = try Data(contentsOf: URL(fileURLWithPath: safariPath))
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

        var localizedFeatures: [String] {
            [
                L("permissions.fda.feature.systemCaches"),
                L("permissions.fda.feature.appLogs"),
                L("permissions.fda.feature.leftovers"),
                L("permissions.fda.feature.mailAttachments"),
                L("permissions.fda.feature.spaceLens")
            ]
        }
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
        case .granted: return L("permissions.status.granted")
        case .denied: return L("permissions.status.denied")
        case .notDetermined: return L("permissions.status.notDetermined")
        case .restricted: return L("permissions.status.restricted")
        }
    }
}
