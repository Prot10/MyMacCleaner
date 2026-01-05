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
                Text(L("navigation.performance"))
                    .font(.system(size: 28, weight: .bold))

                Text(L("performance.subtitle"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // CPU indicator
            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(L("performance.cpu"))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Text("\(Int(viewModel.cpuUsage))%")
                            .font(.system(size: 22, weight: .semibold).monospacedDigit())
                            .foregroundStyle(cpuColor)
                    }

                    ProgressView(value: viewModel.cpuUsage, total: 100)
                        .progressViewStyle(.linear)
                        .tint(cpuColor)
                        .frame(width: 100)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassCard(cornerRadius: 12)
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
            VStack(spacing: 4) {
                Text("\(Int(viewModel.memoryUsage.usagePercentage))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded).monospacedDigit())
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
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text(L("performance.processes.live"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
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
                        .font(.system(size: 48))
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
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
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
        VStack(alignment: .leading, spacing: 12) {
            // Header with Run All button
            HStack {
                Text(L("performance.maintenance.title"))
                    .font(Theme.Typography.headline)

                Spacer()

                if viewModel.isRunningAll {
                    // Progress indicator during run all
                    HStack(spacing: 8) {
                        Text(LFormat("performance.maintenance.taskOf %lld %lld", viewModel.runAllCurrentIndex, viewModel.runAllTotalCount))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)

                        Button(action: viewModel.cancelRunAll) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark")
                                Text(L("common.stop"))
                            }
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
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

// MARK: - Maintenance Task Card

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    let isRunning: Bool
    let progress: Double
    let result: PerformanceViewModel.TaskResult?
    let onRun: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onRun) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(iconBackgroundColor.opacity(0.15))
                            .frame(width: 44, height: 44)

                        if isRunning {
                            ProgressView()
                                .controlSize(.small)
                        } else if let result = result {
                            resultIcon(for: result)
                        } else {
                            Image(systemName: task.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(task.color)
                        }
                    }

                    Spacer()

                    // Status badge
                    if let result = result, result != .pending && result != .running {
                        statusBadge(for: result)
                    } else if task.requiresAdmin {
                        Image(systemName: "lock.shield")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Text(task.localizedName)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(task.localizedDescription)
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
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 2)
            )
            .hoverEffect(isHovered: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Theme.Animation.spring, value: result)
    }

    private var iconBackgroundColor: Color {
        guard let result = result else { return task.color }
        switch result {
        case .success: return .green
        case .failed: return .red
        case .skipped: return .orange
        default: return task.color
        }
    }

    private var borderColor: Color {
        guard let result = result else { return .clear }
        switch result {
        case .running: return task.color.opacity(0.5)
        case .success: return .green.opacity(0.5)
        case .failed: return .red.opacity(0.5)
        default: return .clear
        }
    }

    @ViewBuilder
    private func resultIcon(for result: PerformanceViewModel.TaskResult) -> some View {
        switch result {
        case .success:
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.red)
        case .skipped:
            Image(systemName: "forward.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.orange)
        case .pending:
            Image(systemName: task.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(task.color.opacity(0.5))
        case .running:
            ProgressView()
                .controlSize(.small)
        }
    }

    @ViewBuilder
    private func statusBadge(for result: PerformanceViewModel.TaskResult) -> some View {
        HStack(spacing: 4) {
            switch result {
            case .success:
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                Text(L("common.done"))
            case .failed:
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                Text(L("common.failed"))
            case .skipped:
                Image(systemName: "forward.fill")
                    .font(.system(size: 8, weight: .bold))
                Text(L("common.skipped"))
            default:
                EmptyView()
            }
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(badgeColor(for: result))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(badgeColor(for: result).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func badgeColor(for result: PerformanceViewModel.TaskResult) -> Color {
        switch result {
        case .success: return .green
        case .failed: return .red
        case .skipped: return .orange
        default: return .gray
        }
    }
}

// MARK: - Process Row

struct ProcessRow: View {
    let rank: Int
    let process: RunningProcess
    let onKill: () -> Void

    @State private var isHovered = false
    @State private var showKillConfirm = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Rank
            Text("\(rank)")
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(rankColor)
                .frame(width: 24, alignment: .leading)

            // Process name and user
            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(Theme.Typography.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(process.user)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // PID - use String() to avoid locale-based thousand separators
            Text(String(process.pid))
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .trailing)

            // Memory
            Text(process.formattedMemory)
                .font(Theme.Typography.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(memoryColor)
                .frame(width: 80, alignment: .trailing)

            // CPU
            Text(String(format: "%.1f%%", process.cpuPercent))
                .font(Theme.Typography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 50, alignment: .trailing)

            // Kill button
            Button(action: { showKillConfirm = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text(L("performance.processes.kill"))
                }
                .font(Theme.Typography.caption.weight(.medium))
                .foregroundStyle(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(isHovered ? 0.2 : 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)
            .frame(width: 70)
            .opacity(isHovered ? 1 : 0.6)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
        .onHover { isHovered = $0 }
        .confirmationDialog(
            LFormat("performance.processes.killConfirm %@", process.name),
            isPresented: $showKillConfirm,
            titleVisibility: .visible
        ) {
            Button(L("performance.processes.killProcess"), role: .destructive, action: onKill)
            Button(L("common.cancel"), role: .cancel) {}
        } message: {
            Text(LFormat("performance.processes.killMessage %@", String(process.pid)))
        }
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .secondary
        }
    }

    private var memoryColor: Color {
        if process.memoryMB > 1000 {
            return .red
        } else if process.memoryMB > 500 {
            return .orange
        }
        return .primary
    }
}

// MARK: - Run All Progress View

struct RunAllProgressView: View {
    let currentIndex: Int
    let totalCount: Int
    let currentTaskName: String
    let taskProgress: Double

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Overall progress
            HStack(spacing: Theme.Spacing.md) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: overallProgress)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))

                    Text("\(currentIndex)/\(totalCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L("performance.maintenance.running"))
                        .font(Theme.Typography.subheadline.weight(.semibold))

                    if !currentTaskName.isEmpty {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                                .frame(width: 10, height: 10)

                            Text(currentTaskName)
                                .font(Theme.Typography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Current task progress
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(taskProgress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.purple)

                    Text(L("performance.maintenance.currentTask"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Completed tasks progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * overallProgress, height: 8)

                    // Current task progress (lighter overlay)
                    if currentIndex > 0 {
                        let segmentWidth = geometry.size.width / CGFloat(totalCount)
                        let startX = segmentWidth * CGFloat(currentIndex - 1)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: segmentWidth * taskProgress, height: 8)
                            .offset(x: startX)
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(Theme.Spacing.md)
        .glassCard()
        .animation(Theme.Animation.spring, value: currentIndex)
        .animation(Theme.Animation.spring, value: taskProgress)
    }

    private var overallProgress: CGFloat {
        guard totalCount > 0 else { return 0 }
        let completedTasks = CGFloat(currentIndex - 1)
        let currentTaskContribution = CGFloat(taskProgress) / CGFloat(totalCount)
        return (completedTasks / CGFloat(totalCount)) + currentTaskContribution
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
    PerformanceView(viewModel: PerformanceViewModel())
        .frame(width: 800, height: 700)
}
