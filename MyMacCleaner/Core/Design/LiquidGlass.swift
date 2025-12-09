import SwiftUI

// MARK: - Liquid Glass Design System
// Inspired by Apple's iOS 26 / macOS 26 liquid glass aesthetic

/// Glass material styles
enum GlassStyle {
    case regular
    case thin
    case thick
    case prominent

    var material: Material {
        switch self {
        case .regular: return .regularMaterial
        case .thin: return .thinMaterial
        case .thick: return .thickMaterial
        case .prominent: return .ultraThinMaterial
        }
    }
}

// MARK: - Liquid Glass Card Modifier

struct LiquidGlassCard: ViewModifier {
    var cornerRadius: CGFloat = 20
    var style: GlassStyle = .thin
    var borderOpacity: Double = 0.3
    var shadowRadius: CGFloat = 10
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(style.material)
                    .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(borderOpacity),
                                .white.opacity(borderOpacity * 0.3),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}

// MARK: - Liquid Glass Button Style

struct LiquidGlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    var cornerRadius: CGFloat = 14

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                if isProminent {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cleanPurple,
                                    Color.neonViolet
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.cleanPurple.opacity(0.5), radius: 12, x: 0, y: 6)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(isProminent ? 0.5 : 0.2),
                                .white.opacity(isProminent ? 0.1 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .foregroundStyle(isProminent ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedMeshGradient: View {
    @State private var animate = false

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [animate ? 0.6 : 0.4, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                // Top row - violet to cyan gradient
                Color.neonViolet.opacity(0.25),
                Color.cleanPurple.opacity(0.15),
                Color.electricBlue.opacity(0.20),
                // Middle row - cyan accent to pink
                Color.cleanBlue.opacity(0.15),
                .clear,
                Color.softPink.opacity(0.15),
                // Bottom row - blue to violet
                Color.electricBlue.opacity(0.18),
                Color.mintCyan.opacity(0.12),
                Color.neonViolet.opacity(0.20)
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// MARK: - Circular Progress with Glass Effect

struct GlassCircularProgress: View {
    var progress: Double
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10
    var color: Color = .blue
    var label: String = ""
    var showPercentage: Bool = true

    var body: some View {
        ZStack {
            // Background circle with glass effect
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)

            // Track
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
                .frame(width: size - lineWidth, height: size - lineWidth)

            // Progress
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7), color],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size - lineWidth, height: size - lineWidth)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

            // Center content
            VStack(spacing: 2) {
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .shadow(color: color.opacity(0.3), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Glass Sidebar Item

struct GlassSidebarItem: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? .white : color)
                        .opacity(isLoading ? 0.5 : 1)

                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(isSelected ? .white : color)
                    }
                }
                .frame(width: 32, height: 32)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(color.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(color.opacity(0.15))
                    }
                }

                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                // Small loading dot indicator
                if isLoading {
                    Circle()
                        .fill(Color.cleanOrange)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Extensions

extension View {
    func liquidGlassCard(
        cornerRadius: CGFloat = 20,
        style: GlassStyle = .thin,
        padding: CGFloat = 16
    ) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, style: style, padding: padding))
    }

    func liquidGlassBackground() -> some View {
        self.background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                AnimatedMeshGradient()
                    .opacity(0.5)
            }
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let glassBackground = Color(nsColor: .windowBackgroundColor).opacity(0.8)
    static let glassBorder = Color.white.opacity(0.2)

    // MARK: - 2025 Futuristic Color Palette
    // Inspired by cyberpunk aesthetics, glassmorphism, and modern tech UI trends

    // Primary Action - Electric Violet (tech innovation, futuristic)
    static let cleanPurple = Color(hue: 0.75, saturation: 0.85, brightness: 0.95)  // #A855F7 Electric Violet

    // Success - Neon Lime (cyberpunk energy, completion)
    static let cleanGreen = Color(hue: 0.38, saturation: 0.90, brightness: 0.95)   // #84CC16 Neon Lime

    // Info/Memory - Electric Cyan (tech, data, cool)
    static let cleanBlue = Color(hue: 0.52, saturation: 0.85, brightness: 0.98)    // #06B6D4 Electric Cyan

    // Warning - Amber Glow (warm, attention)
    static let cleanOrange = Color(hue: 0.09, saturation: 0.85, brightness: 0.98)  // #F59E0B Amber Glow

    // Danger - Hot Pink/Magenta (modern, striking)
    static let cleanRed = Color(hue: 0.93, saturation: 0.80, brightness: 0.95)     // #EC4899 Hot Pink

    // MARK: - Extended Palette

    // Accent gradients for depth
    static let neonViolet = Color(hue: 0.78, saturation: 0.90, brightness: 0.90)   // #8B5CF6 Deep Violet
    static let electricBlue = Color(hue: 0.58, saturation: 0.90, brightness: 0.95) // #3B82F6 Electric Blue
    static let mintCyan = Color(hue: 0.47, saturation: 0.70, brightness: 0.90)     // #2DD4BF Mint Cyan
    static let softPink = Color(hue: 0.90, saturation: 0.50, brightness: 0.95)     // #F472B6 Soft Pink
    static let neonYellow = Color(hue: 0.15, saturation: 0.85, brightness: 1.0)    // #FACC15 Neon Yellow

    // Neutral tones with subtle color tints
    static let slate50 = Color(hue: 0.62, saturation: 0.05, brightness: 0.98)      // Near white with blue tint
    static let slate400 = Color(hue: 0.62, saturation: 0.10, brightness: 0.60)     // Medium gray-blue
    static let slate800 = Color(hue: 0.62, saturation: 0.15, brightness: 0.20)     // Dark slate
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.2),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
