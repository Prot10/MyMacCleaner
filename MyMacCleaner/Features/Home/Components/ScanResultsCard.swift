import SwiftUI

// MARK: - Scan Results Card

struct ScanResultsCard: View {
    let results: [ScanResult]
    let onClean: () -> Void
    let onViewDetails: (ScanResult) -> Void

    @State private var isHovered = false
    @State private var isVisible = false

    var totalSize: Int64 {
        results.reduce(0) { $0 + $1.totalSize }
    }

    var selectedSize: Int64 {
        results.reduce(0) { $0 + $1.selectedSize }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Header
            headerSection

            // Category breakdown
            categoryBreakdown

            // Action buttons
            actionButtons
        }
        .padding(Theme.Spacing.lg)
        .glassCardProminent()
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scan Complete")
                    .font(Theme.Typography.title2)

                Text("\(results.count) categories found")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Total size badge
            VStack(alignment: .trailing, spacing: 4) {
                Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                    .font(Theme.Typography.title)
                    .foregroundStyle(.orange)

                Text("cleanable")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ForEach(results.sorted(by: { $0.totalSize > $1.totalSize })) { result in
                ScanResultRow(result: result) {
                    onViewDetails(result)
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // View all button
            Button(action: {}) {
                HStack(spacing: 8) {
                    Image(systemName: "list.bullet")
                    Text("View All")
                }
                .font(Theme.Typography.subheadline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glassCardSubtle()
            }
            .buttonStyle(.plain)

            Spacer()

            // Clean button
            Button(action: onClean) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Clean \(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))")
                }
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
        }
    }
}

// MARK: - Scan Result Row

struct ScanResultRow: View {
    let result: ScanResult
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Theme.Spacing.md) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(result.category.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: result.category.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(result.category.color)
                }

                // Category info
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.category.rawValue)
                        .font(Theme.Typography.body)
                        .foregroundStyle(.primary)

                    Text("\(result.itemCount) items")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Size
                Text(ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file))
                    .font(Theme.Typography.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .offset(x: isHovered ? 2 : 0)
            }
            .padding(Theme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.fast, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Scan Summary

struct CompactScanSummary: View {
    let summary: ScanSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Total cleanable
            VStack(spacing: 4) {
                Text(summary.formattedTotalSize)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(.orange)

                Text("Cleanable")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            // Item count
            VStack(spacing: 4) {
                Text("\(summary.itemCount)")
                    .font(Theme.Typography.title2)

                Text("Files")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            // Largest category
            if let largest = summary.largestCategory {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: largest.icon)
                            .foregroundStyle(largest.color)
                        Text(largest.rawValue)
                    }
                    .font(Theme.Typography.subheadline)

                    Text("Largest")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .glassCard()
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ScanResultsCard(
            results: [
                ScanResult(
                    category: .userCache,
                    items: [
                        CleanableItem(
                            name: "test.cache",
                            path: URL(fileURLWithPath: "/tmp/test"),
                            size: 1024 * 1024 * 500,
                            modificationDate: Date(),
                            category: .userCache
                        )
                    ]
                ),
                ScanResult(
                    category: .xcodeData,
                    items: [
                        CleanableItem(
                            name: "DerivedData",
                            path: URL(fileURLWithPath: "/tmp/derived"),
                            size: 1024 * 1024 * 1024 * 2,
                            modificationDate: Date(),
                            category: .xcodeData
                        )
                    ]
                )
            ],
            onClean: {},
            onViewDetails: { _ in }
        )
    }
    .padding()
    .frame(width: 600, height: 400)
}
