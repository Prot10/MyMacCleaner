import Foundation
import SwiftUI

// MARK: - Scan Result

struct ScanResult: Identifiable {
    let id = UUID()
    let category: ScanCategory
    var items: [CleanableItem]
    var isSelected: Bool = true

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var itemCount: Int {
        items.count
    }
}

// MARK: - Scan Category

enum ScanCategory: String, CaseIterable, Identifiable {
    case systemCache
    case userCache
    case applicationLogs
    case xcodeData
    case browserCache
    case trash
    case downloads
    case mailAttachments
    // Developer tools
    case npmCache
    case yarnCache
    case cocoapodsCache
    case homebrewCache
    // Containers & Simulators
    case dockerData
    case iosSimulators
    case iosBackups

    var id: String { rawValue }

    var localizedName: String {
        L(key: "category.\(rawValue).name")
    }

    var localizedDescription: String {
        L(key: "category.\(rawValue).description")
    }

    var icon: String {
        switch self {
        case .systemCache: return "gearshape.fill"
        case .userCache: return "person.fill"
        case .applicationLogs: return "doc.text.fill"
        case .xcodeData: return "hammer.fill"
        case .browserCache: return "globe"
        case .trash: return "trash.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .mailAttachments: return "paperclip"
        case .npmCache: return "shippingbox.fill"
        case .yarnCache: return "link"
        case .cocoapodsCache: return "cube.fill"
        case .homebrewCache: return "mug.fill"
        case .dockerData: return "tray.2.fill"
        case .iosSimulators: return "iphone"
        case .iosBackups: return "externaldrive.fill"
        }
    }

    var color: Color {
        switch self {
        case .systemCache: return .blue
        case .userCache: return .purple
        case .applicationLogs: return .orange
        case .xcodeData: return .pink
        case .browserCache: return .cyan
        case .trash: return .red
        case .downloads: return .green
        case .mailAttachments: return .yellow
        case .npmCache: return .mint
        case .yarnCache: return .indigo
        case .cocoapodsCache: return .brown
        case .homebrewCache: return .teal
        case .dockerData: return Color(red: 0.13, green: 0.59, blue: 0.95) // Docker blue
        case .iosSimulators: return .gray
        case .iosBackups: return Color(red: 0.6, green: 0.4, blue: 0.8) // Purple-ish
        }
    }

    /// Legacy description for compatibility - use localizedDescription instead
    var description: String {
        localizedDescription
    }

    var requiresFullDiskAccess: Bool {
        switch self {
        case .systemCache, .applicationLogs, .mailAttachments:
            return true
        case .iosBackups:
            // iOS backups in MobileSync may require FDA
            return true
        default:
            return false
        }
    }

    /// Whether this category requires explicit user consent before scanning
    /// These directories are TCC-protected and will trigger system permission dialogs
    var requiresUserConsent: Bool {
        switch self {
        case .downloads, .mailAttachments:
            return true
        case .iosBackups:
            // iOS backups contain personal data
            return true
        default:
            return false
        }
    }

    var paths: [String] {
        let home = NSHomeDirectory()
        switch self {
        case .systemCache:
            return ["/Library/Caches"]
        case .userCache:
            return ["\(home)/Library/Caches"]
        case .applicationLogs:
            return [
                "\(home)/Library/Logs",
                "/Library/Logs"
            ]
        case .xcodeData:
            return [
                "\(home)/Library/Developer/Xcode/DerivedData",
                "\(home)/Library/Developer/Xcode/Archives",
                "\(home)/Library/Developer/CoreSimulator/Caches"
            ]
        case .browserCache:
            return [
                "\(home)/Library/Caches/com.apple.Safari",
                "\(home)/Library/Caches/Google/Chrome",
                "\(home)/Library/Caches/Firefox"
            ]
        case .trash:
            return ["\(home)/.Trash"]
        case .downloads:
            return ["\(home)/Downloads"]
        case .mailAttachments:
            return ["\(home)/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"]
        case .npmCache:
            return ["\(home)/.npm"]
        case .yarnCache:
            return [
                "\(home)/.yarn/cache",
                "\(home)/.cache/yarn"
            ]
        case .cocoapodsCache:
            return ["\(home)/Library/Caches/CocoaPods"]
        case .homebrewCache:
            return ["\(home)/Library/Caches/Homebrew"]
        case .dockerData:
            return ["\(home)/Library/Containers/com.docker.docker/Data"]
        case .iosSimulators:
            return [
                "\(home)/Library/Developer/CoreSimulator/Devices",
                "\(home)/Library/Developer/CoreSimulator/Caches"
            ]
        case .iosBackups:
            return ["\(home)/Library/Application Support/MobileSync/Backup"]
        }
    }
}

// MARK: - Cleanable Item

struct CleanableItem: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let modificationDate: Date?
    let category: ScanCategory
    var isSelected: Bool = true

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedDate: String {
        guard let date = modificationDate else { return L("common.unknown") }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Scan Summary

struct ScanSummary {
    let totalSize: Int64
    let categoryBreakdown: [ScanCategory: Int64]
    let itemCount: Int
    let scanDuration: TimeInterval

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var largestCategory: ScanCategory? {
        categoryBreakdown.max(by: { $0.value < $1.value })?.key
    }
}
