import SwiftUI

struct OptimizerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OptimizerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Optimizer")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("Optimize your Mac's performance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Memory Section with glass effect
                GlassMemoryCard(
                    memoryStats: viewModel.memoryStats,
                    isPurging: viewModel.isPurging,
                    onPurge: { Task { await viewModel.purgeMemory() } }
                )
                .padding(.horizontal, 24)

                // Launch Agents Section
                GlassLaunchAgentsCard(
                    agents: viewModel.launchAgents,
                    onToggle: { agent in
                        Task { await viewModel.toggleAgent(agent) }
                    }
                )
                .padding(.horizontal, 24)

                // Login Items Section
                GlassLoginItemsCard()
                    .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .task {
            // Use preloaded data if available
            let preloadedData = appState.loadingState.optimizer.data
            if preloadedData != nil {
                viewModel.loadData(from: preloadedData)
            } else {
                await viewModel.loadData()
            }
        }
    }
}

// MARK: - Glass Memory Card

struct GlassMemoryCard: View {
    let memoryStats: MemoryDisplayStats?
    let isPurging: Bool
    let onPurge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "memorychip.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.cleanBlue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        if let stats = memoryStats {
                            Text("\(stats.freeText) available")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Button {
                    onPurge()
                } label: {
                    HStack(spacing: 8) {
                        if isPurging {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "bolt.fill")
                        }
                        Text(isPurging ? "Freeing..." : "Free Up RAM")
                    }
                    .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                .disabled(memoryStats == nil || isPurging)
            }

            if let stats = memoryStats {
                // Memory visualization
                VStack(spacing: 14) {
                    // Memory bar with glass effect
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.ultraThinMaterial)

                            // Segments
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cleanRed, .cleanRed.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geo.size.width * stats.wiredPercentage)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cleanOrange, .cleanOrange.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geo.size.width * stats.activePercentage)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.yellow, .yellow.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geo.size.width * stats.compressedPercentage)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cleanGreen.opacity(0.5), .cleanGreen.opacity(0.3)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: geo.size.width * stats.inactivePercentage)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.cleanGreen, .cleanGreen.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .frame(height: 28)

                    // Legend with glass pill badges
                    HStack(spacing: 12) {
                        GlassMemoryLegendItem(color: .cleanRed, label: "Wired", value: stats.wiredText)
                        GlassMemoryLegendItem(color: .cleanOrange, label: "Active", value: stats.activeText)
                        GlassMemoryLegendItem(color: .yellow, label: "Compressed", value: stats.compressedText)
                        GlassMemoryLegendItem(color: .cleanGreen, label: "Free", value: stats.freeText)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Loading memory information...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
    }
}

struct GlassMemoryLegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.gradient)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Glass Launch Agents Card

struct GlassLaunchAgentsCard: View {
    let agents: [LaunchAgentInfo]
    let onToggle: (LaunchAgentInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.15))
                            .frame(width: 44, height: 44)

                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(Color.cleanPurple)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Launch Agents")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("\(agents.count) background services")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            if agents.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.cleanGreen)

                    Text("No launch agents found")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(agents) { agent in
                        GlassLaunchAgentRow(
                            agent: agent,
                            onToggle: { onToggle(agent) }
                        )
                    }
                }
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
    }
}

struct GlassLaunchAgentRow: View {
    let agent: LaunchAgentInfo
    let onToggle: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 14) {
            // Status indicator
            Circle()
                .fill(agent.isEnabled ? Color.cleanGreen : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(agent.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(agent.path)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { agent.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            if isHovering {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Glass Login Items Card

struct GlassLoginItemsCard: View {
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.cleanGreen)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Login Items")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Manage apps that open at login")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
                NSWorkspace.shared.open(url)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Settings")
                }
                .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(LiquidGlassButtonStyle(isProminent: false))
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
    }
}

#Preview {
    OptimizerView()
        .environment(AppState())
        .frame(width: 650, height: 750)
}
