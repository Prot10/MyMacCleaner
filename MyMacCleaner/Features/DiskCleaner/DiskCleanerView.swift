import SwiftUI

struct DiskCleanerView: View {
    @ObservedObject var viewModel: DiskCleanerViewModel
    @ObservedObject var spaceLensViewModel: SpaceLensViewModel
    @State private var isVisible = false
    @State private var selectedTab: DiskCleanerTab = .cleaner

    // Section color for disk cleaner
    private let sectionColor = Theme.Colors.storage

    enum DiskCleanerTab: String, CaseIterable {
        case cleaner = "Cleaner"
        case spaceLens = "Space Lens"

        var icon: String {
            switch self {
            case .cleaner: return "trash"
            case .spaceLens: return "circle.hexagongrid.fill"
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
                    category: viewModel.currentScanCategory?.rawValue ?? "Preparing...",
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
                        type: homeToastType,
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
        .alert("Clean Selected Items?", isPresented: $viewModel.showCleanConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelClean()
            }
            Button("Move to Trash", role: .destructive) {
                viewModel.confirmClean()
            }
        } message: {
            Text("This will move \(viewModel.selectedItemCount) items (\(viewModel.formattedSelectedSize)) to the Trash. You can restore them from the Trash if needed.")
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    // Convert toast type
    private var homeToastType: HomeViewModel.ToastType {
        switch viewModel.toastType {
        case .success: return .success
        case .error: return .error
        case .info: return .info
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Disk Cleaner")
                    .font(.system(size: 28, weight: .bold))

                Text("Free up space by removing junk files")
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

                        Text("\(viewModel.totalItemCount) items found")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(sectionColor.opacity(0.1))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(sectionColor.opacity(0.2), lineWidth: 0.5)
                        }
                }
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
                label: { $0.rawValue },
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
                Text("Scan Your Disk")
                    .font(.system(size: 20, weight: .semibold))

                Text("Find cache files, logs, and other junk that's taking up space")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            GlassActionButton(
                "Start Scan",
                icon: "magnifyingglass",
                color: sectionColor
            ) {
                viewModel.startScan()
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Your Disk is Clean!")
                    .font(.system(size: 20, weight: .semibold))

                Text("No junk files were found. Your Mac is running efficiently.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                Text("Scan Again")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(sectionColor)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Category List

    private var categoryListSection: some View {
        VStack(spacing: 12) {
            // Selection controls
            HStack {
                Text("Categories")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Button("Select All") {
                    viewModel.selectAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(sectionColor)

                Text("·")
                    .foregroundStyle(.tertiary)

                Button("Deselect All") {
                    viewModel.deselectAll()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(sectionColor)

                Button(action: viewModel.startScan) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.05))
                    }
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
                Text("Selected: \(viewModel.formattedSelectedSize)")
                    .font(.system(size: 15, weight: .semibold))

                Text("\(viewModel.selectedItemCount) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                "Clean",
                icon: "trash.fill",
                color: sectionColor,
                disabled: viewModel.selectedItemCount == 0
            ) {
                viewModel.prepareClean()
            }
        }
        .padding(20)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: sectionColor.opacity(0.2), radius: 15, y: 5)
    }
}

// MARK: - Scanning Overlay

struct ScanningOverlay: View {
    let progress: Double
    let category: String
    var accentColor: Color = .blue

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
                Text("Scanning...")
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
