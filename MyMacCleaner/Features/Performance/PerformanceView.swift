import SwiftUI

// MARK: - Performance View

struct PerformanceView: View {
    @StateObject private var viewModel = PerformanceViewModel()
    @State private var isVisible = false
    @State private var selectedTab: PerformanceTab = .memory

    enum PerformanceTab: String, CaseIterable {
        case memory = "Memory"
        case maintenance = "Maintenance"

        var icon: String {
            switch self {
            case .memory: return "memorychip"
            case .maintenance: return "wrench.and.screwdriver"
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection
                        .staggeredAnimation(index: 0, isActive: isVisible)

                    // Tab picker
                    tabPicker
                        .staggeredAnimation(index: 1, isActive: isVisible)

                    // Content
                    if selectedTab == .memory {
                        memorySection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                        memoryBreakdownSection
                            .staggeredAnimation(index: 3, isActive: isVisible)
                    } else {
                        maintenanceSection
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
        .animation(Theme.Animation.spring, value: selectedTab)
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
                Text("Performance")
                    .font(Theme.Typography.largeTitle)

                Text("Monitor and optimize your Mac's performance")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // CPU indicator
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 8) {
                    Text("CPU")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text("\(Int(viewModel.cpuUsage))%")
                        .font(Theme.Typography.title.monospacedDigit())
                        .foregroundStyle(cpuColor)
                }

                ProgressView(value: viewModel.cpuUsage, total: 100)
                    .progressViewStyle(.linear)
                    .tint(cpuColor)
                    .frame(width: 100)
            }
        }
    }

    private var cpuColor: Color {
        if viewModel.cpuUsage > 80 {
            return .red
        } else if viewModel.cpuUsage > 50 {
            return .orange
        }
        return .green
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(PerformanceTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .medium))

                        Text(tab.rawValue)
                            .font(Theme.Typography.subheadline)
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                            .fill(selectedTab == tab ? Color.purple : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        HStack(spacing: Theme.Spacing.lg) {
            // Memory gauge
            memoryGauge
                .frame(width: 200)

            // Memory stats
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                memoryStatRow(
                    label: "Used Memory",
                    value: viewModel.memoryUsage.formattedUsed,
                    color: .orange
                )

                memoryStatRow(
                    label: "Free Memory",
                    value: viewModel.memoryUsage.formattedFree,
                    color: .green
                )

                memoryStatRow(
                    label: "Total Memory",
                    value: viewModel.memoryUsage.formattedTotal,
                    color: .blue
                )

                Divider()
                    .padding(.vertical, Theme.Spacing.xs)

                // Free RAM button
                Button(action: { viewModel.runTask(MaintenanceTask.allTasks[0]) }) {
                    HStack(spacing: 8) {
                        if viewModel.runningTaskId == "purge_ram" {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text("Free Up RAM")
                    }
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.runningTaskId != nil)
            }
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
    }

    private var memoryGauge: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)

            // Progress arc
            Circle()
                .trim(from: 0, to: viewModel.memoryUsage.usagePercentage / 100)
                .stroke(
                    AngularGradient(
                        colors: [.green, .yellow, .orange, .red],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.springSmooth, value: viewModel.memoryUsage.usagePercentage)

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(viewModel.memoryUsage.usagePercentage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(memoryColor)

                Text("Memory Used")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.md)
    }

    private var memoryColor: Color {
        let usage = viewModel.memoryUsage.usagePercentage
        if usage > 85 {
            return .red
        } else if usage > 70 {
            return .orange
        }
        return .green
    }

    private func memoryStatRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(Theme.Typography.subheadline.monospacedDigit().weight(.medium))
        }
    }

    // MARK: - Memory Breakdown Section

    private var memoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Memory Breakdown")
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.md) {
                memoryBreakdownCard(
                    title: "Active",
                    value: viewModel.memoryUsage.formattedActive,
                    icon: "bolt.fill",
                    color: .blue,
                    description: "Currently in use by apps"
                )

                memoryBreakdownCard(
                    title: "Wired",
                    value: viewModel.memoryUsage.formattedWired,
                    icon: "lock.fill",
                    color: .orange,
                    description: "System, cannot be freed"
                )

                memoryBreakdownCard(
                    title: "Compressed",
                    value: viewModel.memoryUsage.formattedCompressed,
                    icon: "archivebox.fill",
                    color: .green,
                    description: "Compressed in RAM"
                )

                memoryBreakdownCard(
                    title: "Cached",
                    value: viewModel.memoryUsage.formattedInactive,
                    icon: "tray.full.fill",
                    color: .purple,
                    description: "Available if needed"
                )
            }

            // Swap section
            if viewModel.memoryUsage.hasSwap {
                HStack(spacing: Theme.Spacing.md) {
                    swapCard
                    Spacer()
                }
            }
        }
    }

    private var swapCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Swap Used")
                    .font(Theme.Typography.subheadline.weight(.medium))

                Text("\(viewModel.memoryUsage.formattedSwapUsed) of \(viewModel.memoryUsage.formattedSwapTotal)")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Swap usage indicator
            if viewModel.memoryUsage.swapTotal > 0 {
                let swapPercent = Double(viewModel.memoryUsage.swapUsed) / Double(viewModel.memoryUsage.swapTotal)
                CircularProgressView(progress: swapPercent, color: swapColor)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(width: 280)
        .glassCard()
    }

    private var swapColor: Color {
        let swapUsed = viewModel.memoryUsage.swapUsed
        let swapTotal = viewModel.memoryUsage.swapTotal
        guard swapTotal > 0 else { return .green }
        let percent = Double(swapUsed) / Double(swapTotal) * 100
        if percent > 50 {
            return .red
        } else if percent > 25 {
            return .orange
        }
        return .green
    }

    private func memoryBreakdownCard(title: String, value: String, icon: String, color: Color, description: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(Theme.Typography.headline.monospacedDigit())

            Text(title)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.secondary)

            Text(description)
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .glassCard()
    }

    // MARK: - Maintenance Section

    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Maintenance Tasks")
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                ForEach(viewModel.maintenanceTasks) { task in
                    MaintenanceTaskCard(
                        task: task,
                        isRunning: viewModel.runningTaskId == task.id,
                        progress: viewModel.runningTaskId == task.id ? viewModel.taskProgress : 0,
                        onRun: { viewModel.runTask(task) }
                    )
                    .disabled(viewModel.runningTaskId != nil && viewModel.runningTaskId != task.id)
                }
            }
        }
    }
}

// MARK: - Maintenance Task Card

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    let isRunning: Bool
    let progress: Double
    let onRun: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onRun) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(task.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        if isRunning {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: task.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(task.color)
                        }
                    }

                    Spacer()

                    if task.requiresAdmin {
                        Image(systemName: "lock.shield")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(task.name)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(task.description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if isRunning {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .tint(task.color)
                }
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
            .hoverEffect(isHovered: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 4)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceView()
        .frame(width: 800, height: 700)
}
