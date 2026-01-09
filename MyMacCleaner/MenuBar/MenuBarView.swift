import SwiftUI
import AppKit

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @StateObject private var statsProvider = SystemStatsProvider.shared
    @StateObject private var menuBarController = MenuBarController.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            headerSection

            Divider()
                .padding(.horizontal, 12)

            // Stats sections
            VStack(alignment: .leading, spacing: 2) {
                cpuSection
                memorySection
                diskSection
            }
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 12)

            // Display mode section
            displayModeSection

            Divider()
                .padding(.horizontal, 12)

            // Actions
            actionsSection
        }
        .frame(width: 280)
        .background(VisualEffectBackground(material: .popover))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 8) {
            Image("MenuBarIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)

            Text("MyMacCleaner")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - CPU Section

    private var cpuSection: some View {
        MenuBarRow(
            icon: "cpu",
            iconColor: cpuColor,
            title: L("menuBar.cpu"),
            value: statsProvider.stats.formattedCPU,
            valueColor: cpuColor,
            progress: statsProvider.stats.cpuUsage / 100,
            progressColor: cpuColor
        )
    }

    private var cpuColor: Color {
        let usage = statsProvider.stats.cpuUsage
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .green
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarRow(
                icon: "memorychip",
                iconColor: memoryColor,
                title: L("menuBar.memory"),
                value: "\(statsProvider.stats.formattedMemory) / \(statsProvider.stats.formattedMemoryTotal)",
                valueColor: memoryColor,
                progress: statsProvider.stats.memoryUsagePercent / 100,
                progressColor: memoryColor
            )

            // Memory pressure indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(memoryColor)
                    .frame(width: 8, height: 8)
                Text(memoryPressureText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }

    private var memoryColor: Color {
        let usage = statsProvider.stats.memoryUsagePercent
        if usage > 80 { return .red }
        if usage > 60 { return .orange }
        return .green
    }

    private var memoryPressureText: String {
        let pressure = statsProvider.stats.memoryPressure
        if pressure > 0.8 { return L("menuBar.memory.pressure.critical") }
        if pressure > 0.6 { return L("menuBar.memory.pressure.warning") }
        return L("menuBar.memory.pressure.normal")
    }

    // MARK: - Disk Section

    private var diskSection: some View {
        MenuBarRow(
            icon: "internaldrive",
            iconColor: diskColor,
            title: L("menuBar.disk"),
            value: diskUsageText,
            valueColor: diskColor,
            progress: diskUsagePercent,
            progressColor: diskColor
        )
    }

    private var diskUsageText: String {
        let (used, total) = getDiskUsage()
        let usedFormatted = ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
        let totalFormatted = ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
        return "\(usedFormatted) / \(totalFormatted)"
    }

    private var diskUsagePercent: Double {
        let (used, total) = getDiskUsage()
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }

    private var diskColor: Color {
        let percent = diskUsagePercent
        if percent > 0.9 { return .red }
        if percent > 0.7 { return .orange }
        return .green
    }

    private func getDiskUsage() -> (used: Int64, total: Int64) {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        do {
            let values = try homeURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let available = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            return (total - available, total)
        } catch {
            return (0, 0)
        }
    }

    // MARK: - Display Mode Section

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L("menuBar.displayMode"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            ForEach(MenuBarController.DisplayMode.allCases, id: \.rawValue) { mode in
                MenuBarButton(
                    title: mode.localizedName,
                    icon: iconForMode(mode),
                    isSelected: menuBarController.displayMode == mode
                ) {
                    menuBarController.setDisplayMode(mode)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func iconForMode(_ mode: MenuBarController.DisplayMode) -> String {
        switch mode {
        case .cpuOnly: return "cpu"
        case .ramOnly: return "memorychip"
        case .cpuAndRam: return "square.grid.2x2"
        case .icon: return "gauge.with.needle"
        }
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            MenuBarButton(title: L("menuBar.action.scan"), icon: "magnifyingglass") {
                openMainApp()
                runSmartScan()
            }

            MenuBarButton(title: L("menuBar.action.openApp"), icon: "macwindow") {
                openMainApp()
            }

            Divider()
                .padding(.horizontal, 12)

            MenuBarButton(title: L("menuBar.quit"), icon: "power") {
                NSApp.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }

    private func openMainApp() {
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApp.windows {
            if window.title == "MyMacCleaner" || window.contentView?.subviews.first is NSHostingView<ContentView> {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        if let mainWindow = NSApp.windows.first(where: { $0.isVisible }) {
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func runSmartScan() {
        NotificationCenter.default.post(name: .triggerSmartScan, object: nil)
    }
}

// MARK: - Menu Bar Row Component

struct MenuBarRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let valueColor: Color
    let progress: Double
    let progressColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)

                Spacer()

                Text(value)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(valueColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)

                    Capsule()
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(max(progress, 0), 1), height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Menu Bar Button Component

struct MenuBarButton: View {
    let title: String
    let icon: String
    var isSelected: Bool = false
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "\(icon).fill" : icon)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 20)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isHovering ? Color.primary.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let triggerSmartScan = Notification.Name("triggerSmartScan")
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .frame(height: 450)
}
