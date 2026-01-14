import SwiftUI

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
                        .font(Theme.Typography.size11.weight(.bold))
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
                        .font(Theme.Typography.size20Bold.monospacedDigit())
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

    // MARK: - Private Properties

    private var overallProgress: CGFloat {
        guard totalCount > 0 else { return 0 }
        let completedTasks = CGFloat(currentIndex - 1)
        let currentTaskContribution = CGFloat(taskProgress) / CGFloat(totalCount)
        return (completedTasks / CGFloat(totalCount)) + currentTaskContribution
    }
}
