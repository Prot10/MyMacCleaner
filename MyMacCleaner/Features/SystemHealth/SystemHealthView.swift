import SwiftUI

// MARK: - System Health View

struct SystemHealthView: View {
    @ObservedObject var viewModel: SystemHealthViewModel
    @State private var isVisible = false

    // Section color for system health
    private let sectionColor = Theme.Colors.health

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                headerSection
                    .staggeredAnimation(index: 0, isActive: isVisible)

                // Health Score Card
                healthScoreCard
                    .staggeredAnimation(index: 1, isActive: isVisible)

                // Health Checks Grid
                healthChecksSection
                    .staggeredAnimation(index: 2, isActive: isVisible)

                // System Info
                systemInfoSection
                    .staggeredAnimation(index: 3, isActive: isVisible)
            }
            .padding(Theme.Spacing.lg)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(L("navigation.systemHealth"))
                    .font(Theme.Typography.size28Bold)

                Text(L("systemHealth.subtitle"))
                    .font(Theme.Typography.size13)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            GlassActionButton(
                L("common.refresh"),
                icon: viewModel.isLoading ? nil : "arrow.clockwise",
                color: sectionColor,
                disabled: viewModel.isLoading
            ) {
                viewModel.runHealthCheck()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Circular Score
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress circle - border (drawn first, slightly wider)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.healthScore) / 100)
                    .stroke(
                        viewModel.healthStatus.color.opacity(0.5),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.springSmooth, value: viewModel.healthScore)

                // Progress circle - fill (on top, narrower)
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.healthScore) / 100)
                    .stroke(
                        viewModel.healthStatus.color.opacity(0.15),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.springSmooth, value: viewModel.healthScore)

                // Score text
                VStack(spacing: 4) {
                    Text("\(viewModel.healthScore)")
                        .font(Theme.Typography.size44BoldRounded)
                        .foregroundStyle(viewModel.healthStatus.color)

                    Text("/ 100")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Status info
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: viewModel.healthStatus.icon)
                        .font(.title2)
                        .foregroundStyle(viewModel.healthStatus.color)

                    Text(viewModel.healthStatus.localizedName)
                        .font(Theme.Typography.title)
                }

                Text(healthSummary)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if let lastUpdated = viewModel.lastUpdated {
                    Text(LFormat("systemHealth.lastChecked %@", lastUpdated.formatted(date: .omitted, time: .shortened)))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.lg)
        .glassCard()
    }

    private var healthSummary: String {
        let passed = viewModel.healthChecks.filter { $0.status == .passed }.count
        let warnings = viewModel.healthChecks.filter { $0.status == .warning }.count
        let failed = viewModel.healthChecks.filter { $0.status == .failed }.count

        if viewModel.isLoading {
            return L("systemHealth.summary.running")
        } else if failed > 0 {
            return LFormat("systemHealth.summary.failed %lld", failed)
        } else if warnings > 0 {
            return LFormat("systemHealth.summary.warnings %lld %lld", passed, warnings)
        } else {
            return LFormat("systemHealth.summary.passed %lld", passed)
        }
    }

    // MARK: - Health Checks Section

    private var healthChecksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(L("systemHealth.checks.title"))
                .font(Theme.Typography.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                ForEach(viewModel.healthChecks) { check in
                    HealthCheckCard(check: check)
                }
            }
        }
    }

    // MARK: - System Info Section

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(L("systemHealth.info.title"))
                .font(Theme.Typography.headline)

            HStack(spacing: Theme.Spacing.md) {
                // Disk Info
                if let disk = viewModel.diskInfo.first {
                    DiskInfoCard(disk: disk)
                }

                // Battery Info (if available)
                if let battery = viewModel.batteryInfo {
                    BatteryInfoCard(battery: battery)
                }

                // macOS Info
                MacInfoCard()
            }
        }
    }
}

// MARK: - Health Check Card

struct HealthCheckCard: View {
    let check: HealthCheck
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(check.status.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                if check.status == .checking {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: check.status.icon)
                        .font(Theme.Typography.size18Semibold)
                        .foregroundStyle(check.status.color)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: check.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(check.title)
                        .font(Theme.Typography.subheadline.weight(.medium))
                }

                Text(check.description)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Disk Info Card

struct DiskInfoCard: View {
    let disk: DiskInfo
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)

                Text(disk.name)
                    .font(Theme.Typography.subheadline.weight(.medium))

                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(diskColor.gradient)
                        .frame(width: geometry.size.width * CGFloat(disk.usedPercent / 100), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text(LFormat("systemHealth.disk.used %@", disk.formattedUsed))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(LFormat("systemHealth.disk.free %@", disk.formattedAvailable))
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }

    private var diskColor: Color {
        if disk.usedPercent < 70 {
            return .green
        } else if disk.usedPercent < 85 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Battery Info Card

struct BatteryInfoCard: View {
    let battery: BatteryInfo
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: batteryIcon)
                    .font(.title3)
                    .foregroundStyle(batteryColor)

                Text(L("systemHealth.battery.title"))
                    .font(Theme.Typography.subheadline.weight(.medium))

                Spacer()

                if battery.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            HStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(battery.percentage)%")
                        .font(Theme.Typography.title2)
                        .foregroundStyle(batteryColor)

                    Text(L("systemHealth.battery.charge"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }

                if let cycles = battery.cycleCount {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(cycles)")
                            .font(Theme.Typography.title2)

                        Text(L("systemHealth.battery.cycles"))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(battery.health)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(healthColor)

                    Text(L("systemHealth.battery.health"))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }

    private var batteryIcon: String {
        if battery.isCharging {
            return "battery.100.bolt"
        } else if battery.percentage > 75 {
            return "battery.100"
        } else if battery.percentage > 50 {
            return "battery.75"
        } else if battery.percentage > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private var batteryColor: Color {
        if battery.percentage > 20 {
            return .green
        } else {
            return .red
        }
    }

    private var healthColor: Color {
        switch battery.health.lowercased() {
        case "good", "normal": return .green
        case "fair": return .orange
        default: return .red
        }
    }
}

// MARK: - Mac Info Card

struct MacInfoCard: View {
    @State private var isHovered = false

    private var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private var macModel: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    private var processorInfo: String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        let fullBrand = String(cString: brand)
        // Simplify the processor name
        if fullBrand.contains("Apple") {
            return fullBrand
        } else if fullBrand.contains("Intel") {
            return fullBrand.replacingOccurrences(of: "(R)", with: "").replacingOccurrences(of: "(TM)", with: "")
        }
        return fullBrand
    }

    private var memorySize: String {
        let bytes = ProcessInfo.processInfo.physicalMemory
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "laptopcomputer")
                    .font(.title3)
                    .foregroundStyle(.purple)

                Text(L("systemHealth.system.title"))
                    .font(Theme.Typography.subheadline.weight(.medium))

                Spacer()
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                InfoRow(label: L("systemHealth.system.macos"), value: macOSVersion)
                InfoRow(label: L("systemHealth.system.model"), value: macModel)
                InfoRow(label: L("systemHealth.system.memory"), value: memorySize)
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .glassCard()
        .hoverEffect(isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    SystemHealthView(viewModel: SystemHealthViewModel())
        .frame(width: 900, height: 700)
}
