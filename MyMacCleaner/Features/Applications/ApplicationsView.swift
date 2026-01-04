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

                    // Search and controls
                    controlsSection
                        .staggeredAnimation(index: 1, isActive: isVisible)

                    // App grid
                    if viewModel.isLoading {
                        loadingSection
                    } else if viewModel.filteredApps.isEmpty {
                        emptySection
                    } else {
                        appGridSection
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
            Button(action: viewModel.loadApplications) {
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

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading applications...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
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
                    .foregroundStyle(.secondary)

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
                        .scaleEffect(0.8)
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
