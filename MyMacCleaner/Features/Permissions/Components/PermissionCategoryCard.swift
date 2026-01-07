import SwiftUI

struct PermissionCategoryCard: View {
    let category: PermissionCategoryState
    let onToggleExpand: () -> Void
    let onOpenSettings: () -> Void
    let onRequestFolderAccess: (FolderAccessInfo) -> Void
    let onRevokeFolderAccess: (FolderAccessInfo) -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            headerRow
                .contentShape(Rectangle())
                .onTapGesture {
                    onToggleExpand()
                }

            // Expandable folder list
            if category.isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                VStack(spacing: 0) {
                    ForEach(category.folders) { folder in
                        PermissionFolderRow(
                            folder: folder,
                            onRequestAccess: { onRequestFolderAccess(folder) },
                            onRevokeAccess: { onRevokeFolderAccess(folder) },
                            onOpenSettings: onOpenSettings
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.xs)

                // Category action button
                if category.type.requiresSystemSettings {
                    Divider()
                        .padding(.horizontal, Theme.Spacing.md)

                    HStack {
                        Spacer()
                        Button(action: onOpenSettings) {
                            HStack(spacing: 6) {
                                Image(systemName: "gear")
                                    .font(.system(size: 12))
                                Text(L("permissions.action.openSettings"))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
        }
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }

    private var headerRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Category icon
            ZStack {
                Circle()
                    .fill(category.type.color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: category.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(category.type.color)
            }

            // Category info
            VStack(alignment: .leading, spacing: 2) {
                Text(category.type.localizedName)
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.primary)

                Text(category.type.localizedDescription)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status summary
            HStack(spacing: Theme.Spacing.sm) {
                statusBadge

                // Expand chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(category.isExpanded ? 90 : 0))
            }
        }
        .padding(Theme.Spacing.md)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let status = category.overallStatus

        HStack(spacing: 4) {
            if status == .checking {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: 10))
            }

            Text(category.statusSummary)
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}
