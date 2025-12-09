import Foundation
import AppKit

/// Manages permission states for the app (Full Disk Access, etc.)
@Observable
final class PermissionsService {
    private(set) var hasFullDiskAccess: Bool = false
    private(set) var lastChecked: Date?

    init() {
        checkPermissions()
    }

    // MARK: - Permission Checks

    /// Check all permissions
    func checkPermissions() {
        hasFullDiskAccess = checkFullDiskAccess()
        lastChecked = Date()
    }

    /// Check if the app has Full Disk Access
    private func checkFullDiskAccess() -> Bool {
        // Try to read a protected directory to check FDA status
        // ~/Library/Mail is protected and requires FDA
        let testPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/Mail")
        let fm = FileManager.default

        // If the directory doesn't exist, try another protected path
        if !fm.fileExists(atPath: testPath) {
            // Try Safari history as alternative
            let safariPath = (NSHomeDirectory() as NSString).appendingPathComponent("Library/Safari/History.db")
            return fm.isReadableFile(atPath: safariPath)
        }

        return fm.isReadableFile(atPath: testPath)
    }

    // MARK: - Request Permissions

    /// Show prompt to request Full Disk Access
    func requestFullDiskAccess() {
        let alert = NSAlert()
        alert.messageText = "Full Disk Access Required"
        alert.informativeText = """
            MyMacCleaner needs Full Disk Access to scan for leftover files and clean protected directories.

            Please grant access in System Settings > Privacy & Security > Full Disk Access.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            openFullDiskAccessSettings()
        }
    }

    /// Open System Settings to Full Disk Access pane
    func openFullDiskAccessSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }

    /// Open System Settings to Privacy & Security
    func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Automation Permission

    /// Check if we can send Apple Events to Finder (for moving to Trash)
    func checkAutomationPermission() -> Bool {
        // This would require sending a test Apple Event to Finder
        // For now, assume we have it until we fail
        return true
    }
}
