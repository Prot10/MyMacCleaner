import SwiftUI

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
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, Theme.Spacing.xxs)
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

    // MARK: - Private Properties

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
