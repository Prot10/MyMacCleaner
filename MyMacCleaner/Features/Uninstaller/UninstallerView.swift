import SwiftUI

struct UninstallerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = UninstallerViewModel()

    var body: some View {
        HSplitView {
            // Left: App List with glass effect
            VStack(spacing: 0) {
                // Search bar with glass effect
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)

                    TextField("Search apps...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                Divider()

                // App list
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Loading apps...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredApps) { app in
                                GlassAppListRow(
                                    app: app,
                                    isSelected: viewModel.selectedApp?.id == app.id
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.selectedApp = app
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                }
            }
            .frame(minWidth: 260, maxWidth: 320)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))

            // Right: Selected App Details
            if let app = viewModel.selectedApp {
                GlassAppDetailView(
                    app: app,
                    leftovers: viewModel.leftovers,
                    isScanning: viewModel.isScanningLeftovers,
                    onUninstall: { Task { await viewModel.uninstallSelectedApp() } }
                )
            } else {
                // Placeholder with glass effect
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)

                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 44))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cleanBlue, .cleanPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }

                    VStack(spacing: 10) {
                        Text("Select an app to uninstall")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Or drag and drop an .app file here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    // Drop zone indicator
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                        .foregroundStyle(.secondary.opacity(0.3))
                        .frame(width: 200, height: 100)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.down.doc")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.secondary)
                                Text("Drop .app here")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Use preloaded data if available, otherwise load fresh
            let preloadedData = appState.loadingState.uninstaller.data
            viewModel.loadData(from: preloadedData)

            // If no preloaded data, load fresh
            if viewModel.apps.isEmpty {
                await viewModel.loadInstalledApps()
            }
        }
    }
}

// MARK: - Glass App List Row

struct GlassAppListRow: View {
    let app: AppInfo
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // App icon with glass background
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "app.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(app.formattedSize)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                } else if isHovering {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.05))
                }
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Glass App Detail View

struct GlassAppDetailView: View {
    let app: AppInfo
    let leftovers: [LeftoverInfo]
    let isScanning: Bool
    let onUninstall: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // App Header with glass card
            VStack(spacing: 0) {
                HStack(spacing: 18) {
                    // App icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .frame(width: 72, height: 72)

                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)

                        Image(systemName: "app.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text(app.bundleId)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)

                        Text(app.formattedSize)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .background(.ultraThinMaterial)

            Divider()

            // Leftovers Section
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Related Files")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()

                    if isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Scanning...")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("\(leftovers.count) items found")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                if leftovers.isEmpty && !isScanning {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.cleanGreen)

                        Text("No leftover files found")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(leftovers) { leftover in
                                GlassLeftoverRow(leftover: leftover)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }

            Spacer()

            // Uninstall Button Footer
            VStack(spacing: 0) {
                Divider()

                HStack {
                    // Total size
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total to remove")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)

                        let totalSize = app.sizeBytes + leftovers.reduce(0) { $0 + $1.sizeBytes }
                        Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Button(action: onUninstall) {
                        HStack(spacing: 10) {
                            Image(systemName: "trash.fill")
                            Text("Uninstall")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.cleanRed, .cleanRed.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .shadow(color: .cleanRed.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(.ultraThinMaterial)
            }
        }
    }
}

// MARK: - Glass Leftover Row

struct GlassLeftoverRow: View {
    let leftover: LeftoverInfo
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(leftover.confidenceColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: leftover.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(leftover.confidenceColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(leftover.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)

                Text(leftover.path)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            // Confidence badge
            Text(leftover.confidence.rawValue)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(leftover.confidenceColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(leftover.confidenceColor.opacity(0.15), in: Capsule())

            Text(leftover.formattedSize)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            if isHovering {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    UninstallerView()
        .environment(AppState())
        .frame(width: 850, height: 650)
}
