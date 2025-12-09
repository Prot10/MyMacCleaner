import Foundation

/// Memory statistics from the system
public struct MemoryStats: Codable, Sendable {
    public let free: UInt64
    public let active: UInt64
    public let inactive: UInt64
    public let wired: UInt64
    public let compressed: UInt64
    public let purgeable: UInt64
    public let speculative: UInt64
    public let total: UInt64

    public init(
        free: UInt64,
        active: UInt64,
        inactive: UInt64,
        wired: UInt64,
        compressed: UInt64,
        purgeable: UInt64 = 0,
        speculative: UInt64 = 0,
        total: UInt64
    ) {
        self.free = free
        self.active = active
        self.inactive = inactive
        self.wired = wired
        self.compressed = compressed
        self.purgeable = purgeable
        self.speculative = speculative
        self.total = total
    }

    /// Memory currently in use (active + wired + compressed)
    public var used: UInt64 {
        active + wired + compressed
    }

    /// Available memory (free + inactive + purgeable)
    public var available: UInt64 {
        free + inactive + purgeable
    }

    /// Usage percentage (0.0 to 1.0)
    public var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }

    /// Pressure level based on usage
    public var pressureLevel: MemoryPressureLevel {
        switch usagePercentage {
        case 0..<0.5: return .nominal
        case 0.5..<0.75: return .warning
        case 0.75..<0.9: return .critical
        default: return .critical
        }
    }

    public static let empty = MemoryStats(
        free: 0, active: 0, inactive: 0, wired: 0,
        compressed: 0, purgeable: 0, speculative: 0, total: 0
    )
}

public enum MemoryPressureLevel: String, Codable, Sendable {
    case nominal
    case warning
    case critical
}
