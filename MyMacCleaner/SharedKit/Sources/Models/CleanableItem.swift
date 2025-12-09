import Foundation

/// Represents a file or directory that can be cleaned
public struct CleanableItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public let path: String
    public let name: String
    public let sizeBytes: Int64
    public let category: CleanupCategory
    public let isSelected: Bool

    public init(
        id: UUID = UUID(),
        path: String,
        name: String,
        sizeBytes: Int64,
        category: CleanupCategory,
        isSelected: Bool = true
    ) {
        self.id = id
        self.path = path
        self.name = name
        self.sizeBytes = sizeBytes
        self.category = category
        self.isSelected = isSelected
    }

    /// Human-readable file size
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}

/// Categories of cleanable items
public enum CleanupCategory: String, Codable, Sendable, CaseIterable {
    case systemCaches = "System Caches"
    case userCaches = "User Caches"
    case logs = "Logs"
    case trash = "Trash"
    case xcodeDerivedData = "Xcode Derived Data"
    case xcodeArchives = "Xcode Archives"
    case xcodeDeviceSupport = "Xcode Device Support"
    case homebrew = "Homebrew Cache"
    case npm = "npm Cache"
    case pip = "pip Cache"
    case dockerImages = "Docker Images"
    case mailAttachments = "Mail Attachments"
    case safariCache = "Safari Cache"
    case spotlightIndex = "Spotlight Index"
    case applicationLeftovers = "Application Leftovers"

    public var systemImage: String {
        switch self {
        case .systemCaches, .userCaches: return "folder.badge.gearshape"
        case .logs: return "doc.text"
        case .trash: return "trash"
        case .xcodeDerivedData, .xcodeArchives, .xcodeDeviceSupport: return "hammer"
        case .homebrew: return "cup.and.saucer"
        case .npm: return "shippingbox"
        case .pip: return "shippingbox"
        case .dockerImages: return "shippingbox.fill"
        case .mailAttachments: return "paperclip"
        case .safariCache: return "safari"
        case .spotlightIndex: return "magnifyingglass"
        case .applicationLeftovers: return "app.badge.checkmark"
        }
    }

    public var isSafeToClean: Bool {
        switch self {
        case .mailAttachments, .spotlightIndex:
            return false // Requires user confirmation
        default:
            return true
        }
    }
}

/// Grouped cleanup results for display
public struct CleanupGroup: Identifiable, Sendable {
    public let id: UUID
    public let category: CleanupCategory
    public var items: [CleanableItem]

    public init(category: CleanupCategory, items: [CleanableItem]) {
        self.id = UUID()
        self.category = category
        self.items = items
    }

    public var totalSize: Int64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }

    public var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    public var selectedCount: Int {
        items.filter(\.isSelected).count
    }
}
