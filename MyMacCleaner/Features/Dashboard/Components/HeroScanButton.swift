import SwiftUI

/// Large animated scan button - the centerpiece of the CleanMyMac-style UI
struct HeroScanButton: View {
    let isScanning: Bool
    let progress: Double
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var pulseAnimation = false

    private let buttonSize: CGFloat = 150

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: .accentColor.opacity(0.3), radius: isHovering ? 20 : 10)

                // Pulse animation ring (when idle)
                if !isScanning {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: buttonSize + 20, height: buttonSize + 20)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0 : 0.5)
                }

                // Progress ring (when scanning)
                if isScanning {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: buttonSize - 16, height: buttonSize - 16)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: buttonSize - 16, height: buttonSize - 16)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut, value: progress)
                }

                // Icon and text
                VStack(spacing: 8) {
                    if isScanning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.2)
                            .tint(.white)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    Text(isScanning ? "Scanning..." : "Smart Scan")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onAppear {
            startPulseAnimation()
        }
        .disabled(isScanning)
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor,
                Color.accentColor.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: false)
        ) {
            pulseAnimation = true
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        HeroScanButton(isScanning: false, progress: 0) { }
        HeroScanButton(isScanning: true, progress: 0.65) { }
    }
    .padding()
    .frame(width: 400, height: 500)
    .background(Color(nsColor: .windowBackgroundColor))
}
