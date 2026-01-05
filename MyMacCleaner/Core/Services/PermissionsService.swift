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
    /// Uses safe test paths that don't trigger TCC prompts for other permissions
    func checkFullDiskAccess() {
        isCheckingPermissions = true

        // Test by trying to read protected files that ONLY require FDA
        // These paths don't trigger separate TCC prompts (like Downloads, Music, Desktop, Documents)
        //
        // IMPORTANT: The paths we test here:
        // - ~/Library/Safari/* - Requires FDA, fails silently without it
        // - ~/Library/Mail - Requires FDA, fails silently without it
        //
        // Paths we DON'T use:
        // - /Library/Application Support/com.apple.TCC/TCC.db - Requires ROOT, not just FDA
        // - ~/Downloads, ~/Desktop, ~/Documents - These trigger TCC prompts!
        // - ~/Music - Triggers Apple Music TCC prompt!

        let testPaths = [
            NSHomeDirectory() + "/Library/Safari/Bookmarks.plist",
            NSHomeDirectory() + "/Library/Safari/CloudTabs.db"
        ]

        var hasAccess = false

        // First, try to read Safari files (these require FDA but don't trigger prompts)
        for path in testPaths {
            if FileManager.default.isReadableFile(atPath: path) {
                hasAccess = true
                break
            }
        }

        // Fallback: Try to list contents of ~/Library/Mail
        // This directory requires FDA but does NOT trigger a TCC prompt
        // (unlike Downloads, Documents, Desktop which DO trigger prompts)
        if !hasAccess {
            let mailURL = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Mail")
            do {
                _ = try FileManager.default.contentsOfDirectory(at: mailURL, includingPropertiesForKeys: nil)
                hasAccess = true
            } catch {
                // Access denied - FDA not granted
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
