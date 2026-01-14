import SwiftUI

struct OrphanedFilesView: View {
    @ObservedObject var viewModel: OrphanedFilesViewModel
    @State private var isVisible = false

    private let sectionColor = Theme.Colors.orphans

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Content
                    if !viewModel.hasScanned && !viewModel.isScanning {
                        scanPromptSection
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    } else if viewModel.orphanedFiles.isEmpty && viewModel.hasScanned {
                        emptyStateSection
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    } else {
                        controlsSection
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        categoryListSection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                        if !viewModel.orphanedFiles.isEmpty {
                            cleanButtonSection
                                .staggeredAnimation(index: 3, isActive: isVisible)
                        }
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
                    category: viewModel.currentScanCategory,
                    accentColor: sectionColor
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
        .animation(Theme.Animation.springSmooth, value: viewModel.isScanning)
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .alert(L("orphans.clean.confirmTitle"), isPresented: $viewModel.showCleanConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelClean()
            }
            Button(L("orphans.clean.moveToTrash"), role: .destructive) {
                viewModel.confirmClean()
            }
        } message: {
            Text(LFormat("orphans.clean.confirmMessage %lld %@", Int64(viewModel.selectedCount), viewModel.formattedSelectedSize))
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
                Text(L("navigation.orphanedFiles"))
                    .font(Theme.Typography.size28Bold)

                Text(L("navigation.orphanedFiles.description"))
                    .font(Theme.Typography.size13)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.hasScanned && !viewModel.orphanedFiles.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.formattedTotalSize)
                            .font(Theme.Typography.size22Semibold)
                            .foregroundStyle(sectionColor)

                        Text(LFormat("orphans.filesFound %lld", Int64(viewModel.totalCount)))
                            .font(Theme.Typography.size11)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassCard(cornerRadius: 12)
            }
        }
    }

    // MARK: - Scan Prompt

    private var scanPromptSection: some View {
        VStack(spacing: 28) {
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

                    Image(systemName: "doc.questionmark.fill")
                        .font(Theme.Typography.size32Medium)
                        .foregroundStyle(sectionColor.gradient)
                }
            }

            VStack(spacing: 8) {
                Text(L("orphans.scan.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("orphans.scan.description"))
                    .font(Theme.Typography.size14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Info about what we scan
            VStack(alignment: .leading, spacing: 8) {
                ForEach([
                    ("folder.fill", L("orphans.info.applicationSupport")),
                    ("gearshape.fill", L("orphans.info.preferences")),
                    ("archivebox.fill", L("orphans.info.caches")),
                    ("shippingbox.fill", L("orphans.info.containers"))
                ], id: \.0) { icon, text in
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(Theme.Typography.size12)
                            .foregroundStyle(sectionColor)
                            .frame(width: 20)

                        Text(text)
                            .font(Theme.Typography.size12)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .glassCard(cornerRadius: 10)

            GlassActionButton(
                L("orphans.scan.startButton"),
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
                .font(Theme.Typography.size48)
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text(L("orphans.empty.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("orphans.empty.description"))
                    .font(Theme.Typography.size14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                Text(L("orphans.scanAgain"))
                    .font(Theme.Typography.size13Medium)
                    .foregroundStyle(sectionColor)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 12) {
            // Search
            GlassSearchField(
                text: $viewModel.searchText,
                placeholder: L("orphans.search.placeholder")
            )
            .frame(maxWidth: 250)

            // Sort
            Menu {
                ForEach(OrphanedFilesViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(order.localizedName) {
                        viewModel.sortOrder = order
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sortOrder.localizedName)
                }
                .font(Theme.Typography.size12Medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 8)
            }
            .buttonStyle(.plain)

            Spacer()

            // Selection controls
            Button(L("diskCleaner.selectAll")) {
                viewModel.selectAll()
            }
            .buttonStyle(.plain)
            .font(Theme.Typography.size12Medium)
            .foregroundStyle(sectionColor)

            Text("·")
                .foregroundStyle(.tertiary)

            Button(L("diskCleaner.deselectAll")) {
                viewModel.deselectAll()
            }
            .buttonStyle(.plain)
            .font(Theme.Typography.size12Medium)
            .foregroundStyle(sectionColor)

            // Rescan
            Button(action: viewModel.startScan) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text(L("diskCleaner.rescan"))
                }
                .font(Theme.Typography.size12Medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .glassCard(cornerRadius: 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Category List

    private var categoryListSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.categoriesWithFiles, id: \.self) { category in
                if let files = viewModel.filesByCategory[category], !files.isEmpty {
                    OrphanCategoryCard(
                        category: category,
                        files: files,
                        isExpanded: viewModel.expandedCategory == category,
                        onToggleExpand: {
                            viewModel.toggleCategoryExpansion(category)
                        },
                        onToggleFile: { file in
                            viewModel.toggleSelection(file)
                        },
                        onToggleAll: {
                            viewModel.toggleCategorySelection(category)
                        },
                        onReveal: { file in
                            viewModel.revealInFinder(file)
                        },
                        accentColor: sectionColor
                    )
                }
            }
        }
    }

    // MARK: - Clean Button

    private var cleanButtonSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(LFormat("diskCleaner.selected %@", viewModel.formattedSelectedSize))
                    .font(Theme.Typography.size15Semibold)

                Text(LFormat("diskCleaner.itemCount %lld", Int64(viewModel.selectedCount)))
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("orphans.clean"),
                icon: "trash.fill",
                color: sectionColor,
                disabled: viewModel.selectedCount == 0
            ) {
                viewModel.prepareClean()
            }
        }
        .padding(20)
        .glassCard()
        .shadow(color: sectionColor.opacity(0.2), radius: 15, y: 5)
    }
}

// MARK: - Orphan Category Card

struct OrphanCategoryCard: View {
    let category: OrphanCategory
    let files: [OrphanedFile]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleFile: (OrphanedFile) -> Void
    let onToggleAll: () -> Void
    let onReveal: (OrphanedFile) -> Void
    let accentColor: Color

    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }

    var allSelected: Bool {
        files.allSatisfy { $0.isSelected }
    }

    var someSelected: Bool {
        files.contains { $0.isSelected } && !allSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                // Checkbox for selecting all - separate hit area
                Button(action: onToggleAll) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(allSelected || someSelected ? accentColor : Color.secondary.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 20, height: 20)

                        if allSelected {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor)
                                .frame(width: 20, height: 20)

                            Image(systemName: "checkmark")
                                .font(Theme.Typography.size10Bold)
                                .foregroundStyle(.white)
                        } else if someSelected {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(accentColor.opacity(0.5))
                                .frame(width: 20, height: 20)

                            Image(systemName: "minus")
                                .font(Theme.Typography.size10Bold)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.leading, Theme.Spacing.md)
                    .padding(.trailing, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Expandable area - everything else
                HStack(spacing: Theme.Spacing.md) {
                    // Category icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(category.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: category.icon)
                            .font(Theme.Typography.size18)
                            .foregroundStyle(category.color)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(Theme.Typography.size15Semibold)

                        Text(LFormat("orphans.files %lld", Int64(files.count)))
                            .font(Theme.Typography.size12)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Size and selection
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(Theme.Typography.size14Semibold)
                            .foregroundStyle(accentColor)

                        if selectedCount > 0 {
                            Text(LFormat("orphans.selected %lld", Int64(selectedCount)))
                                .font(Theme.Typography.size11)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Theme.Typography.size12Semibold)
                        .foregroundStyle(.tertiary)
                }
                .padding(.trailing, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .contentShape(Rectangle())
                .onTapGesture(perform: onToggleExpand)
            }

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                // File list
                VStack(spacing: 0) {
                    ForEach(files) { file in
                        OrphanFileRow(
                            file: file,
                            onToggle: { onToggleFile(file) },
                            onReveal: { onReveal(file) },
                            accentColor: accentColor
                        )
                    }
                }
                .padding(.vertical, Theme.Spacing.sm)
            }
        }
        .glassCard()
    }
}

// MARK: - Orphan File Row

struct OrphanFileRow: View {
    let file: OrphanedFile
    let onToggle: () -> Void
    let onReveal: () -> Void
    let accentColor: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(file.isSelected ? accentColor : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if file.isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(Theme.Typography.size10Bold)
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.suspectedAppName)
                        .font(Theme.Typography.size13Medium)
                        .lineLimit(1)

                    if let bundleId = file.bundleIdPattern {
                        Text("(\(bundleId))")
                            .font(Theme.Typography.size11)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Text(file.url.path)
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Date
            if let days = file.daysSinceModified {
                Text(LFormat("orphans.daysAgo %lld", Int64(days)))
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.tertiary)
            }

            // Size
            Text(file.formattedSize)
                .font(Theme.Typography.size12.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 60, alignment: .trailing)

            // Reveal button
            if isHovered {
                Button(action: onReveal) {
                    Image(systemName: "folder")
                        .font(Theme.Typography.size12)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Preview

#Preview {
    OrphanedFilesView(viewModel: OrphanedFilesViewModel())
        .frame(width: 800, height: 600)
}
