import Foundation
import SwiftUI

// MARK: - Permission Category Type

enum PermissionCategoryType: String, CaseIterable, Identifiable {
    case fullDiskAccess
    case userFolders
    case systemFolders
    case applicationData
    case startupPaths

    var id: String { rawValue }

    var localizedName: String {
        L("permissions.category.\(rawValue).name")
    }

    var localizedDescription: String {
        L("permissions.category.\(rawValue).description")
    }

    var icon: String {
        switch self {
        case .fullDiskAccess: return "lock.shield.fill"
        case .userFolders: return "folder.fill"
        case .systemFolders: return "gearshape.fill"
        case .applicationData: return "app.fill"
        case .startupPaths: return "power.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .fullDiskAccess: return .blue
        case .userFolders: return .green
        case .systemFolders: return .orange
        case .applicationData: return .purple
        case .startupPaths: return .yellow
        }
    }

    /// Whether this category can be managed via System Settings
    var requiresSystemSettings: Bool {
        self == .fullDiskAccess || self == .systemFolders
    }

    /// Whether this category uses TCC dialogs for individual folders
    var usesTCCDialogs: Bool {
        self == .userFolders
    }
}

// MARK: - Folder Access Status

enum FolderAccessStatus: Equatable {
    case accessible
    case denied
    case notExists
    case checking

    var color: Color {
        switch self {
        case .accessible: return .green
        case .denied: return .red
        case .notExists: return .gray
        case .checking: return .secondary
        }
    }

    var icon: String {
        switch self {
        case .accessible: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notExists: return "minus.circle.fill"
        case .checking: return "arrow.clockwise.circle"
        }
    }

    var localizedLabel: String {
        switch self {
        case .accessible: return L("permissions.folder.accessible")
        case .denied: return L("permissions.folder.denied")
        case .notExists: return L("permissions.folder.notExists")
        case .checking: return L("permissions.folder.checking")
        }
    }
}

// MARK: - Folder Access Info

struct FolderAccessInfo: Identifiable, Equatable {
    let id: UUID
    let path: String
    let displayName: String
    var status: FolderAccessStatus
    let requiresFDA: Bool
    let canTriggerTCCDialog: Bool

    init(
        path: String,
        displayName: String,
        status: FolderAccessStatus = .checking,
        requiresFDA: Bool = false,
        canTriggerTCCDialog: Bool = false
    ) {
        self.id = UUID()
        self.path = path
        self.displayName = displayName
        self.status = status
        self.requiresFDA = requiresFDA
        self.canTriggerTCCDialog = canTriggerTCCDialog
    }

    var expandedPath: String {
        (path as NSString).expandingTildeInPath
    }

    static func == (lhs: FolderAccessInfo, rhs: FolderAccessInfo) -> Bool {
        lhs.id == rhs.id &&
        lhs.path == rhs.path &&
        lhs.status == rhs.status
    }
}

// MARK: - Permission Category State

struct PermissionCategoryState: Identifiable {
    let id: UUID
    let type: PermissionCategoryType
    var folders: [FolderAccessInfo]
    var isExpanded: Bool

    init(type: PermissionCategoryType, folders: [FolderAccessInfo], isExpanded: Bool = false) {
        self.id = UUID()
        self.type = type
        self.folders = folders
        self.isExpanded = isExpanded
    }

    var overallStatus: FolderAccessStatus {
        let existingFolders = folders.filter { $0.status != .notExists }
        guard !existingFolders.isEmpty else { return .notExists }

        let statuses = existingFolders.map { $0.status }
        if statuses.allSatisfy({ $0 == .accessible }) {
            return .accessible
        } else if statuses.allSatisfy({ $0 == .denied }) {
            return .denied
        } else if statuses.contains(.checking) {
            return .checking
        } else {
            return .denied // Mixed means some denied
        }
    }

    var accessibleCount: Int {
        folders.filter { $0.status == .accessible }.count
    }

    var existingCount: Int {
        folders.filter { $0.status != .notExists }.count
    }

    var totalCount: Int {
        folders.count
    }

    var statusSummary: String {
        let accessible = accessibleCount
        let existing = existingCount
        if existing == 0 {
            return L("permissions.category.noFolders")
        }
        return "\(accessible)/\(existing)"
    }
}
