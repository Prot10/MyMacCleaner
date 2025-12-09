import Foundation

// MARK: - File Operations

/// Request to delete files at specified paths
public struct DeleteFilesRequest: Codable, Sendable {
    public let paths: [String]
    public let moveToTrash: Bool

    public init(paths: [String], moveToTrash: Bool = true) {
        self.paths = paths
        self.moveToTrash = moveToTrash
    }
}

/// Response from file deletion operation
public struct DeleteFilesResponse: Codable, Sendable {
    public let success: Bool
    public let deletedPaths: [String]
    public let failedPaths: [String: String] // path -> error message
    public let totalBytesFreed: Int64

    public init(
        success: Bool,
        deletedPaths: [String] = [],
        failedPaths: [String: String] = [:],
        totalBytesFreed: Int64 = 0
    ) {
        self.success = success
        self.deletedPaths = deletedPaths
        self.failedPaths = failedPaths
        self.totalBytesFreed = totalBytesFreed
    }
}

// MARK: - Memory Operations

/// Response from memory purge operation
public struct PurgeMemoryResponse: Codable, Sendable {
    public let success: Bool
    public let error: String?

    public init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

// MARK: - System Information

/// Response with system information
public struct SystemInfoResponse: Codable, Sendable {
    public let memoryTotal: UInt64
    public let memoryFree: UInt64
    public let memoryActive: UInt64
    public let memoryInactive: UInt64
    public let memoryWired: UInt64
    public let memoryCompressed: UInt64

    public init(
        memoryTotal: UInt64,
        memoryFree: UInt64,
        memoryActive: UInt64,
        memoryInactive: UInt64,
        memoryWired: UInt64,
        memoryCompressed: UInt64
    ) {
        self.memoryTotal = memoryTotal
        self.memoryFree = memoryFree
        self.memoryActive = memoryActive
        self.memoryInactive = memoryInactive
        self.memoryWired = memoryWired
        self.memoryCompressed = memoryCompressed
    }
}

// MARK: - Launch Item Management

/// Request to manage a launch item (LaunchAgent/LaunchDaemon)
public struct LaunchItemRequest: Codable, Sendable {
    public enum Action: String, Codable, Sendable {
        case enable
        case disable
        case remove
        case load
        case unload
    }

    public let path: String
    public let action: Action

    public init(path: String, action: Action) {
        self.path = path
        self.action = action
    }
}

/// Response from launch item management operation
public struct LaunchItemResponse: Codable, Sendable {
    public let success: Bool
    public let error: String?

    public init(success: Bool, error: String? = nil) {
        self.success = success
        self.error = error
    }
}

// MARK: - Path Validation

/// Request to validate paths before deletion
public struct ValidatePathsRequest: Codable, Sendable {
    public let paths: [String]

    public init(paths: [String]) {
        self.paths = paths
    }
}

/// Response from path validation
public struct ValidatePathsResponse: Codable, Sendable {
    public struct PathValidation: Codable, Sendable {
        public let path: String
        public let isValid: Bool
        public let reason: String?

        public init(path: String, isValid: Bool, reason: String? = nil) {
            self.path = path
            self.isValid = isValid
            self.reason = reason
        }
    }

    public let validations: [PathValidation]

    public init(validations: [PathValidation]) {
        self.validations = validations
    }

    public var allValid: Bool {
        validations.allSatisfy(\.isValid)
    }

    public var invalidPaths: [PathValidation] {
        validations.filter { !$0.isValid }
    }
}

// MARK: - Helper Status

/// Response with helper tool status
public struct HelperStatusResponse: Codable, Sendable {
    public let version: String
    public let isRunningAsRoot: Bool

    public init(version: String, isRunningAsRoot: Bool) {
        self.version = version
        self.isRunningAsRoot = isRunningAsRoot
    }
}
