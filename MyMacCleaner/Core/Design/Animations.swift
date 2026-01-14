import SwiftUI

// MARK: - Page Transition

struct PageTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 20)
            .animation(Theme.Animation.springSmooth, value: isActive)
    }
}

extension View {
    func pageTransition(isActive: Bool = true) -> some View {
        modifier(PageTransition(isActive: isActive))
    }
}

// MARK: - Slide Transition

enum SlideDirection {
    case leading, trailing, top, bottom

    var offset: CGSize {
        switch self {
        case .leading: return CGSize(width: -50, height: 0)
        case .trailing: return CGSize(width: 50, height: 0)
        case .top: return CGSize(width: 0, height: -50)
        case .bottom: return CGSize(width: 0, height: 50)
        }
    }
}

struct SlideTransition: ViewModifier {
    let isActive: Bool
    let direction: SlideDirection

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(isActive ? .zero : direction.offset)
            .animation(Theme.Animation.spring, value: isActive)
    }
}

extension View {
    func slideTransition(isActive: Bool, from direction: SlideDirection = .trailing) -> some View {
        modifier(SlideTransition(isActive: isActive, direction: direction))
    }
}

// MARK: - Scale Fade Transition

struct ScaleFadeTransition: ViewModifier {
    let isActive: Bool
    let scale: CGFloat

    init(isActive: Bool, scale: CGFloat = 0.9) {
        self.isActive = isActive
        self.scale = scale
    }

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : scale)
            .animation(Theme.Animation.spring, value: isActive)
    }
}

extension View {
    func scaleFadeTransition(isActive: Bool, scale: CGFloat = 0.9) -> some View {
        modifier(ScaleFadeTransition(isActive: isActive, scale: scale))
    }
}

// MARK: - Staggered Animation

struct StaggeredAnimation: ViewModifier {
    let index: Int
    let isActive: Bool
    let baseDelay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 20)
            .animation(
                Theme.Animation.spring.delay(Double(index) * baseDelay),
                value: isActive
            )
    }
}

extension View {
    func staggeredAnimation(index: Int, isActive: Bool, baseDelay: Double = 0.05) -> some View {
        modifier(StaggeredAnimation(index: index, isActive: isActive, baseDelay: baseDelay))
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulseAnimation() -> some View {
        modifier(PulseAnimation())
    }
}

// MARK: - Breathing Animation (for scan button)

struct BreathingAnimation: ViewModifier {
    @State private var isBreathing = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double

    init(minScale: CGFloat = 0.98, maxScale: CGFloat = 1.02, duration: Double = 2.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBreathing ? maxScale : minScale)
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}

extension View {
    func breathingAnimation(minScale: CGFloat = 0.98, maxScale: CGFloat = 1.02, duration: Double = 2.0) -> some View {
        modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
}

// MARK: - Rotation Animation

struct RotationAnimation: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .animation(
                .linear(duration: duration).repeatForever(autoreverses: false),
                value: rotation
            )
            .onAppear {
                rotation = 360
            }
    }
}

extension View {
    func continuousRotation(duration: Double = 2.0) -> some View {
        modifier(RotationAnimation(duration: duration))
    }
}

// MARK: - Loading Dots Animation

struct LoadingDotsView: View {
    @State private var activeIndex = 0
    let dotCount: Int
    let dotSize: CGFloat
    let color: Color

    init(dotCount: Int = 3, dotSize: CGFloat = 8, color: Color = .blue) {
        self.dotCount = dotCount
        self.dotSize = dotSize
        self.color = color
    }

    var body: some View {
        HStack(spacing: dotSize / 2) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(activeIndex == index ? 1.3 : 1.0)
                    .opacity(activeIndex == index ? 1.0 : 0.5)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(Theme.Animation.spring) {
                    activeIndex = (activeIndex + 1) % dotCount
                }
            }
        }
    }
}

// MARK: - Progress Ring Animation

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color

    @State private var animatedProgress: Double = 0

    init(progress: Double, lineWidth: CGFloat = 8, color: Color = .blue) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.color = color
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(Theme.Animation.slow) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(Theme.Animation.normal) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Confetti Animation (for completion)

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var position: CGPoint
    var rotation: Double
    var color: Color
    var scale: CGFloat
}

struct ConfettiView: View {
    @State private var pieces: [ConfettiPiece] = []
    @State private var isAnimating = false

    let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .yellow]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(piece.scale)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                }
            }
            .onAppear {
                createPieces(in: geometry.size)
                animate()
            }
        }
        .allowsHitTesting(false)
    }

    private func createPieces(in size: CGSize) {
        pieces = (0..<50).map { _ in
            ConfettiPiece(
                position: CGPoint(x: size.width / 2, y: -20),
                rotation: Double.random(in: 0...360),
                color: colors.randomElement()!,
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
    }

    private func animate() {
        for i in pieces.indices {
            withAnimation(.easeOut(duration: Double.random(in: 1.5...3.0)).delay(Double.random(in: 0...0.5))) {
                pieces[i].position.y = 600
                pieces[i].position.x += CGFloat.random(in: -200...200)
                pieces[i].rotation += Double.random(in: 180...720)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        LoadingDotsView()

        ProgressRing(progress: 0.7)
            .frame(width: 60, height: 60)

        Text("Breathing")
            .padding()
            .background(.blue)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            .breathingAnimation()
    }
    .padding()
    .frame(width: 300, height: 400)
}
