import SwiftUI

struct DiskCleanerView: View {
    @ObservedObject var viewModel: DiskCleanerViewModel
    @ObservedObject var spaceLensViewModel: SpaceLensViewModel
    @StateObject private var privacyViewModel = BrowserPrivacyViewModel()
    @State private var isVisible = false
    @State private var selectedTab: DiskCleanerTab = .cleaner

    // Section color for disk cleaner
    private let sectionColor = Theme.Colors.storage

    enum DiskCleanerTab: String, CaseIterable {
        case cleaner
        case privacy
        case spaceLens

        var icon: String {
            switch self {
            case .cleaner: return "trash"
            case .privacy: return "hand.raised.fill"
            case .spaceLens: return "circle.hexagongrid.fill"
            }
        }

        var localizedName: String {
            switch self {
            case .cleaner: return L("diskCleaner.tab.cleaner")
            case .privacy: return L("diskCleaner.tab.privacy")
            case .spaceLens: return L("diskCleaner.tab.spaceLens")
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Tab picker
                    tabPicker
                        .staggeredAnimation(index: 1, isActive: isVisible)

                    // Content based on selected tab
                    switch selectedTab {
                    case .cleaner:
                        cleanerContent
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    case .privacy:
                        BrowserPrivacyView(viewModel: privacyViewModel)
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    case .spaceLens:
                        SpaceLensView(viewModel: spaceLensViewModel)
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            // Scanning overlay
            if viewModel.isScanning {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ScanningOverlay(
                    progress: viewModel.scanProgress,
                    category: viewModel.currentScanCategory?.localizedName ?? L("diskCleaner.scan.preparing"),
                    accentColor: sectionColor
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Cleaning overlay
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

            // Toast
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
        .animation(Theme.Animation.spring, value: selectedTab)
        .animation(Theme.Animation.springSmooth, value: viewModel.isScanning)
        .animation(Theme.Animation.springSmooth, value: viewModel.isCleaning)
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .sheet(isPresented: $viewModel.showCategoryDetail) {
            if let category = viewModel.selectedCategory {
                CategoryDetailSheet(
                    result: category,
                    onToggleItem: { item in
                        viewModel.toggleItemSelection(item, in: category.category)
                    },
                    onClose: { viewModel.showCategoryDetail = false }
                )
            }
        }
        .alert(L("diskCleaner.clean.confirmTitle"), isPresented: $viewModel.showCleanConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelClean()
            }
            Button(L("diskCleaner.clean.moveToTrash"), role: .destructive) {
                viewModel.confirmClean()
            }
        } message: {
            Text(LFormat("diskCleaner.clean.confirmMessage %lld %@", Int64(viewModel.selectedItemCount), viewModel.formattedSelectedSize))
        }
        .alert(L("diskCleaner.emptyTrash.confirmTitle"), isPresented: $viewModel.showEmptyTrashConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelEmptyTrash()
            }
            Button(L("diskCleaner.emptyTrash.confirmButton"), role: .destructive) {
                viewModel.confirmEmptyTrash()
            }
        } message: {
            Text(LFormat("diskCleaner.emptyTrash.confirmMessage %@", viewModel.formattedTrashSize))
        }
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
                Text(L("navigation.diskCleaner"))
                    .font(.system(size: 28, weight: .bold))

                Text(L("diskCleaner.subtitle"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.hasScanned && !viewModel.scanResults.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.formattedTotalSize)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(sectionColor)

                        Text(LFormat("diskCleaner.itemsFound %lld", viewModel.totalItemCount))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 12)
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack {
            GlassTabPicker(
                tabs: DiskCleanerTab.allCases,
                selection: $selectedTab,
                icon: { $0.icon },
                label: { $0.localizedName },
                accentColor: sectionColor
            )

            Spacer()
        }
    }

    // MARK: - Cleaner Content

    @ViewBuilder
    private var cleanerContent: some View {
        if !viewModel.hasScanned {
            // Initial scan prompt
            scanPromptSection
        } else if viewModel.scanResults.isEmpty {
            // No junk found
            emptyStateSection
        } else {
            // Category list
            categoryListSection

            // Clean button
            cleanButtonSection
        }

        // Empty Trash card (always visible)
        emptyTrashSection
            .staggeredAnimation(index: 3, isActive: isVisible)
    }

    // MARK: - Scan Prompt

    private var scanPromptSection: some View {
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

                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(sectionColor.gradient)
                }
            }

            VStack(spacing: 8) {
                Text(L("diskCleaner.scan.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(L("diskCleaner.scan.description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            GlassActionButton(
                L("diskCleaner.scan.startButton"),
                icon: "magnifyingglass",
                color: sectionColor
            ) {
                viewModel.startScan()
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text(L("diskCleaner.empty.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(L("diskCleaner.empty.description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                Text(L("diskCleaner.scanAgain"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(sectionColor)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Category List

    private var categoryListSection: some View {
        VStack(spacing: 12) {
            // Selection controls
            HStack {
                Text(L("diskCleaner.categories"))
                    .font(Theme.Typography.headline)

                Spacer()

                Button(L("diskCleaner.selectAll")) {
                    viewModel.selectAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(sectionColor)

                Text("·")
                    .foregroundStyle(.tertiary)

                Button(L("diskCleaner.deselectAll")) {
                    viewModel.deselectAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(sectionColor)

                Button(action: viewModel.startScan) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(L("diskCleaner.rescan"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassCard(cornerRadius: 8)
                }
                .buttonStyle(.plain)
                .padding(.leading, 12)
            }

            // Category cards
            ForEach(viewModel.scanResults) { result in
                CleanupCategoryCard(
                    result: result,
                    isExpanded: viewModel.expandedCategory == result.category,
                    onToggleExpand: {
                        viewModel.toggleCategoryExpansion(result.category)
                    },
                    onToggleSelection: {
                        viewModel.toggleCategorySelection(result.category)
                    },
                    onToggleItem: { item in
                        viewModel.toggleItemSelection(item, in: result.category)
                    },
                    onViewDetails: {
                        viewModel.showDetails(for: result)
                    }
                )
            }
        }
    }

    // MARK: - Clean Button

    private var cleanButtonSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LFormat("diskCleaner.selected %@", viewModel.formattedSelectedSize))
                    .font(.system(size: 15, weight: .semibold))

                Text(LFormat("diskCleaner.itemCount %lld", viewModel.selectedItemCount))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("diskCleaner.clean"),
                icon: "trash.fill",
                color: sectionColor,
                disabled: viewModel.selectedItemCount == 0
            ) {
                viewModel.prepareClean()
            }
        }
        .padding(20)
        .glassCard()
        .shadow(color: sectionColor.opacity(0.2), radius: 15, y: 5)
    }

    // MARK: - Empty Trash Section

    private var emptyTrashSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Trash icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.orange.gradient)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(L("diskCleaner.emptyTrash.title"))
                    .font(Theme.Typography.subheadline.weight(.semibold))

                if viewModel.trashSize > 0 {
                    Text(LFormat("diskCleaner.emptyTrash.size %@", viewModel.formattedTrashSize))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(L("diskCleaner.emptyTrash.empty"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // FDA warning if needed - clickable to open settings
            if !viewModel.hasFullDiskAccess {
                Button(action: {
                    PermissionsService.shared.openFullDiskAccessSettings()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text(L("diskCleaner.emptyTrash.needsFDA"))
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help(L("diskCleaner.emptyTrash.clickToGrant"))
            }

            // Empty button
            Button(action: viewModel.prepareEmptyTrash) {
                HStack(spacing: 6) {
                    if viewModel.isEmptyingTrash {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .medium))
                    }
                    Text(viewModel.isEmptyingTrash ? L("diskCleaner.emptyTrash.emptying") : L("diskCleaner.emptyTrash.button"))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(viewModel.trashSize > 0 && !viewModel.isEmptyingTrash ? Color.orange : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(viewModel.trashSize > 0 ? 0.15 : 0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isEmptyingTrash || viewModel.trashSize == 0)
        }
        .padding(Theme.Spacing.md)
        .glassCard()
        .onAppear {
            viewModel.refreshTrashSize()
        }
    }
}

// MARK: - Scanning Overlay

struct ScanningOverlay: View {
    let progress: Double
    let category: String
    var accentColor: Color = .blue
    var onCancel: (() -> Void)? = nil

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        accentColor.gradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: progress)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(accentColor)
            }

            VStack(spacing: 4) {
                Text(L("common.scanning"))
                    .font(.system(size: 20, weight: .semibold))

                Text(category)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold).monospacedDigit())
                    .foregroundStyle(accentColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor.gradient)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(Theme.Animation.spring, value: progress)
                }
            }
            .frame(width: 200, height: 8)

            // Cancel button (optional)
            if let onCancel = onCancel {
                Button(action: onCancel) {
                    Text(L("common.cancel"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(28)
        .frame(width: 280)
        .glassCardProminent()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DiskCleanerView(viewModel: DiskCleanerViewModel(), spaceLensViewModel: SpaceLensViewModel())
        .frame(width: 800, height: 600)
}
