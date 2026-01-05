import SwiftUI

// MARK: - Applications View

struct ApplicationsView: View {
    @ObservedObject var viewModel: ApplicationsViewModel
    @State private var isVisible = false
    @State private var selectedTab: AppTab = .allApps

    enum AppTab: String, CaseIterable {
        case allApps = "All Apps"
        case updates = "Updates"
        case homebrew = "Homebrew"
    }

    // Section color for applications
    private let sectionColor = Theme.Colors.apps

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Show different content based on state
                    if viewModel.analysisState == .completed {
                        // Tab picker
                        tabPicker
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        // Tab content
                        switch selectedTab {
                        case .allApps:
                            controlsSection
                                .staggeredAnimation(index: 2, isActive: isVisible)

                            if viewModel.filteredApps.isEmpty {
                                emptySection
                            } else {
                                appGridSection
                                    .staggeredAnimation(index: 3, isActive: isVisible)
                            }

                        case .updates:
                            updatesSection
                                .staggeredAnimation(index: 2, isActive: isVisible)

                        case .homebrew:
                            homebrewSection
                                .staggeredAnimation(index: 2, isActive: isVisible)
                        }
                    } else {
                        // Discovery / Pre-analysis view
                        infoCardsSection
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        analysisSection
                            .staggeredAnimation(index: 2, isActive: isVisible)
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
        .animation(Theme.Animation.spring, value: viewModel.analysisState)
        .sheet(isPresented: $viewModel.showUninstallConfirmation) {
            if let app = viewModel.appToUninstall {
                UninstallConfirmationSheet(
                    app: app,
                    relatedFiles: viewModel.relatedFiles,
                    isScanning: viewModel.isScanning,
                    onConfirm: viewModel.confirmUninstall,
                    onCancel: viewModel.cancelUninstall
                )
            }
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
            // Start background discovery when view appears
            viewModel.startBackgroundDiscovery()
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Applications")
                    .font(.system(size: 28, weight: .bold))

                Text("Manage and uninstall applications")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.analysisState == .completed {
                HStack(spacing: 16) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(viewModel.formattedTotalSize)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(sectionColor)

                        Text("\(viewModel.applications.count) apps installed")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Info Cards Section

    private var infoCardsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Apps Found Card
            InfoCard(
                icon: "square.grid.2x2.fill",
                iconColor: .cyan,
                title: "\(viewModel.applications.count)",
                subtitle: "Apps Found",
                isLoading: viewModel.discoveryState == .discovering
            )

            // System Apps Card
            InfoCard(
                icon: "gearshape.fill",
                iconColor: .orange,
                title: "\(systemAppsCount)",
                subtitle: "System Apps",
                isLoading: viewModel.discoveryState == .discovering
            )

            // User Apps Card
            InfoCard(
                icon: "person.fill",
                iconColor: .purple,
                title: "\(userAppsCount)",
                subtitle: "User Apps",
                isLoading: viewModel.discoveryState == .discovering
            )

            // Analysis Status Card
            InfoCard(
                icon: viewModel.analysisState == .analyzing ? "arrow.triangle.2.circlepath" : "chart.bar.fill",
                iconColor: .green,
                title: viewModel.analysisState == .analyzing ? "\(Int(viewModel.analysisProgress * 100))%" : "Ready",
                subtitle: viewModel.analysisState == .analyzing ? "Analyzing..." : "To Analyze",
                isLoading: viewModel.analysisState == .analyzing
            )
        }
    }

    private var systemAppsCount: Int {
        viewModel.applications.filter { $0.url.path.hasPrefix("/Applications") }.count
    }

    private var userAppsCount: Int {
        viewModel.applications.filter { !$0.url.path.hasPrefix("/Applications") }.count
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if viewModel.analysisState == .analyzing {
                // Progress view
                VStack(spacing: Theme.Spacing.md) {
                    // Progress bar
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Analyzing Applications...")
                                .font(Theme.Typography.headline)

                            Spacer()

                            Text("\(viewModel.appsWithSizeCalculated) / \(viewModel.applications.count)")
                                .font(Theme.Typography.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: viewModel.analysisProgress)
                            .progressViewStyle(.linear)
                            .tint(.cyan)

                        if !viewModel.currentAppBeingAnalyzed.isEmpty {
                            Text("Calculating size for: \(viewModel.currentAppBeingAnalyzed)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                }
            } else {
                // Start Analysis button
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

                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundStyle(sectionColor.gradient)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Analyze Applications")
                            .font(.system(size: 20, weight: .semibold))

                        Text("Calculate the size of each application to identify which apps are using the most disk space")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                    }

                    // Start button
                    GlassActionButton(
                        "Start Analysis",
                        icon: "play.fill",
                        color: sectionColor,
                        disabled: viewModel.discoveryState == .discovering && viewModel.applications.isEmpty
                    ) {
                        viewModel.startFullAnalysis()
                    }

                    // Discovery status
                    if viewModel.discoveryState == .discovering {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 16, height: 16)

                            Text("Discovering apps in background...")
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }

            // App preview (show some apps without sizes during discovery)
            if !viewModel.applications.isEmpty && viewModel.analysisState != .analyzing {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Discovered Apps")
                            .font(Theme.Typography.headline)

                        Spacer()

                        if viewModel.discoveryState == .discovering {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.mini)
                                    .frame(width: 10, height: 10)
                                Text("Discovering...")
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Show first 8 apps as preview
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: Theme.Spacing.sm)], spacing: Theme.Spacing.sm) {
                        ForEach(Array(viewModel.applications.prefix(8))) { app in
                            AppPreviewCard(app: app)
                        }

                        if viewModel.applications.count > 8 {
                            MoreAppsCard(count: viewModel.applications.count - 8)
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(Theme.Animation.spring) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tabIcon(for: tab))
                        Text(tab.rawValue)

                        // Badge for updates count
                        if tab == .updates && !viewModel.appUpdates.isEmpty {
                            Text("\(viewModel.appUpdates.count)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }

                        // Badge for outdated homebrew casks
                        if tab == .homebrew && !viewModel.outdatedCasks.isEmpty {
                            Text("\(viewModel.outdatedCasks.count)")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white.opacity(0.1))
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(4)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
    }

    private func tabIcon(for tab: AppTab) -> String {
        switch tab {
        case .allApps: return "square.grid.2x2"
        case .updates: return "arrow.down.circle"
        case .homebrew: return "shippingbox"
        }
    }

    // MARK: - Updates Section

    private var updatesSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Check for updates button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("App Updates")
                        .font(Theme.Typography.headline)

                    Text("Check for available updates via Sparkle feeds")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if viewModel.isCheckingUpdates {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("\(Int(viewModel.updateCheckProgress * 100))%")
                            .font(Theme.Typography.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                } else {
                    GlassActionButton(
                        "Check Updates",
                        icon: "arrow.clockwise",
                        color: .orange
                    ) {
                        viewModel.checkForUpdates()
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

            // Updates list
            if viewModel.appUpdates.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)

                    Text("All apps are up to date")
                        .font(Theme.Typography.headline)

                    Text("Click \"Check Updates\" to scan for new versions")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xxl)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    Text("\(viewModel.appUpdates.count) Update(s) Available")
                        .font(Theme.Typography.headline)

                    ForEach(viewModel.appUpdates) { update in
                        UpdateRow(update: update)
                    }
                }
                .padding(Theme.Spacing.lg)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Homebrew Section

    private var homebrewSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            if !viewModel.isHomebrewInstalled {
                // Homebrew not installed
                VStack(spacing: Theme.Spacing.lg) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    Text("Homebrew Not Installed")
                        .font(Theme.Typography.headline)

                    Text("Homebrew is a package manager for macOS. Install it to manage apps via the command line.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)

                    Link(destination: URL(string: "https://brew.sh")!) {
                        HStack {
                            Image(systemName: "globe")
                            Text("Visit brew.sh")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xxl)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
            } else {
                // Homebrew header with actions
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homebrew Casks")
                            .font(Theme.Typography.headline)

                        Text("\(viewModel.homebrewCasks.count) casks installed")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if viewModel.isLoadingHomebrew {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        HStack(spacing: Theme.Spacing.sm) {
                            if !viewModel.outdatedCasks.isEmpty {
                                GlassActionButton(
                                    "Upgrade All",
                                    icon: "arrow.up.circle.fill",
                                    color: .orange
                                ) {
                                    viewModel.upgradeAllCasks()
                                }
                            }

                            GlassActionButton(
                                "Cleanup",
                                icon: "trash",
                                color: .gray
                            ) {
                                viewModel.cleanupHomebrew()
                            }

                            GlassActionButton(
                                "Refresh",
                                icon: "arrow.clockwise",
                                color: sectionColor
                            ) {
                                viewModel.loadHomebrewStatus()
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))

                // Outdated casks
                if !viewModel.outdatedCasks.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("\(viewModel.outdatedCasks.count) Outdated Cask(s)")
                                .font(Theme.Typography.headline)
                        }

                        ForEach(viewModel.outdatedCasks, id: \.name) { cask in
                            HomebrewCaskRow(
                                cask: cask,
                                showUpdateBadge: true,
                                onUpgrade: { viewModel.upgradeCask(cask) },
                                onUninstall: { viewModel.uninstallCask(cask) }
                            )
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .glassEffect(.regular.tint(.orange), in: RoundedRectangle(cornerRadius: 16))
                }

                // All casks
                if viewModel.homebrewCasks.isEmpty {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)

                        Text("No casks installed")
                            .font(Theme.Typography.headline)

                        Text("Install apps via `brew install --cask <app>`")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.xxl)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Installed Casks")
                            .font(Theme.Typography.headline)

                        ForEach(viewModel.homebrewCasks.filter { cask in
                            !viewModel.outdatedCasks.contains(where: { $0.name == cask.name })
                        }, id: \.name) { cask in
                            HomebrewCaskRow(
                                cask: cask,
                                showUpdateBadge: false,
                                onUpgrade: nil,
                                onUninstall: { viewModel.uninstallCask(cask) }
                            )
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .onAppear {
            viewModel.loadHomebrewStatus()
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Search
            GlassSearchField(text: $viewModel.searchText, placeholder: "Search applications...")

            // Sort picker
            Menu {
                ForEach(ApplicationsViewModel.SortOrder.allCases, id: \.self) { order in
                    Button(action: { viewModel.sortOrder = order }) {
                        HStack {
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
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            }

            // Refresh button
            GlassActionButton(
                "Refresh",
                icon: "arrow.clockwise",
                color: sectionColor
            ) {
                viewModel.refresh()
            }
        }
    }

    // MARK: - Empty Section

    private var emptySection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No applications found")
                .font(Theme.Typography.headline)

            Text("Try adjusting your search")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    // MARK: - App Grid Section

    private var appGridSection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200, maximum: 250), spacing: Theme.Spacing.md)], spacing: Theme.Spacing.md) {
            ForEach(viewModel.filteredApps) { app in
                AppCard(
                    app: app,
                    onOpen: { viewModel.openApp(app) },
                    onReveal: { viewModel.revealInFinder(app) },
                    onUninstall: { viewModel.prepareUninstall(app) }
                )
            }
        }
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    var isLoading: Bool = false

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.title2.monospacedDigit())

                Text(subtitle)
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

// MARK: - App Preview Card (small, no actions)

struct AppPreviewCard: View {
    let app: AppInfo

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)

            Text(app.name)
                .font(Theme.Typography.caption)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }
}

// MARK: - More Apps Card

struct MoreAppsCard: View {
    let count: Int

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 44, height: 44)

                Text("+\(count)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Text("more")
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
    }
}

// MARK: - App Card

struct AppCard: View {
    let app: AppInfo
    let onOpen: () -> Void
    let onReveal: () -> Void
    let onUninstall: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Icon
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

            // Name
            Text(app.name)
                .font(Theme.Typography.subheadline.weight(.semibold))
                .lineLimit(1)

            // Size and version
            HStack(spacing: Theme.Spacing.xs) {
                Text(app.formattedSize)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(app.sizeCalculated ? .secondary : .tertiary)

                if let version = app.version {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("v\(version)")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Action buttons
            HStack(spacing: Theme.Spacing.sm) {
                Button(action: onOpen) {
                    Text("Open")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)

                Button(action: onUninstall) {
                    Text("Uninstall")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Open", action: onOpen)
            Button("Reveal in Finder", action: onReveal)
            Divider()
            Button("Uninstall", role: .destructive, action: onUninstall)
        }
    }
}

// MARK: - Uninstall Confirmation Sheet

struct UninstallConfirmationSheet: View {
    let app: AppInfo
    let relatedFiles: [URL]
    let isScanning: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    private var totalSize: Int64 {
        var size = app.size
        for file in relatedFiles {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: file.path),
               let fileSize = attrs[.size] as? Int64 {
                size += fileSize
            }
        }
        return size
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack {
                Image(nsImage: app.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Uninstall \(app.name)?")
                        .font(Theme.Typography.title2)

                    Text("This will move the app and related files to Trash")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            // Files to remove
            if isScanning {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                    Text("Scanning for related files...")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.lg)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Files to remove:")
                        .font(Theme.Typography.headline)

                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            // App itself
                            FileRow(url: app.url, size: app.size, isApp: true)

                            // Related files
                            ForEach(relatedFiles, id: \.self) { file in
                                FileRow(url: file, size: nil, isApp: false)
                            }
                        }
                    }
                    .frame(maxHeight: 200)

                    HStack {
                        Text("Total space to free:")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(Theme.Typography.headline)
                            .foregroundStyle(.green)
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
            }

            Divider()

            // Buttons
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Move to Trash", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isScanning)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(width: 500)
    }
}

// MARK: - File Row

struct FileRow: View {
    let url: URL
    let size: Int64?
    let isApp: Bool

    var body: some View {
        HStack {
            Image(systemName: isApp ? "app" : "doc")
                .font(.caption)
                .foregroundStyle(isApp ? .blue : .secondary)
                .frame(width: 20)

            Text(url.path)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            if let size = size {
                Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Update Row

struct UpdateRow: View {
    let update: AppUpdate

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon placeholder (we don't have app icon here)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(update.appName)
                    .font(Theme.Typography.subheadline.weight(.semibold))

                HStack(spacing: Theme.Spacing.xs) {
                    Text(update.currentVersion)
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(update.latestVersion)
                        .foregroundStyle(.orange)
                }
                .font(Theme.Typography.caption)
            }

            Spacer()

            // Source badge
            Text(update.source.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())

            // Download button
            if let downloadURL = update.downloadURL {
                Link(destination: downloadURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text("Download")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(isHovered ? 0.05 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { isHovered = $0 }
    }
}

// MARK: - Homebrew Cask Row

struct HomebrewCaskRow: View {
    let cask: HomebrewCask
    let showUpdateBadge: Bool
    let onUpgrade: (() -> Void)?
    let onUninstall: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(cask.displayName)
                        .font(Theme.Typography.subheadline.weight(.semibold))

                    if showUpdateBadge {
                        Text("Update")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: Theme.Spacing.xs) {
                    if let installedVersion = cask.installedVersion {
                        Text("v\(installedVersion)")
                            .foregroundStyle(.secondary)

                        if cask.hasUpdate {
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                            Text("v\(cask.version)")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("v\(cask.version)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(Theme.Typography.caption)

                if let description = cask.description {
                    Text(description)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: Theme.Spacing.sm) {
                if let homepage = cask.homepage {
                    Link(destination: homepage) {
                        Image(systemName: "globe")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }

                if let onUpgrade = onUpgrade {
                    Button(action: onUpgrade) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle")
                            Text("Upgrade")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onUninstall) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundStyle(.red)
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(isHovered ? 0.05 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#Preview {
    ApplicationsView(viewModel: ApplicationsViewModel())
        .frame(width: 900, height: 700)
}
