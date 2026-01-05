import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isVisible = false

    private let sectionColor = Theme.Colors.home

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Permission banner (if needed)
                    if !viewModel.hasFullDiskAccess && !viewModel.showPermissionPrompt {
                        PermissionBanner(permissionsService: PermissionsService.shared)
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    }

                    // Smart Scan Button
                    smartScanSection
                        .staggeredAnimation(index: 2, isActive: isVisible)

                    // Scan Results (if available)
                    if viewModel.showScanResults {
                        ScanResultsCard(
                            results: viewModel.scanResults,
                            onClean: viewModel.cleanSelectedItems,
                            onViewDetails: { result in
                                print("View details for \(result.category.rawValue)")
                            }
                        )
                        .staggeredAnimation(index: 3, isActive: isVisible)
                    }

                    // Quick Stats
                    quickStatsSection
                        .staggeredAnimation(index: viewModel.showScanResults ? 4 : 3, isActive: isVisible)

                    // Quick Actions
                    quickActionsSection
                        .staggeredAnimation(index: viewModel.showScanResults ? 5 : 4, isActive: isVisible)
                }
                .padding(Theme.Spacing.lg)
            }

            // Permission prompt overlay
            if viewModel.showPermissionPrompt {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)

                PermissionPromptView(
                    permissionsService: PermissionsService.shared,
                    onDismiss: viewModel.dismissPermissionPrompt,
                    onContinueWithoutPermission: viewModel.continueWithLimitedScan
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Cleaning progress overlay
            if viewModel.isCleaning {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)

                CleaningProgressOverlay(
                    progress: viewModel.cleaningProgress,
                    category: viewModel.cleaningCategory
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Toast notification
            if viewModel.showToast {
                VStack {
                    ToastView(
                        message: viewModel.toastMessage,
                        type: viewModel.toastType,
                        onDismiss: viewModel.dismissToast
                    )
                    .padding(.top, Theme.Spacing.lg)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.springSmooth, value: viewModel.showPermissionPrompt)
        .animation(Theme.Animation.springSmooth, value: viewModel.isCleaning)
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshPermissions()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("navigation.home"))
                    .font(.system(size: 28, weight: .bold))

                Text(L("home.subtitle"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // System status indicator
            HStack(spacing: Theme.Spacing.sm) {
                PermissionStatusView(hasFullDiskAccess: viewModel.hasFullDiskAccess)

                SystemHealthPill(
                    status: viewModel.systemHealthStatus,
                    color: viewModel.systemHealthColor
                )
            }
        }
    }

    // MARK: - Smart Scan Section

    private var smartScanSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            VStack(spacing: 28) {
                // Icon
                ZStack {
                    Circle()
                        .fill(sectionColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 80, height: 80)
                            .overlay {
                                Circle()
                                    .strokeBorder(sectionColor.opacity(0.3), lineWidth: 1)
                            }

                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.regular)
                                .tint(sectionColor)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(sectionColor.gradient)
                        }
                    }
                }

                VStack(spacing: 8) {
                    Text(viewModel.isScanning ? L("home.scanning") : L("home.smartScan"))
                        .font(.system(size: 20, weight: .semibold))

                    Text(viewModel.isScanning ? L("home.scan.analyzing") : L("home.scan.description"))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }

                if viewModel.isScanning {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.scanProgress)
                            .progressViewStyle(.linear)
                            .tint(sectionColor)
                            .frame(maxWidth: 300)

                        if let category = viewModel.currentScanCategory {
                            Text(LFormat("home.scan.scanningCategory %@", category.localizedName))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                } else {
                    GlassActionButton(
                        L("home.scan.startButton"),
                        icon: "magnifyingglass",
                        color: sectionColor
                    ) {
                        viewModel.startSmartScan()
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

            // Error display
            if let error = viewModel.scanError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(error)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Spacing.sm)
                .glassEffect(.regular.tint(.orange), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .animation(Theme.Animation.spring, value: viewModel.isScanning)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(L("home.stats.title"))
                .font(Theme.Typography.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                StatCard(
                    title: L("home.stats.storage"),
                    value: viewModel.storageUsed,
                    subtitle: LFormat("home.stats.of %@", viewModel.storageTotal),
                    icon: "internaldrive.fill",
                    color: Theme.Colors.storage
                )

                StatCard(
                    title: L("home.stats.memory"),
                    value: viewModel.memoryUsed,
                    subtitle: L("home.stats.inUse"),
                    icon: "memorychip.fill",
                    color: Theme.Colors.memory
                )

                StatCard(
                    title: L("home.stats.junkFiles"),
                    value: viewModel.junkSize,
                    subtitle: L("home.stats.cleanable"),
                    icon: "trash.fill",
                    color: Theme.Colors.storage
                )

                StatCard(
                    title: L("home.stats.apps"),
                    value: "\(viewModel.appCount)",
                    subtitle: L("home.stats.installed"),
                    icon: "square.grid.2x2.fill",
                    color: Theme.Colors.apps
                )
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(L("home.actions.title"))
                .font(Theme.Typography.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: Theme.Spacing.md) {
                QuickActionButton(
                    title: L("home.actions.emptyTrash"),
                    icon: "trash",
                    color: Theme.Colors.storage,
                    action: viewModel.emptyTrash
                )

                QuickActionButton(
                    title: L("home.actions.freeMemory"),
                    icon: "memorychip",
                    color: Theme.Colors.memory,
                    action: viewModel.freeMemory
                )

                QuickActionButton(
                    title: L("home.actions.largeFiles"),
                    icon: "doc.fill",
                    color: Theme.Colors.home,
                    action: viewModel.viewLargeFiles
                )

                Spacer()
            }
        }
    }
}

// MARK: - System Health Pill

struct SystemHealthPill: View {
    let status: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 4)

            Text(status)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .glassPill()
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Smart Scan Button

struct SmartScanButton: View {
    let isScanning: Bool
    let progress: Double
    let color: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Circle()
                                .strokeBorder(color.opacity(0.3), lineWidth: 1)
                        }

                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.regular)
                            .tint(color)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(color.gradient)
                    }
                }
            }

            VStack(spacing: 8) {
                Text(isScanning ? L("home.scanning") : L("home.smartScan"))
                    .font(.system(size: 20, weight: .semibold))

                Text(isScanning ? L("home.scan.analyzing") : L("home.scan.description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            if !isScanning {
                GlassActionButton(
                    L("home.scan.startButton"),
                    icon: "magnifyingglass",
                    color: color
                ) {
                    action()
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            Spacer()

            // Value and subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer()
                .frame(height: 12)

            // Title
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(height: 160)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .shadow(color: color.opacity(isHovered ? 0.25 : 0.1), radius: isHovered ? 15 : 8, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(color)
                }
                .shadow(color: color.opacity(isHovered ? 0.4 : 0.2), radius: 8)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, height: 100)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.02 : 1.0))
        .shadow(color: .black.opacity(isHovered ? 0.15 : 0.1), radius: isHovered ? 12 : 6, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView(viewModel: HomeViewModel())
        .frame(width: 800, height: 600)
}
