import SwiftUI

// MARK: - Animation Constants

enum AppAnimation {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let springFast = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.4)

    /// Stagger delay for list items
    static func staggerDelay(index: Int, baseDelay: Double = 0.05) -> Double {
        Double(index) * baseDelay
    }
}

// MARK: - Appear Animation Modifier

struct AppearAnimationModifier: ViewModifier {
    let animation: Animation
    let delay: Double

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.9)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(animation.delay(delay)) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0, animation: Animation = AppAnimation.spring) -> some View {
        modifier(AppearAnimationModifier(animation: animation, delay: delay))
    }

    func staggeredAppear(index: Int, baseDelay: Double = 0.05) -> some View {
        appearAnimation(delay: AppAnimation.staggerDelay(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Slide In Animation

struct SlideInModifier: ViewModifier {
    enum Direction {
        case leading, trailing, top, bottom
    }

    let direction: Direction
    let delay: Double

    @State private var isVisible = false

    private var offset: CGSize {
        switch direction {
        case .leading: return CGSize(width: -50, height: 0)
        case .trailing: return CGSize(width: 50, height: 0)
        case .top: return CGSize(width: 0, height: -30)
        case .bottom: return CGSize(width: 0, height: 30)
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(isVisible ? .zero : offset)
            .onAppear {
                withAnimation(AppAnimation.spring.delay(delay)) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func slideIn(from direction: SlideInModifier.Direction = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(direction: direction, delay: delay))
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.95) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(AppAnimation.springFast, value: configuration.isPressed)
    }
}

// MARK: - Bounce Button Style

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Glow Pulse Animation

struct GlowPulseModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(
                color: isActive ? color.opacity(isPulsing ? 0.6 : 0.3) : .clear,
                radius: isPulsing ? 20 : 10,
                x: 0,
                y: isPulsing ? 8 : 4
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    isPulsing = false
                }
            }
    }
}

extension View {
    func glowPulse(color: Color, isActive: Bool = true) -> some View {
        modifier(GlowPulseModifier(color: color, isActive: isActive))
    }
}

// MARK: - Chart Animation Modifier

struct ChartAnimationModifier: ViewModifier {
    @State private var animationProgress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geo in
                    Rectangle()
                        .frame(width: geo.size.width * animationProgress)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            )
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animationProgress = 1
                }
            }
            .onDisappear {
                animationProgress = 0
            }
    }
}

extension View {
    func chartAppearAnimation() -> some View {
        modifier(ChartAnimationModifier())
    }
}

// MARK: - Progress Ring Animation

struct AnimatedProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let gradient: LinearGradient

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Counting Number Animation

struct AnimatedNumber: View {
    let value: Double
    let format: String
    let font: Font
    let color: Color

    @State private var animatedValue: Double = 0

    var body: some View {
        Text(String(format: format, animatedValue))
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    animatedValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedValue = newValue
                }
            }
    }
}

// MARK: - Card Flip Animation

struct CardAppearModifier: ViewModifier {
    let index: Int

    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .rotation3DEffect(
                .degrees(isVisible ? 0 : -15),
                axis: (x: 1, y: 0, z: 0),
                perspective: 0.3
            )
            .onAppear {
                withAnimation(AppAnimation.springBouncy.delay(Double(index) * 0.08)) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func cardAppear(index: Int = 0) -> some View {
        modifier(CardAppearModifier(index: index))
    }
}

// MARK: - Hover Scale Effect

struct HoverScaleModifier: ViewModifier {
    let scale: CGFloat
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1)
            .animation(AppAnimation.springFast, value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

extension View {
    func hoverScale(_ scale: CGFloat = 1.02) -> some View {
        modifier(HoverScaleModifier(scale: scale))
    }
}

// MARK: - Animated Bar

struct AnimatedBar: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let height: CGFloat

    @State private var animatedWidth: Double = 0

    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Color.secondary.opacity(0.15))

                // Fill
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: geo.size.width * animatedWidth)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedWidth = percentage
            }
        }
        .onChange(of: value) { _, _ in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedWidth = percentage
            }
        }
    }
}

// MARK: - Page Transition

struct PageTransitionModifier: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .onAppear {
                withAnimation(AppAnimation.spring) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
    }
}

extension View {
    func pageTransition() -> some View {
        modifier(PageTransitionModifier())
    }
}
