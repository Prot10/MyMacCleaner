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
                    accentColor: sectionColor,
                    onCancel: { viewModel.cancelScan() }
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
                    .font(Theme.Typography.size28Bold)

                HStack(spacing: 8) {
                    Text(L("navigation.duplicates.description"))
                        .font(Theme.Typography.size13)
                        .foregroundStyle(.secondary)

                    if viewModel.hasScanned {
                        Text("•")
                            .foregroundStyle(.tertiary)

                        Button(action: viewModel.chooseScanLocation) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                    .font(Theme.Typography.size10)
                                Text(viewModel.scanPath.lastPathComponent)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(Theme.Typography.size8)
                            }
                            .font(Theme.Typography.size12)
                            .foregroundStyle(sectionColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            if viewModel.hasScanned && !viewModel.duplicateGroups.isEmpty {
                HStack(spacing: 12) {
                    // Rescan button
                    Button(action: viewModel.startScan) {
                        Image(systemName: "arrow.clockwise")
                            .font(Theme.Typography.size14)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help(L("duplicates.scanAgain"))

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.formattedTotalWastedSize)
                            .font(Theme.Typography.size22Semibold)
                            .foregroundStyle(sectionColor)

                        Text(LFormat("duplicates.wastedSpace %lld", Int64(viewModel.totalGroupCount)))
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

                    Image(systemName: "doc.on.doc.fill")
                        .font(Theme.Typography.size32Medium)
                        .foregroundStyle(sectionColor.gradient)
                }
            }

            VStack(spacing: 8) {
                Text(L("duplicates.scan.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("duplicates.scan.description"))
                    .font(Theme.Typography.size14)
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
                        .font(Theme.Typography.size13)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button(L("duplicates.chooseFolder")) {
                        viewModel.chooseScanLocation()
                    }
                    .buttonStyle(.plain)
                    .font(Theme.Typography.size12Medium)
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
                .font(Theme.Typography.size48)
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text(L("duplicates.empty.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("duplicates.empty.description"))
                    .font(Theme.Typography.size14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Current scan location
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(Theme.Typography.size12)
                    .foregroundStyle(.secondary)

                Text(viewModel.scanPath.lastPathComponent)
                    .font(Theme.Typography.size12)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.05))
            .cornerRadius(6)

            HStack(spacing: 16) {
                Button(action: viewModel.chooseScanLocation) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.gearshape")
                        Text(L("duplicates.changeFolder"))
                    }
                    .font(Theme.Typography.size13Medium)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button(action: viewModel.startScan) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text(L("duplicates.scanAgain"))
                    }
                    .font(Theme.Typography.size13Medium)
                    .foregroundStyle(sectionColor)
                }
                .buttonStyle(.plain)
            }
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
                            .font(Theme.Typography.size16)
                            .foregroundStyle(type.color)
                    }

                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(Theme.Typography.size16Semibold)

                        Text(type.rawValue)
                            .font(Theme.Typography.size11)
                            .foregroundStyle(.secondary)

                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                            .font(Theme.Typography.size10)
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
        HStack(spacing: Theme.ControlSize.controlSpacing) {
            // Search
            GlassSearchField(
                text: $viewModel.searchText,
                placeholder: L("duplicates.search.placeholder")
            )

            // Sort
            GlassMenuButton(
                icon: "arrow.up.arrow.down",
                title: viewModel.sortOrder.localizedName
            ) {
                ForEach(DuplicatesViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(order.localizedName) {
                        viewModel.sortOrder = order
                    }
                }
            }

            if viewModel.filterType != nil || !viewModel.searchText.isEmpty {
                Button(action: viewModel.clearFilter) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text(L("duplicates.clearFilters"))
                    }
                    .font(Theme.ControlSize.controlFont)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Smart selection
            GlassMenuButton(
                icon: "checklist",
                title: L("duplicates.smartSelect")
            ) {
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
            }

            // Rescan
            Button(action: viewModel.startScan) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text(L("diskCleaner.rescan"))
                }
                .font(Theme.ControlSize.controlFont)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.ControlSize.horizontalPadding)
                .padding(.vertical, Theme.ControlSize.verticalPadding)
                .frame(height: Theme.ControlSize.toolbarHeight)
                .glassCard(cornerRadius: Theme.ControlSize.controlRadius)
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
                    onToggleAll: {
                        viewModel.toggleAllInGroup(group)
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
                    .font(Theme.Typography.size15Semibold)

                Text(LFormat("diskCleaner.itemCount %lld", Int64(viewModel.selectedCount)))
                    .font(Theme.Typography.size11)
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
    let onToggleAll: () -> Void
    let onSetKept: (DuplicateFile) -> Void
    let onReveal: (DuplicateFile) -> Void
    let accentColor: Color

    // Files that can be selected (not the kept one)
    var selectableFiles: [DuplicateFile] {
        group.files.filter { !$0.isKept }
    }

    var selectedCount: Int {
        selectableFiles.filter { $0.isSelected }.count
    }

    var allSelected: Bool {
        selectableFiles.allSatisfy { $0.isSelected }
    }

    var someSelected: Bool {
        selectableFiles.contains { $0.isSelected } && !allSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 0) {
                // Checkbox for selecting all duplicates - separate hit area
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
                    // File type icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(group.fileType.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: group.fileType.icon)
                            .font(Theme.Typography.size18)
                            .foregroundStyle(group.fileType.color)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.files.first?.name ?? "Unknown")
                            .font(Theme.Typography.size15Semibold)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            Text(LFormat("duplicates.copies %lld", Int64(group.files.count)))
                                .font(Theme.Typography.size12)
                                .foregroundStyle(.secondary)

                            Text("·")
                                .foregroundStyle(.tertiary)

                            Text(group.formattedSize)
                                .font(Theme.Typography.size12)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Wasted size
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(group.formattedWastedSize)
                            .font(Theme.Typography.size14Semibold)
                            .foregroundStyle(accentColor)

                        if selectedCount > 0 {
                            Text(LFormat("duplicates.selectedCount %lld", Int64(selectedCount)))
                                .font(Theme.Typography.size11)
                                .foregroundStyle(.secondary)
                        } else {
                            Text(L("duplicates.wasted"))
                                .font(Theme.Typography.size11)
                                .foregroundStyle(.tertiary)
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
            // Keep button - always visible, acts like radio button
            Button(action: onSetKept) {
                ZStack {
                    // Larger invisible hit area
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)

                    // Visible circle
                    Circle()
                        .stroke(file.isKept ? Color.green : Color.secondary.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if file.isKept {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
                .contentShape(Circle().scale(1.6))
            }
            .buttonStyle(.plain)
            .help(file.isKept ? L("duplicates.keepingThisCopy") : L("duplicates.keepThisCopy"))

            // Delete checkbox - only for non-kept files
            if file.isKept {
                // Spacer to align with checkbox width
                Color.clear
                    .frame(width: 18, height: 18)
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

                            Image(systemName: "trash.fill")
                                .font(Theme.Typography.size9Bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(file.isSelected ? L("duplicates.willDelete") : L("duplicates.markForDeletion"))
            }

            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.parentFolder)
                        .font(Theme.Typography.size13Medium)
                        .foregroundStyle(file.isKept ? .green : (file.isSelected ? accentColor : .primary))

                    if file.isKept {
                        Text(L("duplicates.keeping"))
                            .font(Theme.Typography.size10Medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    } else if file.isSelected {
                        Text(L("duplicates.willBeDeleted"))
                            .font(Theme.Typography.size10Medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.8))
                            .cornerRadius(4)
                    }
                }

                Text(file.url.path)
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.secondary)
                    .opacity(file.isSelected && !file.isKept ? 0.6 : 1.0)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .strikethrough(file.isSelected && !file.isKept, color: Color.secondary.opacity(0.5))
            }

            Spacer()

            // Date
            Text(file.formattedDate)
                .font(Theme.Typography.size11)
                .foregroundStyle(.tertiary)

            // Size
            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                .font(Theme.Typography.size11.monospacedDigit())
                .foregroundStyle(file.isSelected && !file.isKept ? accentColor : .secondary)
                .frame(minWidth: 60, alignment: .trailing)

            // Reveal in Finder - always visible
            Button(action: onReveal) {
                Image(systemName: "folder")
                    .font(Theme.Typography.size12)
                    .foregroundStyle(isHovered ? .secondary : .tertiary)
            }
            .buttonStyle(.plain)
            .help(L("common.revealInFinder"))
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(file.isKept ? Color.green.opacity(0.08) : (file.isSelected ? accentColor.opacity(0.05) : (isHovered ? Color.white.opacity(0.03) : Color.clear)))
        )
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
