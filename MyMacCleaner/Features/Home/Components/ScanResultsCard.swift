import SwiftUI

// MARK: - Scan Results Card

struct ScanResultsCard: View {
    @Binding var results: [ScanResult]
    let onClean: () -> Void
    let onViewDetails: (ScanResult) -> Void

    @State private var isHovered = false
    @State private var isVisible = false
    @State private var expandedCategories: Set<ScanCategory> = []
    @State private var allExpanded = false

    var totalSize: Int64 {
        results.reduce(0) { $0 + $1.totalSize }
    }

    var selectedSize: Int64 {
        results.filter { $0.isSelected }.reduce(0) { $0 + $1.totalSize }
    }

    var selectedCount: Int {
        results.filter { $0.isSelected }.count
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
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(L("scanResults.title"))
                    .font(Theme.Typography.title2)

                Text(LFormat("scanResults.categoriesFound %lld", results.count))
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Total size badge
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                Text(ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file))
                    .font(Theme.Typography.title)
                    .foregroundStyle(.orange)

                Text(selectedCount == results.count ? L("scanResults.cleanable") : LFormat("scanResults.selectedCount %lld", selectedCount))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ForEach(results.sorted(by: { $0.totalSize > $1.totalSize }).indices, id: \.self) { index in
                let sortedResults = results.sorted(by: { $0.totalSize > $1.totalSize })
                if let resultIndex = results.firstIndex(where: { $0.id == sortedResults[index].id }) {
                    ScanResultRow(
                        result: $results[resultIndex],
                        isExpanded: expandedCategories.contains(results[resultIndex].category),
                        onToggleExpand: {
                            withAnimation(Theme.Animation.spring) {
                                if expandedCategories.contains(results[resultIndex].category) {
                                    expandedCategories.remove(results[resultIndex].category)
                                } else {
                                    expandedCategories.insert(results[resultIndex].category)
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Theme.Spacing.md) {
            // View all / Collapse all button
            Button(action: {
                withAnimation(Theme.Animation.spring) {
                    if allExpanded {
                        expandedCategories.removeAll()
                    } else {
                        expandedCategories = Set(results.map { $0.category })
                    }
                    allExpanded.toggle()
                }
            }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: allExpanded ? "chevron.up.2" : "list.bullet")
                    Text(allExpanded ? L("scanResults.collapseAll") : L("scanResults.viewAll"))
                }
                .font(Theme.Typography.subheadline)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glassCardSubtle()
            }
            .buttonStyle(.plain)

            // Select all / Deselect all button
            Button(action: {
                withAnimation(Theme.Animation.spring) {
                    let allSelected = results.allSatisfy { $0.isSelected }
                    for index in results.indices {
                        results[index].isSelected = !allSelected
                    }
                }
            }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: results.allSatisfy({ $0.isSelected }) ? "checkmark.circle.fill" : "circle")
                    Text(results.allSatisfy({ $0.isSelected }) ? L("scanResults.deselectAll") : L("scanResults.selectAll"))
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .glassCardSubtle()
            }
            .buttonStyle(.plain)

            Spacer()

            // Clean button
            Button(action: onClean) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "trash.fill")
                    Text(LFormat("scanResults.clean %@", ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)))
                }
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: selectedSize > 0 ? [.orange, .orange.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .disabled(selectedSize == 0)
            .shadow(color: selectedSize > 0 ? .orange.opacity(0.3) : .clear, radius: 8, y: 4)
        }
    }
}

// MARK: - Scan Result Row

struct ScanResultRow: View {
    @Binding var result: ScanResult
    let isExpanded: Bool
    let onToggleExpand: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row content
            HStack(spacing: 0) {
                // Checkbox for selection - separate hit area
                Button(action: {
                    withAnimation(Theme.Animation.fast) {
                        result.isSelected.toggle()
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                            .stroke(result.isSelected ? result.category.color : Color.secondary.opacity(0.5), lineWidth: 2)
                            .frame(width: 22, height: 22)

                        if result.isSelected {
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                                .fill(result.category.color)
                                .frame(width: 22, height: 22)

                            Image(systemName: "checkmark")
                                .font(Theme.Typography.size12Bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.leading, Theme.Spacing.sm)
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Expandable area - everything else
                HStack(spacing: Theme.Spacing.md) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(result.category.color.opacity(result.isSelected ? 0.15 : 0.08))
                            .frame(width: 36, height: 36)

                        Image(systemName: result.category.icon)
                            .font(Theme.Typography.size14Semibold)
                            .foregroundStyle(result.isSelected ? result.category.color : result.category.color.opacity(0.5))
                    }

                    // Category info
                    VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                        Text(result.category.localizedName)
                            .font(Theme.Typography.body)
                            .foregroundStyle(result.isSelected ? .primary : .secondary)

                        Text(LFormat("scanResults.items %lld", result.itemCount))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    // Size
                    Text(ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file))
                        .font(Theme.Typography.subheadline.monospacedDigit())
                        .foregroundStyle(result.isSelected ? .secondary : .tertiary)

                    // Expand/Collapse chevron
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.trailing, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.sm)
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggleExpand()
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(isHovered ? Color.white.opacity(0.05) : Color.clear)
            )
            .onHover { hovering in
                withAnimation(Theme.Animation.fast) {
                    isHovered = hovering
                }
            }

            // Expanded content - show individual files
            if isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                VStack(spacing: 0) {
                    // Show files with a max of 10, then indicate more
                    let itemsToShow = Array(result.items.sorted(by: { $0.size > $1.size }).prefix(10))

                    ForEach(itemsToShow) { item in
                        ScanFileItemRow(item: item)
                    }

                    // Show "and X more" if there are more items
                    if result.items.count > 10 {
                        HStack {
                            Spacer()
                            Text(LFormat("scanResults.andMore %lld", result.items.count - 10))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, Theme.Spacing.sm)
                            Spacer()
                        }
                        .background(Color.white.opacity(0.02))
                    }
                }
                .background(Color.white.opacity(0.02))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
            }
        }
        .glassCard()
        .animation(Theme.Animation.spring, value: isExpanded)
    }
}

// MARK: - Cleanable Item Row

struct ScanFileItemRow: View {
    let item: CleanableItem

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // File type icon
            Image(systemName: fileIcon)
                .font(Theme.Typography.size12)
                .foregroundStyle(.tertiary)
                .frame(width: 20)

            // File name
            Text(item.name)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Modified date
            if item.modificationDate != nil {
                Text(item.formattedDate)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }

            // Size
            Text(item.formattedSize)
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
                .frame(width: 70, alignment: .trailing)

            // Reveal in Finder button
            Button(action: {
                NSWorkspace.shared.selectFile(item.path.path, inFileViewerRootedAtPath: item.path.deletingLastPathComponent().path)
            }) {
                Image(systemName: "folder")
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
            .help(L("common.showInFinder"))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
    }

    private var fileIcon: String {
        let ext = item.path.pathExtension.lowercased()
        switch ext {
        case "app": return "app.fill"
        case "dmg", "pkg": return "shippingbox.fill"
        case "zip", "tar", "gz", "rar": return "doc.zipper"
        case "log", "txt": return "doc.text"
        case "json", "xml", "plist": return "doc.badge.gearshape"
        case "": return "folder.fill"
        default: return "doc.fill"
        }
    }
}

// MARK: - Compact Scan Summary

struct CompactScanSummary: View {
    let summary: ScanSummary

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Total cleanable
            VStack(spacing: Theme.Spacing.xxs) {
                Text(summary.formattedTotalSize)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(.orange)

                Text(L("scanResults.cleanable"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            // Item count
            VStack(spacing: Theme.Spacing.xxs) {
                Text("\(summary.itemCount)")
                    .font(Theme.Typography.title2)

                Text(L("scanResults.files"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .frame(height: 40)

            // Largest category
            if let largest = summary.largestCategory {
                VStack(spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Image(systemName: largest.icon)
                            .foregroundStyle(largest.color)
                        Text(largest.localizedName)
                    }
                    .font(Theme.Typography.subheadline)

                    Text(L("scanResults.largest"))
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
    struct PreviewWrapper: View {
        @State var results: [ScanResult] = [
            ScanResult(
                category: .userCache,
                items: [
                    CleanableItem(
                        name: "test.cache",
                        path: URL(fileURLWithPath: "/tmp/test"),
                        size: 1024 * 1024 * 500,
                        modificationDate: Date(),
                        category: .userCache
                    ),
                    CleanableItem(
                        name: "another.cache",
                        path: URL(fileURLWithPath: "/tmp/another"),
                        size: 1024 * 1024 * 100,
                        modificationDate: Date().addingTimeInterval(-86400),
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
        ]

        var body: some View {
            ScanResultsCard(
                results: $results,
                onClean: {},
                onViewDetails: { _ in }
            )
        }
    }

    return PreviewWrapper()
        .padding()
        .frame(width: 700, height: 500)
}
