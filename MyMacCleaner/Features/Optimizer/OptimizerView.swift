import SwiftUI

struct OptimizerView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = OptimizerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Memory Section
                MemoryOptimizerCard(
                    memoryStats: viewModel.memoryStats,
                    isPurging: viewModel.isPurging,
                    onPurge: { Task { await viewModel.purgeMemory() } }
                )

                // Launch Agents Section
                LaunchAgentsCard(
                    agents: viewModel.launchAgents,
                    onToggle: { agent in
                        Task { await viewModel.toggleAgent(agent) }
                    }
                )

                // Login Items Section
                LoginItemsCard()
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await viewModel.loadData()
        }
    }
}

// MARK: - Memory Optimizer Card

struct MemoryOptimizerCard: View {
    let memoryStats: MemoryDisplayStats?
    let isPurging: Bool
    let onPurge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("Memory")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                if isPurging {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Free Up RAM") {
                        onPurge()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(memoryStats == nil)
                }
            }

            if let stats = memoryStats {
                // Memory bar
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: geo.size.width * stats.wiredPercentage)

                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geo.size.width * stats.activePercentage)

                            Rectangle()
                                .fill(Color.yellow)
                                .frame(width: geo.size.width * stats.compressedPercentage)

                            Rectangle()
                                .fill(Color.green.opacity(0.5))
                                .frame(width: geo.size.width * stats.inactivePercentage)

                            Rectangle()
                                .fill(Color.green)
                        }
                        .cornerRadius(4)
                    }
                    .frame(height: 20)

                    // Legend
                    HStack(spacing: 16) {
                        LegendItem(color: .red, label: "Wired", value: stats.wiredText)
                        LegendItem(color: .orange, label: "Active", value: stats.activeText)
                        LegendItem(color: .yellow, label: "Compressed", value: stats.compressedText)
                        LegendItem(color: .green, label: "Free", value: stats.freeText)
                    }
                    .font(.caption)
                }
            } else {
                Text("Loading memory information...")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Launch Agents Card

struct LaunchAgentsCard: View {
    let agents: [LaunchAgentInfo]
    let onToggle: (LaunchAgentInfo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundStyle(.purple)

                Text("Launch Agents")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(agents.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if agents.isEmpty {
                Text("No launch agents found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(agents) { agent in
                        HStack {
                            Toggle(isOn: Binding(
                                get: { agent.isEnabled },
                                set: { _ in onToggle(agent) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(agent.label)
                                        .font(.body)
                                    Text(agent.path)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }
                            .toggleStyle(.switch)
                        }
                        .padding(.vertical, 4)

                        if agent.id != agents.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Login Items Card

struct LoginItemsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("Login Items")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button("Open System Settings") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
            }

            Text("Manage apps that open at login in System Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

#Preview {
    OptimizerView()
        .environment(AppState())
        .frame(width: 600, height: 700)
}
