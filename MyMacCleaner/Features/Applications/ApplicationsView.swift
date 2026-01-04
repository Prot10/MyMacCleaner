import SwiftUI

// MARK: - Applications View

struct ApplicationsView: View {
    @StateObject private var viewModel = ApplicationsViewModel()
    @State private var isVisible = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Show different content based on state
                    if viewModel.analysisState == .completed {
                        // Full app list view
                        controlsSection
                            .staggeredAnimation(index: 1, isActive: isVisible)

                        if viewModel.filteredApps.isEmpty {
                            emptySection
                        } else {
                            appGridSection
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
                    .font(Theme.Typography.largeTitle)

                Text("Manage and uninstall applications")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if viewModel.analysisState == .completed {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.formattedTotalSize)
                        .font(Theme.Typography.title)
                        .foregroundStyle(.cyan)

                    Text("\(viewModel.applications.count) apps installed")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
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
                    .glassCard()
                }
            } else {
                // Start Analysis button
                VStack(spacing: Theme.Spacing.lg) {
                    // Description
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 48))
                            .foregroundStyle(.cyan.gradient)

                        Text("Ready to Analyze")
                            .font(Theme.Typography.title2)

                        Text("Click the button below to calculate the size of each application.\nThis helps identify which apps are using the most disk space.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                    }
                    .padding(.top, Theme.Spacing.lg)

                    // Start button
                    Button(action: viewModel.startFullAnalysis) {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "play.fill")
                            Text("Start Analysis")
                        }
                        .font(Theme.Typography.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                        .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.discoveryState == .discovering && viewModel.applications.isEmpty)

                    // Discovery status
                    if viewModel.discoveryState == .discovering {
                        HStack(spacing: Theme.Spacing.sm) {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 16, height: 16)

                            Text("Discovering apps in background...")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .glassCard()
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
                .glassCard()
            }
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search applications...", text: $viewModel.searchText)
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

            // Sort picker
            Picker("Sort", selection: $viewModel.sortOrder) {
                ForEach(ApplicationsViewModel.SortOrder.allCases, id: \.self) { order in
                    Text(order.rawValue).tag(order)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            // Refresh button
            Button(action: viewModel.refresh) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
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
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            }

            Text(title)
                .font(Theme.Typography.title.monospacedDigit())

            Text(subtitle)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .glassCard()
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
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Text("+\(count)")
                    .font(Theme.Typography.subheadline.weight(.semibold))
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
            .opacity(isHovered ? 1 : 0.7)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
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

// MARK: - Preview

#Preview {
    ApplicationsView()
        .frame(width: 900, height: 700)
}
