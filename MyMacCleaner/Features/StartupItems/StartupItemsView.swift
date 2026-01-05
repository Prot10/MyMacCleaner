import SwiftUI

// MARK: - Startup Items View

struct StartupItemsView: View {
    @ObservedObject var viewModel: StartupItemsViewModel
    @State private var isVisible = false

    // Section color for startup items
    private let sectionColor = Theme.Colors.startup

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Stats cards
                    statsSection
                        .staggeredAnimation(index: 1, isActive: isVisible)

                    // Content
                    if viewModel.items.isEmpty && !viewModel.isLoading {
                        // Initial state - show scan prompt
                        scanPromptSection
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    } else if viewModel.isLoading {
                        loadingSection
                            .staggeredAnimation(index: 2, isActive: isVisible)
                    } else {
                        // Controls
                        controlsSection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                        // Items list
                        itemsSection
                            .staggeredAnimation(index: 3, isActive: isVisible)
                    }
                }
                .padding(Theme.Spacing.lg)
            }

            // Toast
            if viewModel.showToast {
                VStack {
                    ToastView(
                        message: viewModel.toastMessage,
                        type: toastType,
                        onDismiss: viewModel.dismissToast
                    )
                    .padding(.top, Theme.Spacing.lg)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .alert("Disable Startup Item?", isPresented: $viewModel.showDisableConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelToggle()
            }
            Button(viewModel.itemToToggle?.isEnabled == true ? "Disable" : "Enable") {
                viewModel.confirmToggle()
            }
        } message: {
            if let item = viewModel.itemToToggle {
                if item.isEnabled {
                    Text("This will prevent \"\(item.displayName)\" from running at startup. You can re-enable it later.")
                } else {
                    Text("This will allow \"\(item.displayName)\" to run at startup.")
                }
            }
        }
        .alert("Remove Startup Item?", isPresented: $viewModel.showRemoveConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelRemove()
            }
            Button("Remove", role: .destructive) {
                viewModel.confirmRemove()
            }
        } message: {
            if let item = viewModel.itemToRemove {
                Text("This will permanently remove \"\(item.displayName)\" from startup items. The item will be moved to Trash.")
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    private var toastType: HomeViewModel.ToastType {
        switch viewModel.toastType {
        case .success: return .success
        case .error: return .error
        case .info: return .info
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Startup Items")
                    .font(.system(size: 28, weight: .bold))

                Text("Manage apps and services that launch at startup")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !viewModel.items.isEmpty {
                GlassActionButton(
                    "Refresh",
                    icon: viewModel.isLoading ? nil : "arrow.clockwise",
                    color: sectionColor,
                    disabled: viewModel.isLoading
                ) {
                    viewModel.refreshItems()
                }
                .overlay {
                    if viewModel.isLoading {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            StartupStatCard(
                title: "Total Items",
                value: "\(viewModel.items.filter { !$0.isSystemItem }.count)",
                icon: "list.bullet",
                color: .blue
            )

            StartupStatCard(
                title: "Enabled",
                value: "\(viewModel.enabledCount)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StartupStatCard(
                title: "Disabled",
                value: "\(viewModel.disabledCount)",
                icon: "xmark.circle.fill",
                color: .orange
            )

            StartupStatCard(
                title: "Running",
                value: "\(viewModel.runningCount)",
                icon: "play.circle.fill",
                color: .purple
            )
        }
    }

    // MARK: - Scan Prompt Section

    private var scanPromptSection: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "power.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.cyan.gradient)
            }

            VStack(spacing: Theme.Spacing.sm) {
                Text("Scan Startup Items")
                    .font(Theme.Typography.title)

                Text("Discover all apps, agents, and daemons that run when your Mac starts")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            GlassActionButton(
                "Scan Startup Items",
                icon: "magnifyingglass",
                color: .cyan
            ) {
                viewModel.scanItems()
            }

            // Info about what will be scanned
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("What will be scanned:")
                    .font(Theme.Typography.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: Theme.Spacing.lg) {
                    ForEach(StartupItemType.allCases, id: \.self) { type in
                        HStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.caption)
                            Text(type.rawValue)
                                .font(Theme.Typography.caption)
                        }
                        .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.top, Theme.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .frame(width: 32, height: 32)

            Text("Scanning startup items...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search items...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)

                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.sm)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            .frame(maxWidth: 300)

            // Type filter
            Menu {
                Button(action: { viewModel.selectedType = nil }) {
                    HStack {
                        Text("All Types")
                        if viewModel.selectedType == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Divider()

                ForEach(StartupItemType.allCases, id: \.self) { type in
                    Button(action: { viewModel.selectedType = type }) {
                        HStack {
                            Image(systemName: type.icon)
                            Text(type.rawValue)
                            if viewModel.selectedType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.selectedType?.icon ?? "line.3.horizontal.decrease.circle")
                    Text(viewModel.selectedType?.rawValue ?? "All Types")
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }

            // Sort order
            Menu {
                ForEach(StartupItemsViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(action: { viewModel.sortOrder = order }) {
                        HStack {
                            Image(systemName: order.icon)
                            Text(order.rawValue)
                            if viewModel.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sort: \(viewModel.sortOrder.rawValue)")
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }

            Spacer()

            // Show system items toggle
            Toggle(isOn: $viewModel.showSystemItems) {
                Text("System Items")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }

    // MARK: - Items Section

    private var itemsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            if viewModel.filteredItems.isEmpty {
                emptyFilterSection
            } else {
                ForEach(viewModel.filteredItems) { item in
                    StartupItemRow(
                        item: item,
                        onToggle: { viewModel.prepareToggle(item) },
                        onRemove: { viewModel.prepareRemove(item) },
                        onReveal: { viewModel.revealInFinder(item) }
                    )
                }
            }
        }
    }

    private var emptyFilterSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("No matching items")
                .font(Theme.Typography.headline)

            Text("Try adjusting your search or filters")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Startup Stat Card

struct StartupStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Theme.Typography.title2.monospacedDigit())

                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Startup Item Row

struct StartupItemRow: View {
    let item: StartupItem
    let onToggle: () -> Void
    let onRemove: () -> Void
    let onReveal: () -> Void

    @State private var isHovered = false
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: Theme.Spacing.md) {
                // Type icon with status indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(item.typeColor)

                    // Running indicator
                    if item.isRunning {
                        Circle()
                            .fill(.green)
                            .frame(width: 10, height: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .offset(x: 14, y: -14)
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(item.displayName)
                            .font(Theme.Typography.subheadline.weight(.medium))
                            .lineLimit(1)

                        if item.isSystemItem {
                            Text("System")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }

                    Text(item.label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)

                    if let developer = item.developer {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.system(size: 9))
                            Text(developer)
                                .font(Theme.Typography.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Type badge
                Text(item.type.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(item.typeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.typeColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.isEnabled ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)

                    Text(item.isEnabled ? "Enabled" : "Disabled")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 80)

                // Actions
                if !item.isSystemItem {
                    HStack(spacing: Theme.Spacing.sm) {
                        // Toggle button
                        Button(action: onToggle) {
                            Image(systemName: item.isEnabled ? "pause.circle" : "play.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(item.isEnabled ? .orange : .green)
                        }
                        .buttonStyle(.plain)
                        .help(item.isEnabled ? "Disable" : "Enable")

                        // Menu with more options
                        Menu {
                            Button(action: onReveal) {
                                Label("Show in Finder", systemImage: "folder")
                            }

                            Divider()

                            Button(role: .destructive, action: onRemove) {
                                Label("Remove", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 24)
                    }
                    .opacity(isHovered ? 1 : 0.6)
                } else {
                    // System items can only be revealed
                    Button(action: onReveal) {
                        Image(systemName: "folder")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")
                    .opacity(isHovered ? 1 : 0.6)
                }

                // Expand button
                Button(action: { withAnimation(Theme.Animation.spring) { isExpanded.toggle() } }) {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.md)
            .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
            .onHover { isHovered = $0 }

            // Expanded details
            if isExpanded {
                Divider()
                    .padding(.horizontal, Theme.Spacing.md)

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    DetailRow(label: "Label", value: item.label)
                    DetailRow(label: "Path", value: item.path)
                    if let execPath = item.executablePath {
                        DetailRow(label: "Executable", value: execPath)
                    }
                    if let bundleId = item.bundleIdentifier {
                        DetailRow(label: "Bundle ID", value: bundleId)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Color.white.opacity(0.02))
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .trailing)

            Text(value)
                .font(Theme.Typography.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    StartupItemsView(viewModel: StartupItemsViewModel())
        .frame(width: 900, height: 700)
}
