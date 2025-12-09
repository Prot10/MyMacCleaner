import Foundation
import SwiftUI

@Observable
final class CleanerViewModel {
    var categories: [CleanerCategory] = []
    var isScanning = false
    var isCleaning = false

    var totalSelectedSize: Int64 {
        categories.filter(\.isSelected).reduce(0) { $0 + $1.sizeBytes }
    }

    /// Initialize with preloaded data if available
    @MainActor
    func loadData(from preloadedData: CleanerData?) {
        if let data = preloadedData {
            // Convert preloaded CleanerCategoryData to CleanerCategory
            categories = data.categories.map { categoryData in
                CleanerCategory(
                    name: categoryData.name,
                    icon: categoryData.icon,
                    color: colorForCategory(categoryData.name),
                    sizeBytes: categoryData.sizeBytes,
                    itemCount: categoryData.itemCount
                )
            }
        }
    }

    private func colorForCategory(_ name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("cache"): return .cleanBlue
        case let n where n.contains("log"): return .cleanOrange
        case let n where n.contains("xcode"): return .cleanPurple
        case let n where n.contains("homebrew"): return .brown
        case let n where n.contains("npm"): return .cleanRed
        case let n where n.contains("trash"): return .gray
        default: return .gray
        }
    }

    @MainActor
    func scan() async {
        isScanning = true
        categories = []

        // Simulate scanning each category
        try? await Task.sleep(for: .seconds(0.5))

        // Mock data for demonstration
        categories = [
            CleanerCategory(
                name: "System Caches",
                icon: "folder.badge.gearshape",
                color: .cleanBlue,
                sizeBytes: 1_234_567_890,
                itemCount: 156
            ),
            CleanerCategory(
                name: "User Caches",
                icon: "folder",
                color: .cleanBlue,
                sizeBytes: 876_543_210,
                itemCount: 89
            ),
            CleanerCategory(
                name: "Application Logs",
                icon: "doc.text",
                color: .cleanOrange,
                sizeBytes: 234_567_890,
                itemCount: 42
            ),
            CleanerCategory(
                name: "Xcode Derived Data",
                icon: "hammer",
                color: .cleanPurple,
                sizeBytes: 3_456_789_012,
                itemCount: 23
            ),
            CleanerCategory(
                name: "Homebrew Cache",
                icon: "cup.and.saucer",
                color: .brown,
                sizeBytes: 567_890_123,
                itemCount: 34
            ),
            CleanerCategory(
                name: "npm Cache",
                icon: "shippingbox",
                color: .cleanRed,
                sizeBytes: 345_678_901,
                itemCount: 67
            ),
            CleanerCategory(
                name: "Trash",
                icon: "trash",
                color: .gray,
                sizeBytes: 2_123_456_789,
                itemCount: 234
            ),
        ]

        isScanning = false
    }

    @MainActor
    func clean() async {
        isCleaning = true

        // TODO: Implement actual cleaning via helper service
        try? await Task.sleep(for: .seconds(1))

        // Remove cleaned categories
        categories.removeAll { $0.isSelected }

        isCleaning = false
    }
}

// MARK: - Types

struct CleanerCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let sizeBytes: Int64
    let itemCount: Int
    var isSelected: Bool = true

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }
}
