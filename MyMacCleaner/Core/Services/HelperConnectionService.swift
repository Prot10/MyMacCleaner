import Foundation
import AppKit
import ServiceManagement

/// Manages connection to the privileged helper tool via SMAppService
@Observable
final class HelperConnectionService {
    enum Status: Equatable {
        case notRegistered
        case requiresApproval
        case enabled
        case notFound
        case unknown
    }

    private(set) var status: Status = .unknown
    private(set) var lastError: String?

    private let daemonPlistName = "com.mymaccleaner.helper.plist"
    private let machServiceName = "com.mymaccleaner.helper"

    init() {
        updateStatus()
    }

    // MARK: - Status

    func updateStatus() {
        let service = SMAppService.daemon(plistName: daemonPlistName)
        switch service.status {
        case .notRegistered:
            status = .notRegistered
        case .enabled:
            status = .enabled
        case .requiresApproval:
            status = .requiresApproval
        case .notFound:
            status = .notFound
        @unknown default:
            status = .unknown
        }
    }

    // MARK: - Registration

    /// Register the helper daemon. User must approve in System Settings > Login Items
    func register() async throws {
        let service = SMAppService.daemon(plistName: daemonPlistName)

        do {
            try service.register()
            updateStatus()
        } catch {
            lastError = error.localizedDescription
            throw HelperError.registrationFailed(error.localizedDescription)
        }
    }

    /// Unregister the helper daemon
    func unregister() async throws {
        let service = SMAppService.daemon(plistName: daemonPlistName)

        do {
            try await service.unregister()
            updateStatus()
        } catch {
            lastError = error.localizedDescription
            throw HelperError.unregistrationFailed(error.localizedDescription)
        }
    }

    /// Open System Settings to the Login Items pane for user approval
    func openLoginItemsSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Helper Operations (Placeholder for SecureXPC integration)

    /// Check if the helper is ready for operations
    var isReady: Bool {
        status == .enabled
    }

    /// Delete files via the helper (requires helper to be enabled)
    func deleteFiles(_ paths: [String], moveToTrash: Bool = true) async throws -> DeleteFilesResult {
        guard isReady else {
            throw HelperError.notConnected
        }

        // TODO: Implement SecureXPC client call
        // For now, return a placeholder
        return DeleteFilesResult(
            success: false,
            deletedCount: 0,
            failedPaths: [:],
            bytesFreed: 0
        )
    }

    /// Purge memory via the helper (requires root)
    func purgeMemory() async throws -> Bool {
        guard isReady else {
            throw HelperError.notConnected
        }

        // TODO: Implement SecureXPC client call
        return false
    }

    /// Manage launch items via the helper
    func manageLaunchItem(at path: String, action: LaunchItemAction) async throws -> Bool {
        guard isReady else {
            throw HelperError.notConnected
        }

        // TODO: Implement SecureXPC client call
        return false
    }
}

// MARK: - Types

enum HelperError: LocalizedError {
    case notConnected
    case registrationFailed(String)
    case unregistrationFailed(String)
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Helper is not connected. Please enable it in System Settings > Login Items."
        case .registrationFailed(let message):
            return "Failed to register helper: \(message)"
        case .unregistrationFailed(let message):
            return "Failed to unregister helper: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}

struct DeleteFilesResult {
    let success: Bool
    let deletedCount: Int
    let failedPaths: [String: String]
    let bytesFreed: Int64
}

enum LaunchItemAction {
    case enable
    case disable
    case remove
}
