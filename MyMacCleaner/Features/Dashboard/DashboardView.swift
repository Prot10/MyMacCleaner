import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section with Scan Button
                HeroSectionView(
                    isScanning: viewModel.isScanning,
                    scanProgress: viewModel.scanProgress,
                    cleanableSize: viewModel.totalCleanableSize,
                    onScanTap: { Task { await viewModel.startScan() } }
                )

                // Quick Stats Cards
                HStack(spacing: 16) {
                    QuickStatsCard(
                        title: "Memory",
                        value: viewModel.memoryUsageText,
                        percentage: viewModel.memoryUsagePercentage,
                        icon: "memorychip",
                        color: viewModel.memoryColor
                    )

                    QuickStatsCard(
                        title: "Storage",
                        value: viewModel.storageUsageText,
                        percentage: viewModel.storageUsagePercentage,
                        icon: "internaldrive",
                        color: viewModel.storageColor
                    )

                    QuickStatsCard(
                        title: "CPU",
                        value: viewModel.cpuUsageText,
                        percentage: viewModel.cpuUsagePercentage,
                        icon: "cpu",
                        color: viewModel.cpuColor
                    )
                }
                .padding(.horizontal)

                // Cleanup Summary
                if viewModel.totalCleanableSize > 0 {
                    CleanupSummaryCard(
                        totalSize: viewModel.totalCleanableSize,
                        categories: viewModel.cleanupCategories,
                        onCleanNow: { Task { await viewModel.performCleanup() } },
                        onViewDetails: { appState.selectedNavigation = .cleaner }
                    )
                    .padding(.horizontal)
                }

                // Storage Breakdown Chart
                if !viewModel.diskCategories.isEmpty {
                    StorageBreakdownCard(categories: viewModel.diskCategories)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Hero Section

struct HeroSectionView: View {
    let isScanning: Bool
    let scanProgress: Double
    let cleanableSize: Int64
    let onScanTap: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Large Scan Button
            HeroScanButton(
                isScanning: isScanning,
                progress: scanProgress,
                onTap: onScanTap
            )

            // Status Text
            if isScanning {
                Text("Scanning your Mac...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else if cleanableSize > 0 {
                Text("\(ByteCountFormatter.string(fromByteCount: cleanableSize, countStyle: .file)) can be cleaned")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            } else {
                Text("Click to scan your Mac")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(AppState())
        .frame(width: 700, height: 600)
}
