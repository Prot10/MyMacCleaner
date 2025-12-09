import SwiftUI

/// Card showing cleanup summary with action buttons
struct CleanupSummaryCard: View {
    let totalSize: Int64
    let categories: [CleanupCategorySummary]
    let onCleanNow: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cleanup Available")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Health indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.green)
            }

            // Categories breakdown
            if !categories.isEmpty {
                VStack(spacing: 8) {
                    ForEach(categories.prefix(4)) { category in
                        HStack {
                            Circle()
                                .fill(categoryColor(for: category.name))
                                .frame(width: 8, height: 8)

                            Text(category.name)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(category.formattedSize)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }

                    if categories.count > 4 {
                        Text("and \(categories.count - 4) more...")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 8)
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onViewDetails) {
                    Text("View Details")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(action: onCleanNow) {
                    Text("Clean Now")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private func categoryColor(for name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("cache"): return .blue
        case let n where n.contains("log"): return .orange
        case let n where n.contains("xcode"): return .purple
        case let n where n.contains("trash"): return .red
        default: return .gray
        }
    }
}

#Preview {
    CleanupSummaryCard(
        totalSize: 5_432_100_000,
        categories: [
            CleanupCategorySummary(name: "System Caches", sizeBytes: 2_100_000_000),
            CleanupCategorySummary(name: "User Caches", sizeBytes: 1_500_000_000),
            CleanupCategorySummary(name: "Logs", sizeBytes: 800_000_000),
            CleanupCategorySummary(name: "Xcode Data", sizeBytes: 700_000_000),
            CleanupCategorySummary(name: "Trash", sizeBytes: 332_100_000),
        ],
        onCleanNow: {},
        onViewDetails: {}
    )
    .padding()
    .frame(width: 400)
    .background(Color(nsColor: .windowBackgroundColor))
}
