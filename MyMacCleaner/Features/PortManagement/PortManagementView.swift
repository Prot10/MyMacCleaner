import SwiftUI

// MARK: - Port Management View

struct PortManagementView: View {
    @StateObject private var viewModel = PortManagementViewModel()
    @State private var isVisible = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Stats
                    statsSection
                        .staggeredAnimation(index: 1, isActive: isVisible)

                    // Controls
                    controlsSection
                        .staggeredAnimation(index: 2, isActive: isVisible)

                    // Connections list
                    if viewModel.isLoading {
                        loadingSection
                    } else if viewModel.filteredConnections.isEmpty {
                        emptySection
                    } else {
                        connectionsSection
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
        .alert("Kill Process?", isPresented: $viewModel.showKillConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelKill()
            }
            Button("Kill", role: .destructive) {
                viewModel.confirmKill()
            }
        } message: {
            if let connection = viewModel.connectionToKill {
                Text("This will terminate \(connection.processName) (PID: \(connection.pid)) using port \(connection.localPort).")
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
                Text("Port Management")
                    .font(Theme.Typography.largeTitle)

                Text("Monitor network connections and active ports")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: viewModel.refreshConnections) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            PortStatCard(
                title: "Total Connections",
                value: "\(viewModel.connections.count)",
                icon: "network",
                color: .blue
            )

            PortStatCard(
                title: "Listening",
                value: "\(viewModel.listeningCount)",
                icon: "antenna.radiowaves.left.and.right",
                color: .green
            )

            PortStatCard(
                title: "Established",
                value: "\(viewModel.establishedCount)",
                icon: "link",
                color: .orange
            )
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search by process or port...", text: $viewModel.searchText)
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

            // Filter
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(PortManagementViewModel.FilterType.allCases, id: \.self) { filter in
                    Button(action: { viewModel.filterType = filter }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.caption)
                            Text(filter.rawValue)
                                .font(Theme.Typography.caption)
                        }
                        .foregroundStyle(viewModel.filterType == filter ? .white : .secondary)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                                .fill(viewModel.filterType == filter ? Color.blue : Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Scanning network connections...")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    // MARK: - Empty Section

    private var emptySection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "network.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            Text("No connections found")
                .font(Theme.Typography.headline)

            Text("No active network connections match your criteria")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    // MARK: - Connections Section

    private var connectionsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Table header
            HStack {
                Text("Process")
                    .frame(width: 150, alignment: .leading)
                Text("PID")
                    .frame(width: 60, alignment: .leading)
                Text("Local Port")
                    .frame(width: 100, alignment: .leading)
                Text("Remote")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("State")
                    .frame(width: 100, alignment: .leading)
                Text("")
                    .frame(width: 80)
            }
            .font(Theme.Typography.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)

            Divider()

            // Connections
            ForEach(viewModel.filteredConnections) { connection in
                ConnectionRow(
                    connection: connection,
                    onKill: { viewModel.prepareKill(connection) }
                )

                if connection.id != viewModel.filteredConnections.last?.id {
                    Divider()
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Port Stat Card

struct PortStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

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
        .glassCard()
    }
}

// MARK: - Connection Row

struct ConnectionRow: View {
    let connection: NetworkConnection
    let onKill: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack {
            // Process name
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "app")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(connection.processName)
                    .font(Theme.Typography.subheadline)
                    .lineLimit(1)
            }
            .frame(width: 150, alignment: .leading)

            // PID
            Text("\(connection.pid)")
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            // Local port
            Text("\(connection.localPort)")
                .font(Theme.Typography.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.cyan)
                .frame(width: 100, alignment: .leading)

            // Remote
            Text(connection.formattedRemote ?? "-")
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            // State
            HStack(spacing: 4) {
                Circle()
                    .fill(connection.stateColor)
                    .frame(width: 8, height: 8)

                Text(connection.state)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 100, alignment: .leading)

            // Kill button
            Button(action: onKill) {
                Text("Kill")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.6)
            .frame(width: 80)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Preview

#Preview {
    PortManagementView()
        .frame(width: 900, height: 700)
}
