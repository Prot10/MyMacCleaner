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
                color: .blue,
                sizeBytes: 1_234_567_890,
                itemCount: 156
            ),
            CleanerCategory(
                name: "User Caches",
                icon: "folder",
                color: .cyan,
                sizeBytes: 876_543_210,
                itemCount: 89
            ),
            CleanerCategory(
                name: "Application Logs",
                icon: "doc.text",
                color: .orange,
                sizeBytes: 234_567_890,
                itemCount: 42
            ),
            CleanerCategory(
                name: "Xcode Derived Data",
                icon: "hammer",
                color: .purple,
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
                color: .red,
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
