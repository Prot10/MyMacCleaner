import SwiftUI

// MARK: - Browser Privacy View Model

@MainActor
class BrowserPrivacyViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var hasScanned = false

    @Published var items: [BrowserDataItem] = []
    @Published var showCleanConfirmation = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    private let service = BrowserCleanerService.shared

    // MARK: - Computed Properties

    var installedBrowsers: [BrowserType] {
        BrowserType.allCases.filter { $0.isInstalled }
    }

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var selectedCount: Int {
        items.filter { $0.isSelected }.count
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)
    }

    var itemsByBrowser: [BrowserType: [BrowserDataItem]] {
        Dictionary(grouping: items, by: { $0.browser })
    }

    var hasWarningItems: Bool {
        items.filter { $0.isSelected }.contains { $0.dataType.warningLevel != .low }
    }

    // MARK: - Actions

    func scan() {
        isScanning = true
        hasScanned = false

        Task {
            let scannedItems = await service.scanAllBrowsers()
            items = scannedItems
            hasScanned = true
            isScanning = false
        }
    }

    func toggleSelection(_ item: BrowserDataItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isSelected.toggle()
        }
    }

    func selectAllForBrowser(_ browser: BrowserType) {
        for i in items.indices where items[i].browser == browser {
            items[i].isSelected = true
        }
    }

    func deselectAllForBrowser(_ browser: BrowserType) {
        for i in items.indices where items[i].browser == browser {
            items[i].isSelected = false
        }
    }

    func selectAll() {
        for i in items.indices {
            items[i].isSelected = true
        }
    }

    func deselectAll() {
        for i in items.indices {
            items[i].isSelected = false
        }
    }

    func prepareClean() {
        guard selectedCount > 0 else { return }
        showCleanConfirmation = true
    }

    func confirmClean() {
        showCleanConfirmation = false
        isCleaning = true

        Task {
            let result = await service.cleanItems(items)

            isCleaning = false

            if result.errors.isEmpty {
                toastMessage = LFormat("privacy.clean.success %lld %@", Int64(result.cleaned), ByteCountFormatter.string(fromByteCount: result.freedSpace, countStyle: .file))
                toastType = .success
            } else {
                toastMessage = LFormat("privacy.clean.partial %lld %lld", Int64(result.cleaned), Int64(result.errors.count))
                toastType = .error
            }
            showToast = true

            // Rescan to update UI
            scan()

            // Auto-dismiss toast
            try? await Task.sleep(for: .seconds(3))
            showToast = false
        }
    }

    func cancelClean() {
        showCleanConfirmation = false
    }

    func dismissToast() {
        showToast = false
    }
}

// MARK: - Browser Privacy View

struct BrowserPrivacyView: View {
    @ObservedObject var viewModel: BrowserPrivacyViewModel
    @State private var expandedBrowser: BrowserType?

    private let privacyColor = Color.orange

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if !viewModel.hasScanned && !viewModel.isScanning {
                scanPromptSection
            } else if viewModel.items.isEmpty && viewModel.hasScanned {
                emptyStateSection
            } else {
                browserListSection
                if !viewModel.items.isEmpty {
                    cleanButtonSection
                }
            }
        }
        .overlay {
            if viewModel.isScanning {
                ScanningOverlay(
                    progress: 0.5,
                    category: L("privacy.scanning"),
                    accentColor: privacyColor
                )
            }
        }
        .overlay {
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
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .alert(L("privacy.clean.confirmTitle"), isPresented: $viewModel.showCleanConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelClean()
            }
            Button(L("privacy.clean.delete"), role: .destructive) {
                viewModel.confirmClean()
            }
        } message: {
            VStack {
                Text(LFormat("privacy.clean.confirmMessage %lld %@", Int64(viewModel.selectedCount), viewModel.formattedSelectedSize))
                if viewModel.hasWarningItems {
                    Text(L("privacy.clean.warning"))
                        .foregroundStyle(.red)
                }
            }
        }
    }

    // MARK: - Scan Prompt

    private var scanPromptSection: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(privacyColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Circle()
                                .strokeBorder(privacyColor.opacity(0.3), lineWidth: 1)
                        }

                    Image(systemName: "hand.raised.fill")
                        .font(Theme.Typography.size32Medium)
                        .foregroundStyle(privacyColor.gradient)
                }
            }

            VStack(spacing: Theme.Spacing.xs) {
                Text(L("privacy.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("privacy.description"))
                    .font(Theme.Typography.size14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Installed browsers
            HStack(spacing: Theme.Spacing.lg) {
                ForEach(viewModel.installedBrowsers) { browser in
                    HStack(spacing: 6) {
                        Image(systemName: browser.icon)
                            .font(Theme.Typography.size14)
                        Text(browser.rawValue)
                            .font(Theme.Typography.size13)
                    }
                    .foregroundStyle(.secondary)
                }
            }

            GlassActionButton(
                L("privacy.scan"),
                icon: "magnifyingglass",
                color: privacyColor
            ) {
                viewModel.scan()
            }
        }
        .padding(Theme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Empty State

    private var emptyStateSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(Theme.Typography.size48)
                .foregroundStyle(.green)

            VStack(spacing: Theme.Spacing.xs) {
                Text(L("privacy.empty.title"))
                    .font(Theme.Typography.size20Semibold)

                Text(L("privacy.empty.description"))
                    .font(Theme.Typography.size14)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: viewModel.scan) {
                Text(L("privacy.scanAgain"))
                    .font(Theme.Typography.size13Medium)
                    .foregroundStyle(privacyColor)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    // MARK: - Browser List

    private var browserListSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                Text(L("privacy.browserData"))
                    .font(Theme.Typography.headline)

                Spacer()

                Button(L("diskCleaner.selectAll")) {
                    viewModel.selectAll()
                }
                .buttonStyle(.plain)
                .font(Theme.Typography.size12Medium)
                .foregroundStyle(privacyColor)

                Text("·")
                    .foregroundStyle(.tertiary)

                Button(L("diskCleaner.deselectAll")) {
                    viewModel.deselectAll()
                }
                .buttonStyle(.plain)
                .font(Theme.Typography.size12Medium)
                .foregroundStyle(privacyColor)

                Button(action: viewModel.scan) {
                    HStack(spacing: Theme.Spacing.xxs) {
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
                .padding(.leading, 12)
            }

            // Browser cards
            ForEach(viewModel.installedBrowsers) { browser in
                if let browserItems = viewModel.itemsByBrowser[browser], !browserItems.isEmpty {
                    BrowserDataCard(
                        browser: browser,
                        items: browserItems,
                        isExpanded: expandedBrowser == browser,
                        onToggleExpand: {
                            withAnimation(Theme.Animation.spring) {
                                expandedBrowser = expandedBrowser == browser ? nil : browser
                            }
                        },
                        onToggleItem: { item in
                            viewModel.toggleSelection(item)
                        },
                        onToggleAll: {
                            // If all selected, deselect all; otherwise select all
                            let allSelected = browserItems.allSatisfy { $0.isSelected }
                            if allSelected {
                                viewModel.deselectAllForBrowser(browser)
                            } else {
                                viewModel.selectAllForBrowser(browser)
                            }
                        },
                        accentColor: privacyColor
                    )
                }
            }
        }
    }

    // MARK: - Clean Button

    private var cleanButtonSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(LFormat("diskCleaner.selected %@", viewModel.formattedSelectedSize))
                    .font(Theme.Typography.size15Semibold)

                Text(LFormat("diskCleaner.itemCount %lld", Int64(viewModel.selectedCount)))
                    .font(Theme.Typography.size11)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("privacy.clean"),
                icon: "trash.fill",
                color: privacyColor,
                disabled: viewModel.selectedCount == 0
            ) {
                viewModel.prepareClean()
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
        .shadow(color: privacyColor.opacity(0.2), radius: 15, y: 5)
    }
}

// MARK: - Browser Data Card

struct BrowserDataCard: View {
    let browser: BrowserType
    let items: [BrowserDataItem]
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleItem: (BrowserDataItem) -> Void
    let onToggleAll: () -> Void
    let accentColor: Color

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }

    var allSelected: Bool {
        items.allSatisfy { $0.isSelected }
    }

    var someSelected: Bool {
        items.contains { $0.isSelected } && !allSelected
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
                    // Browser icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: browser.icon)
                            .font(Theme.Typography.size18)
                            .foregroundStyle(accentColor)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(browser.rawValue)
                            .font(Theme.Typography.size15Semibold)

                        Text(LFormat("privacy.items %lld", Int64(items.count)))
                            .font(Theme.Typography.size12)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Size
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(Theme.Typography.size14Semibold)
                            .foregroundStyle(accentColor)

                        if selectedSize > 0 && selectedSize < totalSize {
                            Text(LFormat("privacy.selected %@", ByteCountFormatter.string(fromByteCount: selectedSize, countStyle: .file)))
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

                VStack(spacing: 0) {
                    ForEach(items) { item in
                        BrowserDataItemRow(
                            item: item,
                            onToggle: { onToggleItem(item) },
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

// MARK: - Browser Data Item Row

struct BrowserDataItemRow: View {
    let item: BrowserDataItem
    let onToggle: () -> Void
    let accentColor: Color

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Theme.Spacing.sm) {
                // Checkbox
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(item.isSelected ? accentColor : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 18, height: 18)

                    if item.isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(Theme.Typography.size10Bold)
                            .foregroundStyle(.white)
                    }
                }

                // Icon
                Image(systemName: item.dataType.icon)
                    .font(Theme.Typography.size14)
                    .foregroundStyle(accentColor.opacity(0.8))
                    .frame(width: 24)

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.dataType.rawValue)
                            .font(Theme.Typography.size13Medium)

                        // Warning indicator
                        if let warning = item.dataType.warningLevel.message {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(Theme.Typography.size10)
                                .foregroundStyle(.orange)
                                .help(warning)
                        }
                    }

                    Text(item.dataType.description)
                        .font(Theme.Typography.size11)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Size
                Text(item.formattedSize)
                    .font(Theme.Typography.size12.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    BrowserPrivacyView(viewModel: BrowserPrivacyViewModel())
        .frame(width: 600, height: 500)
}
