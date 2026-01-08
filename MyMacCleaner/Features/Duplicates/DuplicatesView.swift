import SwiftUI

struct DuplicatesView: View {
    @ObservedObject var viewModel: DuplicatesViewModel
    @State private var isVisible = false
    @State private var expandedGroup: UUID?

    private let sectionColor = Theme.Colors.duplicates

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
                    } else if viewModel.duplicateGroups.isEmpty && viewModel.hasScanned {
                        emptyStateSection
                            .staggeredAnimation(index: 1, isActive: isVisible)
                    } else {
                        // Stats overview
                        statsSection
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        // Controls
                        controlsSection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                        // Duplicate groups list
                        duplicateListSection
                            .staggeredAnimation(index: 3, isActive: isVisible)

                        // Clean button
                        if !viewModel.duplicateGroups.isEmpty {
                            cleanButtonSection
                                .staggeredAnimation(index: 4, isActive: isVisible)
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
                    category: viewModel.currentScanStatus,
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
        .alert(L("duplicates.clean.confirmTitle"), isPresented: $viewModel.showCleanConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelClean()
            }
            Button(L("duplicates.clean.moveToTrash"), role: .destructive) {
                viewModel.confirmClean()
            }
        } message: {
            Text(LFormat("duplicates.clean.confirmMessage %lld %@", Int64(viewModel.selectedCount), viewModel.formattedSelectedSize))
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
                Text(L("navigation.duplicates"))
                    .font(.system(size: 28, weight: .bold))

                Text(L("navigation.duplicates.description"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.hasScanned && !viewModel.duplicateGroups.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.formattedTotalWastedSize)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(sectionColor)

                        Text(LFormat("duplicates.wastedSpace %lld", Int64(viewModel.totalGroupCount)))
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

                    Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(sectionColor.gradient)
                }
            }

            VStack(spacing: 8) {
                Text(L("duplicates.scan.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(L("duplicates.scan.description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            // Scan location
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(sectionColor)

                    Text(viewModel.scanPath.path)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button(L("duplicates.chooseFolder")) {
                        viewModel.chooseScanLocation()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(sectionColor)
                }
                .padding(12)
                .glassCard(cornerRadius: 10)
            }

            GlassActionButton(
                L("duplicates.scan.startButton"),
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
                Text(L("duplicates.empty.title"))
                    .font(.system(size: 20, weight: .semibold))

                Text(L("duplicates.empty.description"))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.startScan) {
                Text(L("duplicates.scanAgain"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(sectionColor)
            }
            .buttonStyle(.plain)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.fileTypeStats.prefix(4), id: \.0) { type, count, size in
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(type.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: type.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(type.color)
                    }

                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(size: 16, weight: .semibold))

                        Text(type.rawValue)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassCard(cornerRadius: 12)
                .onTapGesture {
                    if viewModel.filterType == type {
                        viewModel.filterType = nil
                    } else {
                        viewModel.filterType = type
                    }
                }
                .overlay {
                    if viewModel.filterType == type {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(sectionColor, lineWidth: 2)
                    }
                }
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 12) {
            // Search
            GlassSearchField(
                text: $viewModel.searchText,
                placeholder: L("duplicates.search.placeholder")
            )
            .frame(maxWidth: 250)

            // Sort
            Menu {
                ForEach(DuplicatesViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(order.localizedName) {
                        viewModel.sortOrder = order
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(viewModel.sortOrder.localizedName)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 8)
            }
            .buttonStyle(.plain)

            if viewModel.filterType != nil || !viewModel.searchText.isEmpty {
                Button(action: viewModel.clearFilter) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text(L("duplicates.clearFilters"))
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Smart selection
            Menu {
                Button(L("duplicates.selectAllDuplicates")) {
                    viewModel.selectAllDuplicates()
                }
                Button(L("duplicates.keepNewest")) {
                    viewModel.selectOldestInEachGroup()
                }
                Divider()
                Button(L("diskCleaner.deselectAll")) {
                    viewModel.deselectAll()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checklist")
                    Text(L("duplicates.smartSelect"))
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(sectionColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: 8)
            }
            .buttonStyle(.plain)

            // Rescan
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
        }
    }

    // MARK: - Duplicate List

    private var duplicateListSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.filteredGroups) { group in
                DuplicateGroupCard(
                    group: group,
                    isExpanded: expandedGroup == group.id,
                    onToggleExpand: {
                        withAnimation(Theme.Animation.spring) {
                            expandedGroup = expandedGroup == group.id ? nil : group.id
                        }
                    },
                    onToggleFile: { file in
                        viewModel.toggleFileSelection(file, in: group)
                    },
                    onSetKept: { file in
                        viewModel.setKeptFile(file, in: group)
                    },
                    onReveal: { file in
                        viewModel.revealInFinder(file)
                    },
                    accentColor: sectionColor
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

                Text(LFormat("diskCleaner.itemCount %lld", Int64(viewModel.selectedCount)))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("duplicates.clean"),
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

// MARK: - Duplicate Group Card

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleFile: (DuplicateFile) -> Void
    let onSetKept: (DuplicateFile) -> Void
    let onReveal: (DuplicateFile) -> Void
    let accentColor: Color

    var selectedCount: Int {
        group.files.filter { $0.isSelected && !$0.isKept }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack(spacing: Theme.Spacing.md) {
                    // File type icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(group.fileType.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: group.fileType.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(group.fileType.color)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.files.first?.name ?? "Unknown")
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(LFormat("duplicates.copies %lld", Int64(group.files.count)))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)

                            Text("·")
                                .foregroundStyle(.tertiary)

                            Text(group.formattedSize)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Wasted size
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(group.formattedWastedSize)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(accentColor)

                        Text(L("duplicates.wasted"))
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(Theme.Spacing.md)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                VStack(spacing: 0) {
                    ForEach(group.files) { file in
                        DuplicateFileRow(
                            file: file,
                            onToggle: { onToggleFile(file) },
                            onSetKept: { onSetKept(file) },
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

// MARK: - Duplicate File Row

struct DuplicateFileRow: View {
    let file: DuplicateFile
    let onToggle: () -> Void
    let onSetKept: () -> Void
    let onReveal: () -> Void
    let accentColor: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Checkbox or kept indicator
            if file.isKept {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                }
                .help(L("duplicates.keepingThisCopy"))
            } else {
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
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.parentFolder)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(file.isKept ? .green : .primary)

                    if file.isKept {
                        Text(L("duplicates.keeping"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text(file.url.path)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Date
            Text(file.formattedDate)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)

            // Actions
            if isHovered {
                HStack(spacing: 8) {
                    if !file.isKept {
                        Button(action: onSetKept) {
                            Image(systemName: "star")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                        .buttonStyle(.plain)
                        .help(L("duplicates.keepThisCopy"))
                    }

                    Button(action: onReveal) {
                        Image(systemName: "folder")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L("common.revealInFinder"))
                }
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
    }
}

// MARK: - Preview

#Preview {
    DuplicatesView(viewModel: DuplicatesViewModel())
        .frame(width: 900, height: 700)
}
