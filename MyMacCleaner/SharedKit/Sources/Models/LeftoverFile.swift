import Foundation

/// Represents a leftover file from an uninstalled application
public struct LeftoverFile: Identifiable, Codable, Sendable {
    public let id: UUID
    public let path: String
    public let sizeBytes: Int64
    public let category: LeftoverCategory
    public let confidence: LeftoverConfidence
    public let relatedBundleId: String?

    public init(
        id: UUID = UUID(),
        path: String,
        sizeBytes: Int64,
        category: LeftoverCategory,
        confidence: LeftoverConfidence,
        relatedBundleId: String? = nil
    ) {
        self.id = id
        self.path = path
        self.sizeBytes = sizeBytes
        self.category = category
        self.confidence = confidence
        self.relatedBundleId = relatedBundleId
    }

    /// Human-readable file size
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    /// File/folder name extracted from path
    public var name: String {
        (path as NSString).lastPathComponent
    }

    /// Parent directory path
    public var parentPath: String {
        (path as NSString).deletingLastPathComponent
    }
}

/// Categories of leftover files
public enum LeftoverCategory: String, Codable, Sendable {
    case cache = "Cache"
    case preferences = "Preferences"
    case applicationSupport = "Application Support"
    case container = "Container"
    case logs = "Logs"
    case launchItem = "Launch Item"
    case cookies = "Cookies"
    case savedState = "Saved State"
    case webkit = "WebKit Data"
    case crashReports = "Crash Reports"
    case other = "Other"

    public var systemImage: String {
        switch self {
        case .cache: return "folder.badge.gearshape"
        case .preferences: return "gearshape"
        case .applicationSupport: return "folder"
        case .container: return "shippingbox"
        case .logs: return "doc.text"
        case .launchItem: return "play.circle"
        case .cookies: return "doc.badge.clock"
        case .savedState: return "bookmark"
        case .webkit: return "safari"
        case .crashReports: return "exclamationmark.triangle"
        case .other: return "questionmark.folder"
        }
    }
}

/// Confidence level for leftover detection
public enum LeftoverConfidence: String, Codable, Sendable, Comparable {
    case high = "High"      // Exact bundle ID match
    case medium = "Medium"  // App name match
    case low = "Low"        // Fuzzy/developer name match

    public var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "orange"
        case .low: return "red"
        }
    }

    public var description: String {
        switch self {
        case .high: return "Exact match - safe to remove"
        case .medium: return "Likely match - review recommended"
        case .low: return "Possible match - verify before removing"
        }
    }

    public static func < (lhs: LeftoverConfidence, rhs: LeftoverConfidence) -> Bool {
        let order: [LeftoverConfidence] = [.low, .medium, .high]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

/// Result of leftover scanning for an app
public struct LeftoverScanResult: Sendable {
    public let app: InstalledApp
    public let leftovers: [LeftoverFile]
    public let totalSize: Int64

    public init(app: InstalledApp, leftovers: [LeftoverFile]) {
        self.app = app
        self.leftovers = leftovers
        self.totalSize = leftovers.reduce(0) { $0 + $1.sizeBytes }
    }

    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    public var highConfidenceLeftovers: [LeftoverFile] {
        leftovers.filter { $0.confidence == .high }
    }

    public var mediumConfidenceLeftovers: [LeftoverFile] {
        leftovers.filter { $0.confidence == .medium }
    }

    public var lowConfidenceLeftovers: [LeftoverFile] {
        leftovers.filter { $0.confidence == .low }
    }
}
