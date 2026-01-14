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
                            HStack(spacing: Theme.Spacing.xxxs) {
                                Image(systemName: "gear")
                                    .font(Theme.Typography.size12)
                                Text(L("permissions.action.openSettings"))
                                    .font(Theme.Typography.size12Medium)
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
                    .font(Theme.Typography.size18Semibold)
                    .foregroundStyle(category.type.color)
            }

            // Category info
            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
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
                    .font(Theme.Typography.size12Semibold)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(category.isExpanded ? 90 : 0))
            }
        }
        .padding(Theme.Spacing.md)
    }

    @ViewBuilder
    private var statusBadge: some View {
        let status = category.overallStatus

        HStack(spacing: Theme.Spacing.xxs) {
            if status == .checking {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: status.icon)
                    .font(Theme.Typography.size10)
            }

            Text(category.statusSummary)
                .font(Theme.Typography.size11Semibold)
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12))
        .clipShape(Capsule())
    }
}
