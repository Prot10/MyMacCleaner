import SwiftUI

// MARK: - Skeleton View Modifier

/// Applies skeleton loading effect with shimmer animation
struct SkeletonModifier: ViewModifier {
    let isLoading: Bool

    @State private var shimmerOffset: CGFloat = -200

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                .overlay {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 100)
                        .offset(x: shimmerOffset)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false)
                            ) {
                                shimmerOffset = geo.size.width + 200
                            }
                        }
                    }
                    .mask(content.redacted(reason: .placeholder))
                }
                .allowsHitTesting(false)
        } else {
            content
        }
    }
}

extension View {
    func skeleton(isLoading: Bool) -> some View {
        modifier(SkeletonModifier(isLoading: isLoading))
    }
}

// MARK: - Skeleton Shapes

struct SkeletonRectangle: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.secondary.opacity(0.15))
            .frame(width: width, height: height)
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: size, height: size)
    }
}

// MARK: - Shimmer Effect

struct ShimmerView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.3),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: phase)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 400
            }
        }
    }
}

// MARK: - Dashboard Skeleton

struct DashboardSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero button skeleton
                VStack(spacing: 24) {
                    SkeletonCircle(size: 160)
                        .shimmerOverlay()

                    VStack(spacing: 8) {
                        SkeletonRectangle(width: 120, height: 32, cornerRadius: 8)
                        SkeletonRectangle(width: 180, height: 16)
                    }
                }
                .padding(.vertical, 32)

                // Stats cards skeleton
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        StatsCardSkeleton()
                    }
                }
                .padding(.horizontal, 24)

                // Cleanup card skeleton
                CleanupCardSkeleton()
                    .padding(.horizontal, 24)

                // Storage card skeleton
                StorageCardSkeleton()
                    .padding(.horizontal, 24)

                Spacer(minLength: 20)
            }
            .padding(.vertical, 24)
        }
    }
}

struct StatsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                SkeletonCircle(size: 14)
                SkeletonRectangle(width: 60, height: 13)
                Spacer()
            }

            HStack(spacing: 14) {
                SkeletonCircle(size: 56)

                VStack(alignment: .leading, spacing: 4) {
                    SkeletonRectangle(width: 50, height: 26, cornerRadius: 8)
                    SkeletonRectangle(width: 80, height: 11)
                }

                Spacer()
            }
        }
        .liquidGlassCard(cornerRadius: 18, style: .thin, padding: 16)
        .shimmerOverlay()
    }
}

struct CleanupCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRectangle(width: 120, height: 13)
                    SkeletonRectangle(width: 100, height: 32, cornerRadius: 8)
                }

                Spacer()

                SkeletonCircle(size: 56)
            }

            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 10) {
                        SkeletonCircle(size: 8)
                        SkeletonRectangle(width: 100, height: 13)
                        Spacer()
                        SkeletonRectangle(width: 60, height: 13)
                    }
                }
            }
            .padding(.vertical, 8)

            HStack(spacing: 12) {
                SkeletonRectangle(height: 44, cornerRadius: 14)
                SkeletonRectangle(height: 44, cornerRadius: 14)
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
        .shimmerOverlay()
    }
}

struct StorageCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SkeletonRectangle(width: 140, height: 13)

            HStack(spacing: 28) {
                SkeletonCircle(size: 150)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        HStack(spacing: 10) {
                            SkeletonRectangle(width: 12, height: 12, cornerRadius: 3)
                            SkeletonRectangle(width: 80, height: 13)
                            Spacer()
                            SkeletonRectangle(width: 50, height: 12)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
        .shimmerOverlay()
    }
}

// MARK: - Cleaner Skeleton

struct CleanerSkeletonView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header skeleton
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonRectangle(width: 160, height: 24, cornerRadius: 8)
                    SkeletonRectangle(width: 240, height: 14)
                }

                Spacer()

                SkeletonRectangle(width: 100, height: 40, cornerRadius: 14)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { _ in
                        CleanerRowSkeleton()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .shimmerOverlay()
    }
}

struct CleanerRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            SkeletonRectangle(width: 24, height: 24, cornerRadius: 6)
            SkeletonRectangle(width: 40, height: 40, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 4) {
                SkeletonRectangle(width: 120, height: 15)
                SkeletonRectangle(width: 60, height: 12)
            }

            Spacer()

            SkeletonRectangle(width: 80, height: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}

// MARK: - Uninstaller Skeleton

struct UninstallerSkeletonView: View {
    var body: some View {
        HSplitView {
            // App list skeleton
            VStack(spacing: 0) {
                // Search bar
                SkeletonRectangle(height: 40, cornerRadius: 10)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                Divider()

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(0..<10, id: \.self) { _ in
                            AppRowSkeleton()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
            }
            .frame(minWidth: 260, maxWidth: 320)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))

            // Detail placeholder
            VStack(spacing: 24) {
                SkeletonCircle(size: 100)
                SkeletonRectangle(width: 200, height: 18)
                SkeletonRectangle(width: 280, height: 14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .shimmerOverlay()
    }
}

struct AppRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonRectangle(width: 44, height: 44, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 3) {
                SkeletonRectangle(width: 100, height: 14)
                SkeletonRectangle(width: 60, height: 12)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Optimizer Skeleton

struct OptimizerSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonRectangle(width: 120, height: 24, cornerRadius: 8)
                        SkeletonRectangle(width: 220, height: 14)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Memory card
                MemoryCardSkeleton()
                    .padding(.horizontal, 24)

                // Launch agents card
                LaunchAgentsCardSkeleton()
                    .padding(.horizontal, 24)

                // Login items card
                HStack(spacing: 16) {
                    SkeletonCircle(size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonRectangle(width: 100, height: 18)
                        SkeletonRectangle(width: 180, height: 13)
                    }

                    Spacer()

                    SkeletonRectangle(width: 120, height: 40, cornerRadius: 14)
                }
                .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .shimmerOverlay()
    }
}

struct MemoryCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 12) {
                    SkeletonCircle(size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonRectangle(width: 80, height: 18)
                        SkeletonRectangle(width: 100, height: 13)
                    }
                }

                Spacer()

                SkeletonRectangle(width: 120, height: 40, cornerRadius: 14)
            }

            VStack(spacing: 14) {
                SkeletonRectangle(height: 28, cornerRadius: 8)

                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonRectangle(width: 90, height: 28, cornerRadius: 14)
                    }
                }
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
    }
}

struct LaunchAgentsCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                SkeletonCircle(size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    SkeletonRectangle(width: 120, height: 18)
                    SkeletonRectangle(width: 140, height: 13)
                }

                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(0..<5, id: \.self) { _ in
                    HStack(spacing: 14) {
                        SkeletonCircle(size: 10)

                        VStack(alignment: .leading, spacing: 3) {
                            SkeletonRectangle(width: 180, height: 14)
                            SkeletonRectangle(width: 240, height: 11)
                        }

                        Spacer()

                        SkeletonRectangle(width: 50, height: 30, cornerRadius: 15)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
    }
}

// MARK: - Shimmer Overlay Extension

extension View {
    func shimmerOverlay() -> some View {
        self.modifier(ShimmerOverlayModifier())
    }
}

struct ShimmerOverlayModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.3), location: 0.3),
                            .init(color: .white.opacity(0.3), location: 0.7),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: geo.size.width * phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                            phase = 1.6
                        }
                    }
                }
                .mask(content)
                .allowsHitTesting(false)
            }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cleanPurple, Color.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Previews

#Preview("Dashboard Skeleton") {
    DashboardSkeletonView()
        .frame(width: 750, height: 700)
        .liquidGlassBackground()
}

#Preview("Cleaner Skeleton") {
    CleanerSkeletonView()
        .frame(width: 650, height: 550)
        .liquidGlassBackground()
}

#Preview("Optimizer Skeleton") {
    OptimizerSkeletonView()
        .frame(width: 650, height: 750)
        .liquidGlassBackground()
}
