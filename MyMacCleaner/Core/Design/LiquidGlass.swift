import SwiftUI

// MARK: - Liquid Glass View Modifiers

extension View {
    /// Applies a glass card effect with material background
    func glassCard(cornerRadius: CGFloat = Theme.CornerRadius.large) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    /// Applies a prominent glass effect for important elements
    func glassCardProminent(cornerRadius: CGFloat = Theme.CornerRadius.large) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    /// Applies a subtle glass effect for secondary elements
    func glassCardSubtle(cornerRadius: CGFloat = Theme.CornerRadius.medium) -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Applies a pill-shaped glass effect (for buttons, tags)
    func glassPill() -> some View {
        self
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
    }

    /// Applies hover effect with scale and glow
    func hoverEffect(isHovered: Bool, scale: CGFloat = 1.02) -> some View {
        self
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(Theme.Animation.spring, value: isHovered)
    }

    /// Applies press effect
    func pressEffect(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fast, value: isPressed)
    }
}

// MARK: - Glass Card Component

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    @State private var isHovered = false

    init(
        cornerRadius: CGFloat = Theme.CornerRadius.large,
        padding: CGFloat = Theme.Spacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .glassCard(cornerRadius: cornerRadius)
            .hoverEffect(isHovered: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                Group {
                    if isProminent {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(.blue.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .foregroundStyle(isProminent ? .white : .primary)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(Theme.Animation.fast, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { GlassButtonStyle() }
    static var glassProminent: GlassButtonStyle { GlassButtonStyle(isProminent: true) }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (phase * geometry.size.width * 2))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Glow Effect

struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                content
                    .blur(radius: radius)
                    .opacity(0.5)
            )
    }
}

extension View {
    func glow(color: Color = .blue, radius: CGFloat = 10) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

// MARK: - Animated Border

struct AnimatedBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat

    @State private var rotation: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AngularGradient(
                            colors: [.blue, .purple, .pink, .blue],
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: lineWidth
                    )
                    .opacity(0.5)
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

extension View {
    func animatedBorder(cornerRadius: CGFloat = Theme.CornerRadius.large, lineWidth: CGFloat = 2) -> some View {
        modifier(AnimatedBorderModifier(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Glass Card")
            .padding()
            .glassCard()

        Text("Prominent Glass")
            .padding()
            .glassCardProminent()

        Text("Glass Pill")
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassPill()

        Button("Glass Button") {}
            .buttonStyle(.glass)

        Button("Prominent Button") {}
            .buttonStyle(.glassProminent)

        GlassCard {
            Text("GlassCard Component")
        }
    }
    .padding()
    .frame(width: 400, height: 400)
    .background(Color.black)
}
