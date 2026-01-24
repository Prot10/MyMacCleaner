import SwiftUI

// MARK: - Port Management View

struct PortManagementView: View {
    @ObservedObject var viewModel: PortManagementViewModel
    @State private var isVisible = false

    // Section color for port management
    private let sectionColor = Theme.Colors.ports

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
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.pageTopPadding)
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
        .animation(Theme.Animation.spring, value: viewModel.showToast)
        .alert(L("portManagement.kill.title"), isPresented: $viewModel.showKillConfirmation) {
            Button(L("common.cancel"), role: .cancel) {
                viewModel.cancelKill()
            }
            Button(L("portManagement.kill.button"), role: .destructive) {
                viewModel.confirmKill()
            }
        } message: {
            if let connection = viewModel.connectionToKill {
                Text(LFormat("portManagement.kill.message %@ %@ %@", connection.processName, String(connection.pid), connection.localPort))
            }
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
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(L("navigation.portManagement"))
                    .font(Theme.Typography.size28Bold)

                Text(L("portManagement.subtitle"))
                    .font(Theme.Typography.size13)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("common.refresh"),
                icon: "arrow.clockwise",
                color: sectionColor
            ) {
                viewModel.refreshConnections()
            }
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            PortStatCard(
                title: L("portManagement.stats.total"),
                value: "\(viewModel.connections.count)",
                icon: "network",
                color: .blue
            )

            PortStatCard(
                title: L("portManagement.stats.listening"),
                value: "\(viewModel.listeningCount)",
                icon: "antenna.radiowaves.left.and.right",
                color: .green
            )

            PortStatCard(
                title: L("portManagement.stats.established"),
                value: "\(viewModel.establishedCount)",
                icon: "link",
                color: .orange
            )
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: Theme.ControlSize.controlSpacing) {
            // Search
            GlassSearchField(text: $viewModel.searchText, placeholder: L("portManagement.search"))

            Spacer()

            // Filter tabs
            GlassTabPicker(
                tabs: PortManagementViewModel.FilterType.allCases,
                selection: $viewModel.filterType,
                icon: { $0.icon },
                label: { $0.localizedName },
                accentColor: sectionColor
            )
        }
    }

    // MARK: - Loading Section

    private var loadingSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .frame(width: 32, height: 32)

            Text(L("portManagement.scanning"))
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
                .font(Theme.Typography.size48)
                .foregroundStyle(.tertiary)

            Text(L("portManagement.empty.title"))
                .font(Theme.Typography.headline)

            Text(L("portManagement.empty.message"))
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
                Text(L("portManagement.table.process"))
                    .frame(width: 150, alignment: .leading)
                Text(L("portManagement.table.pid"))
                    .frame(width: 60, alignment: .leading)
                Text(L("portManagement.table.localPort"))
                    .frame(width: 100, alignment: .leading)
                Text(L("portManagement.table.remote"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(L("portManagement.table.state"))
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
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(Theme.Typography.size18Semibold)
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
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
            Text(connection.processName)
                .font(Theme.Typography.subheadline)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)

            // PID - use String() to avoid locale-based thousand separators
            Text(String(connection.pid))
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            // Local port - use String() to avoid locale-based thousand separators
            Text(String(connection.localPort))
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
            HStack(spacing: Theme.Spacing.xxs) {
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
                Text(L("portManagement.kill.button"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(Color.red.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny))
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
    PortManagementView(viewModel: PortManagementViewModel())
        .frame(width: 900, height: 700)
}
