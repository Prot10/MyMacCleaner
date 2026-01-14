import SwiftUI

// MARK: - Homebrew Cask Row

struct HomebrewCaskRow: View {
    let cask: HomebrewCask
    let showUpdateBadge: Bool
    let onUpgrade: (() -> Void)?
    let onUninstall: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "shippingbox.fill")
                    .font(Theme.Typography.size18)
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(cask.displayName)
                        .font(Theme.Typography.subheadline.weight(.semibold))

                    if showUpdateBadge {
                        Text(L("applications.homebrew.updateBadge"))
                            .font(Theme.Typography.caption2)
                            .padding(.horizontal, Theme.Spacing.xxxs)
                            .padding(.vertical, Theme.Spacing.tiny)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: Theme.Spacing.xs) {
                    if let installedVersion = cask.installedVersion {
                        Text("v\(installedVersion)")
                            .foregroundStyle(.secondary)

                        if cask.hasUpdate {
                            Image(systemName: "arrow.right")
                                .font(Theme.Typography.caption2)
                                .foregroundStyle(.tertiary)

                            Text("v\(cask.version)")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("v\(cask.version)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(Theme.Typography.caption)

                if let description = cask.description {
                    Text(description)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: Theme.Spacing.sm) {
                if let homepage = cask.homepage {
                    Link(destination: homepage) {
                        Image(systemName: "globe")
                            .font(Theme.Typography.size14)
                            .foregroundStyle(.secondary)
                    }
                }

                if let onUpgrade = onUpgrade {
                    Button(action: onUpgrade) {
                        HStack(spacing: Theme.Spacing.xxs) {
                            Image(systemName: "arrow.up.circle")
                            Text(L("applications.homebrew.upgrade"))
                        }
                        .font(Theme.Typography.size12Medium)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, Theme.Spacing.xxxs)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onUninstall) {
                    Image(systemName: "trash")
                        .font(Theme.Typography.size14)
                        .foregroundStyle(.red)
                        .padding(Theme.Spacing.xxxs)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(isHovered ? 0.05 : 0))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
        .onHover { isHovered = $0 }
    }
}
