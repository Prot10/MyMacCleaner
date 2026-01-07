import SwiftUI

// MARK: - Shared Toast Type

/// Shared toast notification type used across all ViewModels
/// Consolidates the previously duplicated ToastType enums
enum ToastType: Sendable {
    case success
    case error
    case info

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(type.color)

            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: 400)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(Theme.Animation.spring) {
                isVisible = true
            }
        }
    }
}

// MARK: - Cleaning Progress Overlay

struct CleaningProgressOverlay: View {
    let progress: Double
    let category: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Animated icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                // Progress ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(Theme.Animation.spring, value: progress)

                // Icon
                Image(systemName: "trash.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.orange)
            }

            // Text
            VStack(spacing: Theme.Spacing.xs) {
                Text("Cleaning...")
                    .font(Theme.Typography.title2)

                if !category.isEmpty {
                    Text(category)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(Int(progress * 100))%")
                    .font(Theme.Typography.title.monospacedDigit())
                    .foregroundStyle(.orange)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(Theme.Animation.spring, value: progress)
                }
            }
            .frame(width: 200, height: 8)
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 280)
        .glassCardProminent()
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Toast Success") {
    VStack {
        Spacer()
        ToastView(
            message: "Cleaned 1.5 GB successfully!",
            type: .success,
            onDismiss: {}
        )
        Spacer()
    }
    .frame(width: 500, height: 300)
    .background(Color.black.opacity(0.8))
}

#Preview("Toast Error") {
    VStack {
        Spacer()
        ToastView(
            message: "Failed to clean items",
            type: .error,
            onDismiss: {}
        )
        Spacer()
    }
    .frame(width: 500, height: 300)
    .background(Color.black.opacity(0.8))
}

#Preview("Cleaning Progress") {
    ZStack {
        Color.black.opacity(0.5)
            .ignoresSafeArea()

        CleaningProgressOverlay(
            progress: 0.65,
            category: "User Cache"
        )
    }
    .frame(width: 500, height: 400)
}
