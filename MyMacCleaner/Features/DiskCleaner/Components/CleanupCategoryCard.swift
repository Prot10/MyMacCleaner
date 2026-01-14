import SwiftUI

// MARK: - Cleanup Category Card

struct CleanupCategoryCard: View {
    let result: ScanResult
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleSelection: () -> Void
    let onToggleItem: (CleanableItem) -> Void
    let onViewDetails: () -> Void

    @State private var isHovered = false

    private var allSelected: Bool {
        result.items.allSatisfy { $0.isSelected }
    }

    private var someSelected: Bool {
        result.items.contains { $0.isSelected } && !allSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            headerRow

            // Expanded content
            if isExpanded {
                expandedContent
            }
        }
        .clipped()
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
        .animation(Theme.Animation.spring, value: isExpanded)
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 0) {
            // Selection checkbox - separate hit area
            Button(action: onToggleSelection) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny)
                        .stroke(allSelected || someSelected ? result.category.color : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 20, height: 20)

                    if allSelected {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny)
                            .fill(result.category.color)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(Theme.Typography.size10Bold)
                            .foregroundStyle(.white)
                    } else if someSelected {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny)
                            .fill(result.category.color.opacity(0.5))
                            .frame(width: 20, height: 20)

                        Image(systemName: "minus")
                            .font(Theme.Typography.size10Bold)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.leading, Theme.Spacing.md)
                .padding(.trailing, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Expandable area - everything else
            HStack(spacing: Theme.Spacing.md) {
                // Category icon
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(result.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: result.category.icon)
                        .font(Theme.Typography.size18Semibold)
                        .foregroundStyle(result.category.color)
                }

                // Category info
                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(result.category.localizedName)
                        .font(Theme.Typography.body)

                    Text(result.category.localizedDescription)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Size and count
                VStack(alignment: .trailing, spacing: Theme.Spacing.tiny) {
                    Text(ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file))
                        .font(Theme.Typography.subheadline.monospacedDigit())
                        .foregroundStyle(result.category.color)

                    Text(LFormat("common.items %lld", result.itemCount))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }

                // Expand chevron
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.size12Semibold)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.trailing, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.md)
            .contentShape(Rectangle())
            .onTapGesture(perform: onToggleExpand)
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.horizontal, Theme.Spacing.md)

            // Item list (show first 5)
            let displayItems = Array(result.items.prefix(5))

            ForEach(displayItems) { item in
                CleanableItemRow(
                    item: item,
                    categoryColor: result.category.color,
                    onToggle: { onToggleItem(item) }
                )

                if item.id != displayItems.last?.id {
                    Divider()
                        .padding(.leading, 60)
                }
            }

            // View all button if more items
            if result.items.count > 5 {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                Button(action: onViewDetails) {
                    HStack {
                        Text(LFormat("diskCleaner.viewAllItems %lld", result.items.count))
                            .font(Theme.Typography.subheadline)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundStyle(result.category.color)
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.md)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Cleanable Item Row

struct CleanableItemRow: View {
    let item: CleanableItem
    let categoryColor: Color
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny)
                        .stroke(item.isSelected ? categoryColor : Color.secondary.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if item.isSelected {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny)
                            .fill(categoryColor)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(Theme.Typography.size9Bold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // File icon
            Image(systemName: fileIcon(for: item.name))
                .font(Theme.Typography.size14)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            // File info
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Text(item.name)
                    .font(Theme.Typography.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(item.path.path)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Size and date
            VStack(alignment: .trailing, spacing: Theme.Spacing.tiny) {
                Text(item.formattedSize)
                    .font(Theme.Typography.caption.monospacedDigit())
                    .foregroundStyle(.secondary)

                Text(item.formattedDate)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .onHover { isHovered = $0 }
    }

    private func fileIcon(for name: String) -> String {
        let ext = (name as NSString).pathExtension.lowercased()

        switch ext {
        case "log", "txt": return "doc.text"
        case "cache": return "archivebox"
        case "plist": return "gearshape"
        case "json": return "curlybraces"
        case "db", "sqlite": return "cylinder"
        case "zip", "gz", "tar": return "doc.zipper"
        case "dmg": return "externaldrive"
        case "app": return "app"
        case "png", "jpg", "jpeg", "gif": return "photo"
        case "mp3", "wav", "aac": return "music.note"
        case "mp4", "mov", "avi": return "film"
        case "pdf": return "doc.richtext"
        default: return "doc"
        }
    }
}

// MARK: - Category Detail Sheet

struct CategoryDetailSheet: View {
    let result: ScanResult
    let onToggleItem: (CleanableItem) -> Void
    let onClose: () -> Void

    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .sizeDesc

    enum SortOrder: String, CaseIterable {
        case sizeDesc
        case sizeAsc
        case dateDesc
        case dateAsc
        case name

        var localizedName: String {
            L(key: "diskCleaner.sort.\(rawValue)")
        }
    }

    private var filteredItems: [CleanableItem] {
        var items = result.items

        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.path.path.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .sizeDesc:
            items.sort { $0.size > $1.size }
        case .sizeAsc:
            items.sort { $0.size < $1.size }
        case .dateDesc:
            items.sort { ($0.modificationDate ?? .distantPast) > ($1.modificationDate ?? .distantPast) }
        case .dateAsc:
            items.sort { ($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast) }
        case .name:
            items.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }

        return items
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .fill(result.category.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: result.category.icon)
                        .font(Theme.Typography.size18Semibold)
                        .foregroundStyle(result.category.color)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                    Text(result.category.localizedName)
                        .font(Theme.Typography.title3)

                    Text(LFormat("diskCleaner.itemsSummary %lld %@", result.itemCount, ByteCountFormatter.string(fromByteCount: result.totalSize, countStyle: .file)))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.lg)

            Divider()

            // Search and sort
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(L("diskCleaner.searchFiles"), text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(Theme.Spacing.sm)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))

                Picker(L("diskCleaner.sort"), selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.localizedName).tag(order)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            .padding(Theme.Spacing.md)

            Divider()

            // Item list
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredItems) { item in
                        CleanableItemRow(
                            item: item,
                            categoryColor: result.category.color,
                            onToggle: { onToggleItem(item) }
                        )

                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Preview

#Preview("Category Card") {
    VStack {
        CleanupCategoryCard(
            result: ScanResult(
                category: .userCache,
                items: [
                    CleanableItem(
                        name: "com.apple.Safari",
                        path: URL(fileURLWithPath: "/Users/test/Library/Caches/com.apple.Safari"),
                        size: 1024 * 1024 * 150,
                        modificationDate: Date().addingTimeInterval(-86400),
                        category: .userCache
                    ),
                    CleanableItem(
                        name: "com.google.Chrome",
                        path: URL(fileURLWithPath: "/Users/test/Library/Caches/com.google.Chrome"),
                        size: 1024 * 1024 * 300,
                        modificationDate: Date().addingTimeInterval(-172800),
                        category: .userCache
                    )
                ]
            ),
            isExpanded: true,
            onToggleExpand: {},
            onToggleSelection: {},
            onToggleItem: { _ in },
            onViewDetails: {}
        )
    }
    .padding()
    .frame(width: 600, height: 400)
}
