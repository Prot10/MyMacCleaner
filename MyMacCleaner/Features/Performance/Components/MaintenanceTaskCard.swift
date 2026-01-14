import SwiftUI

// MARK: - Maintenance Task Card

struct MaintenanceTaskCard: View {
    let task: MaintenanceTask
    let isRunning: Bool
    let progress: Double
    let result: PerformanceViewModel.TaskResult?
    let onRun: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header row: Icon + Name on left, Run button on right
            HStack(spacing: Theme.Spacing.sm) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBackgroundColor.opacity(0.15))
                        .frame(width: 32, height: 32)

                    if isRunning {
                        ProgressView()
                            .controlSize(.small)
                    } else if let result = result, result != .pending {
                        resultIcon(for: result)
                    } else {
                        Image(systemName: task.icon)
                            .font(Theme.Typography.size14Semibold)
                            .foregroundStyle(task.color)
                    }
                }

                // Task name
                Text(task.localizedName)
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                // Admin badge
                if task.requiresAdmin {
                    Image(systemName: "lock.shield")
                        .font(Theme.Typography.size10)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                // Run button or status
                if let result = result, result != .pending && result != .running {
                    statusBadge(for: result)
                } else {
                    Button(action: onRun) {
                        HStack(spacing: 4) {
                            if isRunning {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(Theme.Typography.size10)
                            }
                            Text(isRunning ? L("performance.maintenance.running") : L("performance.maintenance.run"))
                        }
                        .font(Theme.Typography.size11Medium)
                        .foregroundStyle(isRunning ? .secondary : task.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(task.color.opacity(isHovered && !isRunning ? 0.2 : 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                }
            }

            // Description
            Text(task.localizedDescription)
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Progress bar when running
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
        .onHover { isHovered = $0 }
        .animation(Theme.Animation.spring, value: result)
        .animation(Theme.Animation.spring, value: isRunning)
    }

    // MARK: - Private Properties

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

    // MARK: - Private Methods

    @ViewBuilder
    private func resultIcon(for result: PerformanceViewModel.TaskResult) -> some View {
        switch result {
        case .success:
            Image(systemName: "checkmark")
                .font(Theme.Typography.size12.weight(.bold))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark")
                .font(Theme.Typography.size12.weight(.bold))
                .foregroundStyle(.red)
        case .skipped:
            Image(systemName: "forward.fill")
                .font(Theme.Typography.size11Semibold)
                .foregroundStyle(.orange)
        case .pending:
            Image(systemName: task.icon)
                .font(Theme.Typography.size14Semibold)
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
                    .font(Theme.Typography.size10.weight(.bold))
                Text(L("common.done"))
            case .failed:
                Image(systemName: "xmark")
                    .font(Theme.Typography.size10.weight(.bold))
                Text(L("common.failed"))
            case .skipped:
                Image(systemName: "forward.fill")
                    .font(Theme.Typography.size10.weight(.bold))
                Text(L("common.skipped"))
            default:
                EmptyView()
            }
        }
        .font(Theme.Typography.size10Medium)
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
