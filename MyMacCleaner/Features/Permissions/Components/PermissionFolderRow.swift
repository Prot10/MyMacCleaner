import SwiftUI

struct PermissionFolderRow: View {
    let folder: FolderAccessInfo
    let onRequestAccess: () -> Void
    let onRevokeAccess: () -> Void
    let onOpenSettings: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status indicator
            statusIcon

            // Path info
            VStack(alignment: .leading, spacing: 2) {
                Text(folder.displayName)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(folder.path)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Badges and actions
            HStack(spacing: Theme.Spacing.sm) {
                // FDA badge
                if folder.requiresFDA {
                    Text("FDA")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }

                // Action buttons based on status
                actionButton
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
        .padding(.horizontal, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        )
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var statusIcon: some View {
        if folder.status == .checking {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: folder.status.icon)
                .foregroundStyle(folder.status.color)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 18, height: 18)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch folder.status {
        case .accessible:
            // Show revoke button when accessible
            Button(action: onRevokeAccess) {
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 10))
                    Text(L("permissions.folder.revoke"))
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.8))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

        case .denied:
            // Show grant button when denied
            if folder.canTriggerTCCDialog {
                // TCC folders can trigger dialog directly
                Button(action: onRequestAccess) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10))
                        Text(L("permissions.folder.grant"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                // FDA folders need System Settings
                Button(action: onOpenSettings) {
                    HStack(spacing: 4) {
                        Image(systemName: "gear")
                            .font(.system(size: 10))
                        Text(L("permissions.folder.grant"))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

        case .notExists:
            // No action for non-existent folders
            EmptyView()

        case .checking:
            // No action while checking
            EmptyView()
        }
    }
}
