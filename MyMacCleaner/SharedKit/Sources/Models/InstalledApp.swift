import Foundation

/// Represents an installed application
public struct InstalledApp: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let bundleIdentifier: String
    public let path: String
    public let version: String?
    public let sizeBytes: Int64
    public let iconData: Data?

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        path: String,
        version: String? = nil,
        sizeBytes: Int64,
        iconData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.version = version
        self.sizeBytes = sizeBytes
        self.iconData = iconData
    }

    /// Human-readable file size
    public var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    /// Extract developer name from bundle identifier
    /// e.g., "com.microsoft.Word" -> "microsoft"
    public var developerName: String? {
        let components = bundleIdentifier.split(separator: ".")
        guard components.count >= 2 else { return nil }
        return String(components[1])
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }

    public static func == (lhs: InstalledApp, rhs: InstalledApp) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
    }
}
