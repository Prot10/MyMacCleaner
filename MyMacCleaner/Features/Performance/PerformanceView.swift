import SwiftUI

// MARK: - Performance View

struct PerformanceView: View {
    @ObservedObject var viewModel: PerformanceViewModel
    @State private var isVisible = false
    @State private var selectedTab: PerformanceTab = .memory

    // Section color for performance
    private let sectionColor = Theme.Colors.memory

    enum PerformanceTab: String, CaseIterable {
        case memory
        case processes
        case maintenance

        var icon: String {
            switch self {
            case .memory: return "memorychip"
            case .processes: return "list.number"
            case .maintenance: return "wrench.and.screwdriver"
            }
        }

        var localizedName: String {
            switch self {
            case .memory: return L("performance.tab.memory")
            case .processes: return L("performance.tab.processes")
            case .maintenance: return L("performance.tab.maintenance")
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
                    switch selectedTab {
                    case .memory:
                        memorySection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                        memoryBreakdownSection
                            .staggeredAnimation(index: 3, isActive: isVisible)

                    case .processes:
                        processesSection
                            .staggeredAnimation(index: 2, isActive: isVisible)

                    case .maintenance:
                        maintenanceSection
                            .staggeredAnimation(index: 2, isActive: isVisible)
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
        .animation(Theme.Animation.spring, value: selectedTab)
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .processes {
                viewModel.startProcessMonitoring()
            } else {
                viewModel.stopProcessMonitoring()
            }
        }
        .onDisappear {
            viewModel.stopProcessMonitoring()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(L("navigation.performance"))
                    .font(Theme.Typography.size28Bold)

                Text(L("performance.subtitle"))
                    .font(Theme.Typography.size13)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // CPU indicator
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(L("performance.cpu"))
                            .font(Theme.Typography.size11)
                            .foregroundStyle(.secondary)

                        Text("\(Int(viewModel.cpuUsage))%")
                            .font(Theme.Typography.size22Semibold.monospacedDigit())
                            .foregroundStyle(cpuColor)
                    }

                    ProgressView(value: viewModel.cpuUsage, total: 100)
                        .progressViewStyle(.linear)
                        .tint(cpuColor)
                        .frame(width: 100)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 10)
            .glassCard(cornerRadius: Theme.CornerRadius.medium)
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
        HStack {
            GlassTabPicker(
                tabs: PerformanceTab.allCases,
                selection: $selectedTab,
                icon: { $0.icon },
                label: { $0.localizedName },
                accentColor: sectionColor
            )

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
                    label: L("performance.memory.used"),
                    value: viewModel.memoryUsage.formattedUsed,
                    color: .orange
                )

                memoryStatRow(
                    label: L("performance.memory.free"),
                    value: viewModel.memoryUsage.formattedFree,
                    color: .green
                )

                memoryStatRow(
                    label: L("performance.memory.total"),
                    value: viewModel.memoryUsage.formattedTotal,
                    color: .blue
                )

                Divider()
                    .padding(.vertical, Theme.Spacing.xs)

                // Freeable RAM info
                freeableRamInfo

                // Purge cache button
                GlassActionButton(
                    L("performance.memory.purgeDiskCache"),
                    icon: viewModel.runningTaskId == "purge_ram" ? nil : "bolt.fill",
                    color: sectionColor,
                    disabled: viewModel.runningTaskId != nil
                ) {
                    viewModel.runTask(MaintenanceTask.allTasks[0])
                }
                .overlay {
                    if viewModel.runningTaskId == "purge_ram" {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
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

            // Progress arc - border (drawn first, slightly wider)
            Circle()
                .trim(from: 0, to: viewModel.memoryUsage.usagePercentage / 100)
                .stroke(
                    AngularGradient(
                        colors: [.green.opacity(0.5), .yellow.opacity(0.5), .orange.opacity(0.5), .red.opacity(0.5)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 20, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.springSmooth, value: viewModel.memoryUsage.usagePercentage)

            // Progress arc - fill (on top, narrower)
            Circle()
                .trim(from: 0, to: viewModel.memoryUsage.usagePercentage / 100)
                .stroke(
                    AngularGradient(
                        colors: [.green.opacity(0.15), .yellow.opacity(0.15), .orange.opacity(0.15), .red.opacity(0.15)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(Theme.Animation.springSmooth, value: viewModel.memoryUsage.usagePercentage)

            // Center content
            VStack(spacing: Theme.Spacing.xxs) {
                Text("\(Int(viewModel.memoryUsage.usagePercentage))%")
                    .font(Theme.Typography.size36BoldRounded.monospacedDigit())
                    .foregroundStyle(memoryColor)

                Text(L("performance.memory.memoryUsed"))
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

    private var freeableRamInfo: some View {
        let freeableAmount = viewModel.memoryUsage.inactive + viewModel.memoryUsage.purgeable
        let freeableFormatted = ByteCountFormatter.string(fromByteCount: Int64(freeableAmount), countStyle: .memory)

        return HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.blue)

            Text(LFormat("performance.memory.canBeFreed %@", freeableFormatted))
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)

            Text(L("performance.memory.cachedPurgeable"))
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.bottom, Theme.Spacing.xs)
    }

    // MARK: - Processes Section

    private var processesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Text(L("performance.processes.topConsumers"))
                    .font(Theme.Typography.headline)

                Spacer()

                // Auto-refresh indicator
                HStack(spacing: Theme.Spacing.xxxs) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text(L("performance.processes.live"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.tiny))
            }

            if viewModel.isLoadingProcesses && viewModel.topProcesses.isEmpty {
                // Loading state
                VStack(spacing: Theme.Spacing.md) {
                    ProgressView()
                        .controlSize(.regular)
                        .frame(width: 20, height: 20)

                    Text(L("performance.processes.loading"))
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .glassCard()
            } else if viewModel.topProcesses.isEmpty {
                // Empty state
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(Theme.Typography.size48)
                        .foregroundStyle(.tertiary)

                    Text(L("performance.processes.noData"))
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.xl)
                .glassCard()
            } else {
                // Process list
                VStack(spacing: 0) {
                    // Header row
                    HStack(spacing: Theme.Spacing.md) {
                        Text("#")
                            .frame(width: 24, alignment: .leading)
                        Text(L("performance.processes.process"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(L("performance.processes.pid"))
                            .frame(width: 60, alignment: .trailing)
                        Text(L("performance.processes.memory"))
                            .frame(width: 80, alignment: .trailing)
                        Text(L("performance.processes.cpuColumn"))
                            .frame(width: 50, alignment: .trailing)
                        Text("")
                            .frame(width: 70)
                    }
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)

                    Divider()

                    ForEach(Array(viewModel.topProcesses.enumerated()), id: \.element.id) { index, process in
                        ProcessRow(
                            rank: index + 1,
                            process: process,
                            onKill: { viewModel.killProcess(process) }
                        )

                        if index < viewModel.topProcesses.count - 1 {
                            Divider()
                                .padding(.leading, Theme.Spacing.md)
                        }
                    }
                }
                .glassCard()
            }

            // Info text
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)

                Text(L("performance.processes.warning"))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
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
            Text(L("performance.memory.breakdown"))
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.md) {
                memoryBreakdownCard(
                    title: L("performance.memory.active"),
                    value: viewModel.memoryUsage.formattedActive,
                    icon: "bolt.fill",
                    color: .blue,
                    description: L("performance.memory.activeDesc")
                )

                memoryBreakdownCard(
                    title: L("performance.memory.wired"),
                    value: viewModel.memoryUsage.formattedWired,
                    icon: "lock.fill",
                    color: .orange,
                    description: L("performance.memory.wiredDesc")
                )

                memoryBreakdownCard(
                    title: L("performance.memory.compressed"),
                    value: viewModel.memoryUsage.formattedCompressed,
                    icon: "archivebox.fill",
                    color: .green,
                    description: L("performance.memory.compressedDesc")
                )

                memoryBreakdownCard(
                    title: L("performance.memory.cached"),
                    value: viewModel.memoryUsage.formattedInactive,
                    icon: "tray.full.fill",
                    color: .purple,
                    description: L("performance.memory.cachedDesc")
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
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.left.arrow.right")
                    .font(Theme.Typography.size18Semibold)
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.tiny) {
                Text(L("performance.memory.swapUsed"))
                    .font(Theme.Typography.subheadline.weight(.medium))

                Text(LFormat("performance.memory.swapOf %@ %@", viewModel.memoryUsage.formattedSwapUsed, viewModel.memoryUsage.formattedSwapTotal))
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
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(Theme.Typography.size18Semibold)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header with Run All button
            HStack {
                Text(L("performance.maintenance.title"))
                    .font(Theme.Typography.headline)

                Spacer()

                if viewModel.isRunningAll {
                    // Progress indicator during run all
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(LFormat("performance.maintenance.taskOf %lld %lld", viewModel.runAllCurrentIndex, viewModel.runAllTotalCount))
                            .font(Theme.Typography.size11)
                            .foregroundStyle(.secondary)

                        Button(action: viewModel.cancelRunAll) {
                            HStack(spacing: Theme.Spacing.xxs) {
                                Image(systemName: "xmark")
                                Text(L("common.stop"))
                            }
                            .font(Theme.Typography.size11Medium)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, Theme.Spacing.xxs)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    GlassActionButton(
                        L("performance.maintenance.runAll"),
                        icon: "play.fill",
                        color: sectionColor,
                        disabled: viewModel.runningTaskId != nil
                    ) {
                        viewModel.runAllTasks()
                    }
                }
            }

            // Overall progress bar during run all
            if viewModel.isRunningAll {
                RunAllProgressView(
                    currentIndex: viewModel.runAllCurrentIndex,
                    totalCount: viewModel.runAllTotalCount,
                    currentTaskName: viewModel.maintenanceTasks.first { $0.id == viewModel.runningTaskId }?.localizedName ?? "",
                    taskProgress: viewModel.taskProgress
                )
            }

            // Task grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                ForEach(viewModel.maintenanceTasks) { task in
                    MaintenanceTaskCard(
                        task: task,
                        isRunning: viewModel.runningTaskId == task.id,
                        progress: viewModel.runningTaskId == task.id ? viewModel.taskProgress : 0,
                        result: viewModel.taskResults[task.id],
                        onRun: { viewModel.runTask(task) }
                    )
                    .disabled((viewModel.runningTaskId != nil || viewModel.isRunningAll) && viewModel.runningTaskId != task.id)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PerformanceView(viewModel: PerformanceViewModel())
        .frame(width: 800, height: 700)
}
