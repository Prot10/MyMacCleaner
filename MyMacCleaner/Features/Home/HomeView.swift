import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // Smart Scan Button
                smartScanSection

                // Quick Stats
                quickStatsSection

                // Quick Actions
                quickActionsSection
            }
            .padding(24)
        }
        .navigationTitle("Home")
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to MyMacCleaner")
                    .font(.largeTitle.bold())

                Text("Keep your Mac running smoothly")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // System status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.systemHealthColor)
                    .frame(width: 12, height: 12)

                Text(viewModel.systemHealthStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    // MARK: - Smart Scan Section

    private var smartScanSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.startSmartScan()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 60, height: 60)

                        if viewModel.isScanning {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.isScanning ? "Scanning..." : "Smart Scan")
                            .font(.title2.bold())

                        Text(viewModel.isScanning ? "Analyzing your system" : "Scan all categories at once")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isScanning)

            if viewModel.isScanning {
                ProgressView(value: viewModel.scanProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Storage",
                    value: viewModel.storageUsed,
                    subtitle: "of \(viewModel.storageTotal)",
                    icon: "internaldrive.fill",
                    color: .blue
                )

                StatCard(
                    title: "Memory",
                    value: viewModel.memoryUsed,
                    subtitle: "in use",
                    icon: "memorychip.fill",
                    color: .purple
                )

                StatCard(
                    title: "Junk Files",
                    value: viewModel.junkSize,
                    subtitle: "cleanable",
                    icon: "trash.fill",
                    color: .orange
                )

                StatCard(
                    title: "Apps",
                    value: "\(viewModel.appCount)",
                    subtitle: "installed",
                    icon: "square.grid.2x2.fill",
                    color: .green
                )
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Empty Trash",
                    icon: "trash",
                    action: viewModel.emptyTrash
                )

                QuickActionButton(
                    title: "Free Memory",
                    icon: "memorychip",
                    action: viewModel.freeMemory
                )

                QuickActionButton(
                    title: "View Large Files",
                    icon: "doc.fill",
                    action: viewModel.viewLargeFiles
                )

                Spacer()
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2.bold())

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)

                Text(title)
                    .font(.caption)
            }
            .frame(width: 100, height: 80)
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .frame(width: 800, height: 600)
}
