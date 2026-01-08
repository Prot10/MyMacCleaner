import SwiftUI

// MARK: - Menu Bar View

struct MenuBarView: View {
    @StateObject private var statsProvider = SystemStatsProvider.shared
    @StateObject private var menuBarController = MenuBarController.shared
    @State private var isHoveringOpenApp = false
    @State private var isHoveringScan = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Stats
            ScrollView {
                VStack(spacing: 12) {
                    cpuSection
                    memorySection
                    diskSection
                }
                .padding(16)
            }

            Divider()

            // Quick Actions
            quickActionsSection

            Divider()

            // Footer
            footerSection
        }
        .frame(width: 320)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "gauge.with.needle.fill")
                .font(.title2)
                .foregroundStyle(.blue.gradient)

            Text("MyMacCleaner")
                .font(.headline)

            Spacer()

            // Display mode picker
            Menu {
                ForEach(MenuBarController.DisplayMode.allCases, id: \.rawValue) { mode in
                    Button {
                        menuBarController.setDisplayMode(mode)
                    } label: {
                        HStack {
                            Text(mode.localizedName)
                            if menuBarController.displayMode == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(16)
    }

    // MARK: - CPU Section

    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.blue)
                Text(L("menuBar.cpu"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(statsProvider.stats.formattedCPU)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(cpuColor)
            }

            // CPU Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(cpuColor.gradient)
                        .frame(width: geometry.size.width * min(statsProvider.stats.cpuUsage / 100, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    private var cpuColor: Color {
        let usage = statsProvider.stats.cpuUsage
        if usage > 80 { return .red }
        if usage > 50 { return .orange }
        return .green
    }

    // MARK: - Memory Section

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.purple)
                Text(L("menuBar.memory"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(statsProvider.stats.formattedMemory) / \(statsProvider.stats.formattedMemoryTotal)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(memoryColor)
            }

            // Memory Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(memoryColor.gradient)
                        .frame(width: geometry.size.width * min(statsProvider.stats.memoryUsagePercent / 100, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Memory pressure indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(memoryColor)
                    .frame(width: 6, height: 6)
                Text(memoryPressureText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.orange)
                Text(L("menuBar.disk"))
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(diskUsageText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(diskColor)
            }

            // Disk Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(diskColor.gradient)
                        .frame(width: geometry.size.width * diskUsagePercent, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
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

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                openMainApp()
                runSmartScan()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                    Text(L("menuBar.action.scan"))
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isHoveringScan ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringScan = $0 }

            Button {
                openMainApp()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "macwindow")
                    Text(L("menuBar.action.openApp"))
                }
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isHoveringOpenApp ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringOpenApp = $0 }
        }
        .padding(16)
    }

    private func openMainApp() {
        NSApp.activate(ignoringOtherApps: true)

        // Find and activate the main window
        for window in NSApp.windows {
            if window.title == "MyMacCleaner" || window.contentView?.subviews.first is NSHostingView<ContentView> {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }

        // If no window found, create a new one
        if let mainWindow = NSApp.windows.first(where: { $0.isVisible }) {
            mainWindow.makeKeyAndOrderFront(nil)
        }
    }

    private func runSmartScan() {
        // Post notification to trigger scan in main app
        NotificationCenter.default.post(name: .triggerSmartScan, object: nil)
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text(L("menuBar.lastUpdate"))
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()

            Button {
                NSApp.terminate(nil)
            } label: {
                Text(L("menuBar.quit"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let triggerSmartScan = Notification.Name("triggerSmartScan")
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .frame(height: 400)
}
