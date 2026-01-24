import SwiftUI

struct PermissionsView: View {
    @ObservedObject var viewModel: PermissionsViewModel
    @State private var isVisible = false

    private let sectionColor = Theme.Colors.permissions

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                headerSection
                    .staggeredAnimation(index: 0, isActive: isVisible)

                summaryCard
                    .staggeredAnimation(index: 1, isActive: isVisible)

                categoriesSection
                    .staggeredAnimation(index: 2, isActive: isVisible)

                Spacer(minLength: Theme.Spacing.xl)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.pageTopPadding)
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
            // Trigger full permission check when user visits the Permissions page
            // This includes TCC-triggerable folders (Downloads, Documents, Desktop)
            // that are skipped at app startup to avoid permission dialogs on launch
            viewModel.refreshAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshAllPermissions()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(L("permissions.title"))
                    .font(Theme.Typography.size28Bold)

                Text(L("permissions.subtitle"))
                    .font(Theme.Typography.size13)
                    .foregroundStyle(.secondary)

                if let lastChecked = viewModel.lastChecked {
                    Text(LFormat("permissions.lastChecked %@", formatRelativeTime(lastChecked)))
                        .font(Theme.Typography.size11)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Refresh button
            GlassActionButton(
                L("common.refresh"),
                icon: viewModel.isLoading ? nil : "arrow.clockwise",
                color: sectionColor,
                disabled: viewModel.isLoading
            ) {
                viewModel.refreshAllPermissions()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Overall status indicator
            ZStack {
                Circle()
                    .fill(viewModel.overallStatus.color.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: viewModel.overallStatus.icon)
                    .font(Theme.Typography.size28Semibold)
                    .foregroundStyle(viewModel.overallStatus.color)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(L("permissions.summary.title"))
                    .font(Theme.Typography.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: Theme.Spacing.sm) {
                    Text(summaryText)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                HStack(spacing: Theme.Spacing.xxs) {
                    Text("\(viewModel.totalAccessible)")
                        .font(Theme.Typography.size24BoldRounded)
                        .foregroundStyle(.green)
                    Text("/")
                        .font(Theme.Typography.size18Medium)
                        .foregroundStyle(.secondary)
                    Text("\(viewModel.totalExisting)")
                        .font(Theme.Typography.size24BoldRounded)
                        .foregroundStyle(.primary)
                }

                Text(L("permissions.summary.foldersAccessible"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
    }

    private var summaryText: String {
        let accessible = viewModel.totalAccessible
        let total = viewModel.totalExisting

        if accessible == total && total > 0 {
            return L("permissions.summary.allGranted")
        } else if accessible == 0 {
            return L("permissions.summary.nonegranted")
        } else {
            return LFormat("permissions.summary.partial %lld %lld", accessible, total)
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            ForEach(viewModel.categories) { category in
                PermissionCategoryCard(
                    category: category,
                    onToggleExpand: {
                        viewModel.toggleCategory(category.id)
                    },
                    onOpenSettings: {
                        viewModel.openFullDiskAccessSettings()
                    },
                    onRequestFolderAccess: { folder in
                        viewModel.requestFolderAccess(folder)
                    },
                    onRevokeFolderAccess: { folder in
                        viewModel.revokeFolderAccess(folder)
                    }
                )
            }
        }
    }

    // MARK: - Helpers

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
