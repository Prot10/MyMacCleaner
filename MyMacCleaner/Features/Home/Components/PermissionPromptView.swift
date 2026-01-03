import SwiftUI

// MARK: - Permission Prompt View

struct PermissionPromptView: View {
    @ObservedObject var permissionsService: PermissionsService
    let onDismiss: () -> Void
    let onContinueWithoutPermission: () -> Void

    @State private var isVisible = false
    @State private var isHoveredGrant = false
    @State private var isHoveredSkip = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Icon
            iconSection

            // Content
            contentSection

            // Features list
            featuresSection

            // Buttons
            buttonsSection
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: 500)
        .glassCardProminent()
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isVisible = true
            }
        }
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)
                .blur(radius: 20)

            // Icon container
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.blue.opacity(0.5), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.blue.gradient)
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Full Disk Access Required")
                .font(Theme.Typography.title2)

            Text("To scan all system files and provide accurate cleanup recommendations, MyMacCleaner needs Full Disk Access permission.")
                .font(Theme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This enables:")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.tertiary)

            ForEach(PermissionsService.fullDiskAccessInfo.features, id: \.self) { feature in
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)

                    Text(feature)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(Color.blue.opacity(0.05))
        )
    }

    // MARK: - Buttons Section

    private var buttonsSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Grant permission button
            Button(action: {
                permissionsService.openFullDiskAccessSettings()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Open System Settings")
                }
                .font(Theme.Typography.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            .buttonStyle(.plain)
            .scaleEffect(isHoveredGrant ? 1.02 : 1.0)
            .shadow(color: .blue.opacity(0.3), radius: isHoveredGrant ? 12 : 8, y: 4)
            .animation(Theme.Animation.fast, value: isHoveredGrant)
            .onHover { isHoveredGrant = $0 }

            // Skip button
            Button(action: onContinueWithoutPermission) {
                Text("Continue with Limited Scan")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
            }
            .buttonStyle(.plain)
            .opacity(isHoveredSkip ? 0.7 : 1.0)
            .animation(Theme.Animation.fast, value: isHoveredSkip)
            .onHover { isHoveredSkip = $0 }

            // Dismiss button for later
            Button(action: onDismiss) {
                Text("Maybe Later")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Compact Permission Banner

struct PermissionBanner: View {
    @ObservedObject var permissionsService: PermissionsService

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.orange)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text("Limited Access")
                    .font(Theme.Typography.subheadline)

                Text("Grant Full Disk Access for complete scanning")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Grant button
            Button(action: {
                permissionsService.openFullDiskAccessSettings()
            }) {
                Text("Grant")
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(Theme.Animation.fast, value: isHovered)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Permission Status View

struct PermissionStatusView: View {
    let hasFullDiskAccess: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Circle()
                .fill(hasFullDiskAccess ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .shadow(color: (hasFullDiskAccess ? Color.green : Color.orange).opacity(0.5), radius: 4)

            Text(hasFullDiskAccess ? "Full Access" : "Limited Access")
                .font(Theme.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .glassPill()
    }
}

// MARK: - Preview

#Preview("Permission Prompt") {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        PermissionPromptView(
            permissionsService: PermissionsService.shared,
            onDismiss: {},
            onContinueWithoutPermission: {}
        )
    }
    .frame(width: 600, height: 700)
}

#Preview("Permission Banner") {
    VStack {
        PermissionBanner(permissionsService: PermissionsService.shared)
    }
    .padding()
    .frame(width: 500, height: 200)
}
