import SwiftUI
import Charts

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()
    @State private var appearId = UUID() // Forces re-animation on page switch

    /// Check if disk categories are still loading
    private var isDiskCategoriesLoading: Bool {
        appState.loadingState.dashboard.data?.diskCategories == nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero Section with Scan Button
                HeroSectionView(
                    isScanning: viewModel.isScanning,
                    scanProgress: viewModel.scanProgress,
                    cleanableSize: viewModel.totalCleanableSize,
                    onScanTap: { Task { await viewModel.startScan() } }
                )
                .appearAnimation(delay: 0)

                // Quick Stats Cards - show immediately when available
                if viewModel.memoryStats != nil {
                    HStack(spacing: 16) {
                        GlassStatsCard(
                            title: "Memory",
                            value: viewModel.memoryUsageText,
                            percentage: viewModel.memoryUsagePercentage,
                            icon: "memorychip.fill",
                            color: viewModel.memoryColor
                        )
                        .cardAppear(index: 0)

                        GlassStatsCard(
                            title: "Storage",
                            value: viewModel.storageUsageText,
                            percentage: viewModel.storageUsagePercentage,
                            icon: "internaldrive.fill",
                            color: viewModel.storageColor
                        )
                        .cardAppear(index: 1)

                        GlassStatsCard(
                            title: "CPU",
                            value: viewModel.cpuUsageText,
                            percentage: viewModel.cpuUsagePercentage,
                            icon: "cpu.fill",
                            color: viewModel.cpuColor
                        )
                        .cardAppear(index: 2)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Stats skeleton
                    HStack(spacing: 16) {
                        ForEach(0..<3, id: \.self) { _ in
                            StatsCardSkeleton()
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Cleanup Summary
                if viewModel.totalCleanableSize > 0 {
                    GlassCleanupCard(
                        totalSize: viewModel.totalCleanableSize,
                        categories: viewModel.cleanupCategories,
                        onCleanNow: { Task { await viewModel.performCleanup() } },
                        onViewDetails: { appState.selectedNavigation = .cleaner }
                    )
                    .padding(.horizontal, 24)
                    .slideIn(from: .bottom, delay: 0.2)
                }

                // Storage Breakdown Chart - show skeleton while loading
                if !viewModel.diskCategories.isEmpty {
                    GlassStorageCard(categories: viewModel.diskCategories)
                        .padding(.horizontal, 24)
                        .slideIn(from: .bottom, delay: 0.3)
                } else if isDiskCategoriesLoading {
                    StorageCardSkeleton()
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical, 24)
            .id(appearId) // Re-triggers animations
        }
        .task {
            // Use preloaded data if available
            let preloadedData = appState.loadingState.dashboard.data
            await viewModel.loadData(from: preloadedData)
        }
        .onChange(of: appState.loadingState.dashboard.data?.diskCategories) { _, newValue in
            // Update when disk categories finish loading
            if let categories = newValue {
                viewModel.diskCategories = categories
            }
        }
        .onAppear {
            // Trigger re-animation when switching to this page
            appearId = UUID()
        }
    }
}

// MARK: - Hero Section

struct HeroSectionView: View {
    let isScanning: Bool
    let scanProgress: Double
    let cleanableSize: Int64
    let onScanTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Large Scan Button with glass effect
            GlassHeroButton(
                isScanning: isScanning,
                progress: scanProgress,
                onTap: onScanTap
            )

            // Status Text
            VStack(spacing: 8) {
                if isScanning {
                    Text("Scanning your Mac...")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                } else if cleanableSize > 0 {
                    Text("\(ByteCountFormatter.string(fromByteCount: cleanableSize, countStyle: .file))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("can be cleaned")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Your Mac is ready")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Click to scan for cleanable files")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Glass Hero Button

struct GlassHeroButton: View {
    let isScanning: Bool
    let progress: Double
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var pulseAnimation = false

    private let buttonSize: CGFloat = 160

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: buttonSize, height: buttonSize)

                // Gradient overlay - Electric Violet to Deep Purple
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cleanPurple,
                                Color.neonViolet,
                                Color.electricBlue.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: buttonSize - 8, height: buttonSize - 8)

                // Glass border
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: buttonSize, height: buttonSize)

                // Pulse animation ring (when idle) - Electric violet glow
                if !isScanning {
                    Circle()
                        .stroke(Color.cleanPurple.opacity(0.5), lineWidth: 2)
                        .frame(width: buttonSize + 24, height: buttonSize + 24)
                        .scaleEffect(pulseAnimation ? 1.15 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.7)
                }

                // Progress ring (when scanning)
                if isScanning {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: buttonSize - 20, height: buttonSize - 20)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: buttonSize - 20, height: buttonSize - 20)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                }

                // Icon and text
                VStack(spacing: 10) {
                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.3)
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    Text(isScanning ? "Scanning..." : "Smart Scan")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: Color.cleanPurple.opacity(0.5), radius: isHovering ? 35 : 25, x: 0, y: 10)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            startPulseAnimation()
        }
        .disabled(isScanning)
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: false)
        ) {
            pulseAnimation = true
        }
    }
}

// MARK: - Glass Stats Card

struct GlassStatsCard: View {
    let title: String
    let value: String
    let percentage: Double
    let icon: String
    let color: Color

    @State private var animatedPercentage: Double = 0
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)

                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack(spacing: 14) {
                // Animated Circular Gauge with glass effect
                AnimatedProgressRing(
                    progress: percentage,
                    lineWidth: 6,
                    gradient: LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)

                // Value with animated number
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(animatedPercentage * 100))%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())

                    Text(value)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
        }
        .liquidGlassCard(cornerRadius: 18, style: .thin, padding: 16)
        .scaleEffect(isHovering ? 1.02 : 1)
        .shadow(color: color.opacity(isHovering ? 0.3 : 0), radius: 15, x: 0, y: 8)
        .animation(AppAnimation.springFast, value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animatedPercentage = percentage
            }
        }
        .onChange(of: percentage) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedPercentage = newValue
            }
        }
    }
}

// MARK: - Glass Cleanup Card

struct GlassCleanupCard: View {
    let totalSize: Int64
    let categories: [CleanupCategorySummary]
    let onCleanNow: () -> Void
    let onViewDetails: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Cleanup Available")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                Spacer()

                // Animated health indicator
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 56, height: 56)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.cleanGreen)
                }
            }

            // Categories breakdown
            if !categories.isEmpty {
                VStack(spacing: 10) {
                    ForEach(categories.prefix(4)) { category in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(categoryColor(for: category.name))
                                .frame(width: 8, height: 8)

                            Text(category.name)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(category.formattedSize)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                        }
                    }

                    if categories.count > 4 {
                        Text("and \(categories.count - 4) more categories")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
            }

            // Action buttons with glass style
            HStack(spacing: 12) {
                Button(action: onViewDetails) {
                    Text("View Details")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: false))

                Button(action: onCleanNow) {
                    Text("Clean Now")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.cleanGreen.opacity(0.4), .cleanGreen.opacity(0.1), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func categoryColor(for name: String) -> Color {
        switch name.lowercased() {
        case let n where n.contains("cache"): return .cleanBlue
        case let n where n.contains("log"): return .cleanOrange
        case let n where n.contains("xcode"): return .cleanPurple
        case let n where n.contains("trash"): return .cleanRed
        default: return .gray
        }
    }
}

// MARK: - Glass Storage Card

struct GlassStorageCard: View {
    let categories: [DiskCategory]

    @State private var chartAnimationProgress: CGFloat = 0
    @State private var legendVisible: [Bool] = []
    @State private var showFDASheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            Text("Storage Breakdown")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 28) {
                // Animated Pie Chart with glass background
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 150, height: 150)

                    Chart(categories) { category in
                        SectorMark(
                            angle: .value("Size", max(category.sizeBytes, category.needsPermission ? 1_000_000_000 : 0)),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(category.needsPermission ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(colorForCategory(category.colorName).gradient))
                        .opacity(Double(chartAnimationProgress))
                    }
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90 + (90 * Double(chartAnimationProgress))))
                    .scaleEffect(0.8 + (0.2 * Double(chartAnimationProgress)))
                }

                // Legend with staggered animation
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(categories.prefix(5).enumerated()), id: \.element.id) { index, category in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(category.needsPermission ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(colorForCategory(category.colorName).gradient))
                                .frame(width: 12, height: 12)

                            Text(category.name)
                                .font(.system(size: 13))
                                .foregroundStyle(category.needsPermission ? .secondary : .primary)

                            Spacer()

                            if category.needsPermission {
                                Button {
                                    showFDASheet = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 9))
                                        Text("Grant Access")
                                            .font(.system(size: 10, weight: .medium))
                                    }
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.orange.opacity(0.15), in: Capsule())
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text(category.formattedSize)
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .opacity(legendVisible.indices.contains(index) && legendVisible[index] ? 1 : 0)
                        .offset(x: legendVisible.indices.contains(index) && legendVisible[index] ? 0 : 20)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .liquidGlassCard(cornerRadius: 20, style: .thin, padding: 20)
        .onAppear {
            // Initialize legend visibility
            legendVisible = Array(repeating: false, count: min(categories.count, 5))

            // Animate chart
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                chartAnimationProgress = 1
            }

            // Stagger legend items
            for index in legendVisible.indices {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4 + Double(index) * 0.1)) {
                    legendVisible[index] = true
                }
            }
        }
        .sheet(isPresented: $showFDASheet) {
            FDAPermissionSheet()
        }
    }

    private func colorForCategory(_ name: String) -> Color {
        switch name {
        case "blue": return .cleanBlue
        case "orange": return .cleanOrange
        case "green": return .cleanGreen
        case "purple": return .cleanPurple
        case "red": return .cleanRed
        case "gray": return .gray
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(AppState())
        .frame(width: 750, height: 700)
}
