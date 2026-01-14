import SwiftUI

// MARK: - Update Row

struct UpdateRow: View {
    let update: AppUpdate

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon placeholder (we don't have app icon here)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.down.circle.fill")
                    .font(Theme.Typography.size20)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(update.appName)
                    .font(Theme.Typography.subheadline.weight(.semibold))

                HStack(spacing: Theme.Spacing.xs) {
                    Text(update.currentVersion)
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.right")
                        .font(Theme.Typography.caption2)
                        .foregroundStyle(.tertiary)

                    Text(update.latestVersion)
                        .foregroundStyle(.orange)
                }
                .font(Theme.Typography.caption)
            }

            Spacer()

            // Source badge
            Text(update.source.rawValue)
                .font(Theme.Typography.caption2)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())

            // Download button
            if let downloadURL = update.downloadURL {
                Link(destination: downloadURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                        Text(L("applications.updates.download"))
                    }
                    .font(Theme.Typography.size12Medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Color.white.opacity(isHovered ? 0.05 : 0))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover { isHovered = $0 }
    }
}
