import SwiftUI

struct DiskCleanerView: View {
    @StateObject private var viewModel = DiskCleanerViewModel()
    @State private var isVisible = false
    @State private var selectedTab: DiskCleanerTab = .cleaner

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
            if selectedTab == .cleaner {
                cleanerContent
            } else {
                SpaceLensView()
            }
        }
        .animation(Theme.Animation.spring, value: selectedTab)
        .safeAreaInset(edge: .top) {
            tabPicker
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(DiskCleanerTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))

                        Text(tab.rawValue)
                            .font(Theme.Typography.subheadline)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(selectedTab == tab ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Cleaner Content

    private var cleanerContent: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    if !viewModel.hasScanned {
                        // Initial scan prompt
                        scanPromptSection
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    } else if viewModel.scanResults.isEmpty {
                        // No junk found
                        emptyStateSection
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    } else {
                        // Category list
                        categoryListSection
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        // Clean button
                        cleanButtonSection
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            // Scanning overlay
            if viewModel.isScanning {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ScanningOverlay(
                    progress: viewModel.scanProgress,
                    category: viewModel.currentScanCategory?.rawValue ?? "Preparing..."
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Cleaning overlay
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
                    .font(Theme.Typography.largeTitle)

                Text("Free up space by removing junk files")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.hasScanned && !viewModel.scanResults.isEmpty {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedTotalSize)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.orange)

                    Text("\(viewModel.totalItemCount) items found")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Scan Prompt

    private var scanPromptSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)

                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.blue.gradient)
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Scan Your Disk")
                    .font(Theme.Typography.title2)

                Text("Find cache files, logs, and other junk that's taking up space")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Start Scan")
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: Theme.Spacing.sm) {
                Text("Your Disk is Clean!")
                    .font(Theme.Typography.title2)

                Text("No junk files were found. Your Mac is running efficiently.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                Text("Scan Again")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Category List

    private var categoryListSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Selection controls
            HStack {
                Text("Categories")
                    .font(Theme.Typography.headline)

                Spacer()

                Button("Select All") {
                    viewModel.selectAll()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Text("·")
                    .foregroundStyle(.tertiary)

                Button("Deselect All") {
                    viewModel.deselectAll()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)

                Button(action: viewModel.startScan) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, Theme.Spacing.md)
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
                    .font(Theme.Typography.headline)

                Text("\(viewModel.selectedItemCount) items")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: viewModel.prepareClean) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                    Text("Clean")
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: viewModel.selectedItemCount > 0 ? [.orange, .orange.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.selectedItemCount == 0)
            .shadow(color: viewModel.selectedItemCount > 0 ? .orange.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .padding(Theme.Spacing.lg)
        .glassCardProminent()
    }
}

// MARK: - Scanning Overlay

struct ScanningOverlay: View {
    let progress: Double
    let category: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: progress)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text("Scanning...")
                    .font(Theme.Typography.title2)

                Text(category)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(Int(progress * 100))%")
                    .font(Theme.Typography.title.monospacedDigit())
                    .foregroundStyle(.blue)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(Theme.Animation.spring, value: progress)
                }
            }
            .frame(width: 200, height: 8)
        }
        .padding(Theme.Spacing.xl)
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
    DiskCleanerView()
        .frame(width: 800, height: 600)
}
