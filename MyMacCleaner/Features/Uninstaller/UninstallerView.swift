import SwiftUI

struct UninstallerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = UninstallerViewModel()

    var body: some View {
        HSplitView {
            // Left: App List
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search apps...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .padding()

                Divider()

                // App list
                if viewModel.isLoading {
                    ProgressView("Loading apps...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(viewModel.filteredApps, selection: $viewModel.selectedApp) { app in
                        AppListRow(app: app)
                            .tag(app)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 250, maxWidth: 350)

            // Right: Selected App Details
            if let app = viewModel.selectedApp {
                AppDetailView(
                    app: app,
                    leftovers: viewModel.leftovers,
                    isScanning: viewModel.isScanningLeftovers,
                    onUninstall: { Task { await viewModel.uninstallSelectedApp() } }
                )
            } else {
                // Placeholder
                VStack(spacing: 16) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("Select an app to uninstall")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Or drag and drop an .app here")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .task {
            await viewModel.loadInstalledApps()
        }
    }
}

// MARK: - App List Row

struct AppListRow: View {
    let app: AppInfo

    var body: some View {
        HStack(spacing: 12) {
            // App icon placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "app.fill")
                        .foregroundStyle(.secondary)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.body)
                    .lineLimit(1)

                Text(app.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - App Detail View

struct AppDetailView: View {
    let app: AppInfo
    let leftovers: [LeftoverInfo]
    let isScanning: Bool
    let onUninstall: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // App Header
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(app.bundleId)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(app.formattedSize)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()

            Divider()

            // Leftovers Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Related Files")
                        .font(.headline)

                    Spacer()

                    if isScanning {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if leftovers.isEmpty && !isScanning {
                    Text("No leftover files found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    List(leftovers) { leftover in
                        HStack {
                            Image(systemName: leftover.icon)
                                .foregroundStyle(.secondary)

                            VStack(alignment: .leading) {
                                Text(leftover.name)
                                    .font(.body)
                                Text(leftover.path)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(leftover.formattedSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.inset)
                }
            }

            Spacer()

            Divider()

            // Uninstall Button
            HStack {
                Spacer()

                Button(role: .destructive, action: onUninstall) {
                    Label("Uninstall", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    UninstallerView()
        .environment(AppState())
        .frame(width: 800, height: 600)
}
