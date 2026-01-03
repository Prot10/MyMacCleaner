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
    case systemCache = "System Cache"
    case userCache = "User Cache"
    case applicationLogs = "Application Logs"
    case xcodeData = "Xcode Data"
    case browserCache = "Browser Cache"
    case trash = "Trash"
    case downloads = "Old Downloads"
    case mailAttachments = "Mail Attachments"

    var id: String { rawValue }

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
        }
    }

    var description: String {
        switch self {
        case .systemCache: return "System-level cached data"
        case .userCache: return "User application caches"
        case .applicationLogs: return "App crash reports and logs"
        case .xcodeData: return "DerivedData and build files"
        case .browserCache: return "Safari, Chrome, Firefox caches"
        case .trash: return "Items in your Trash"
        case .downloads: return "Files older than 30 days"
        case .mailAttachments: return "Downloaded email attachments"
        }
    }

    var requiresFullDiskAccess: Bool {
        switch self {
        case .systemCache, .applicationLogs, .mailAttachments:
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
        guard let date = modificationDate else { return "Unknown" }
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
