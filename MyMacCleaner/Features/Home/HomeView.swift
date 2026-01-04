import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var isVisible = false

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
                                // TODO: Navigate to detail view
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
                Color.black.opacity(0.4)
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
                Color.black.opacity(0.4)
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
        .navigationTitle("Home")
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // Refresh permissions when app becomes active (user might have granted FDA)
            viewModel.refreshPermissions()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to MyMacCleaner")
                    .font(Theme.Typography.largeTitle)

                Text("Keep your Mac running smoothly")
                    .font(Theme.Typography.title3)
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
            SmartScanButton(
                isScanning: viewModel.isScanning,
                progress: viewModel.scanProgress
            ) {
                viewModel.startSmartScan()
            }

            if viewModel.isScanning {
                VStack(spacing: 8) {
                    ProgressView(value: viewModel.scanProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)

                    if let category = viewModel.currentScanCategory {
                        Text("Scanning \(category.rawValue)...")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Preparing scan...")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
                .glassCard()
            }
        }
        .animation(Theme.Animation.spring, value: viewModel.isScanning)
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Stats")
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                StatCard(
                    title: "Storage",
                    value: viewModel.storageUsed,
                    subtitle: "of \(viewModel.storageTotal)",
                    icon: "internaldrive.fill",
                    color: Theme.Colors.storage
                )

                StatCard(
                    title: "Memory",
                    value: viewModel.memoryUsed,
                    subtitle: "in use",
                    icon: "memorychip.fill",
                    color: Theme.Colors.memory
                )

                StatCard(
                    title: "Junk Files",
                    value: viewModel.junkSize,
                    subtitle: "cleanable",
                    icon: "trash.fill",
                    color: Theme.Colors.junk
                )

                StatCard(
                    title: "Apps",
                    value: "\(viewModel.appCount)",
                    subtitle: "installed",
                    icon: "square.grid.2x2.fill",
                    color: Theme.Colors.apps
                )
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quick Actions")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.md) {
                QuickActionButton(
                    title: "Empty Trash",
                    icon: "trash",
                    color: .orange,
                    action: viewModel.emptyTrash
                )

                QuickActionButton(
                    title: "Free Memory",
                    icon: "memorychip",
                    color: .purple,
                    action: viewModel.freeMemory
                )

                QuickActionButton(
                    title: "Large Files",
                    icon: "doc.fill",
                    color: .blue,
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
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.5), radius: 4)

            Text(status)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.md)
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
    let action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .frame(width: 16, height: 16)
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(isScanning ? "Scanning..." : "Smart Scan")
                        .font(Theme.Typography.title2)

                    Text(isScanning ? "Analyzing your system" : "Scan all categories at once")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .offset(x: isHovered ? 4 : 0)
            }
            .padding(Theme.Spacing.lg)
            .glassCardProminent()
        }
        .buttonStyle(.plain)
        .disabled(isScanning)
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
        .animation(Theme.Animation.spring, value: isHovered)
        .animation(Theme.Animation.fast, value: isPressed)
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

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Icon
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                Spacer()
            }

            Spacer()

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }

            // Title
            Text(title)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.md)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .hoverEffect(isHovered: isHovered)
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
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(isHovered ? 0.2 : 0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90, height: 80)
            .glassCardSubtle()
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(Theme.Animation.fast, value: isPressed)
        .onHover { hovering in
            withAnimation(Theme.Animation.fast) {
                isHovered = hovering
            }
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
