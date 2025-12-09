import SwiftUI

// MARK: - Toast Manager

@Observable
final class ToastManager {
    var currentToast: ToastMessage?
    private var dismissTask: Task<Void, Never>?

    @MainActor
    func show(_ message: String, type: ToastType = .info, duration: Double = 3.0) {
        dismissTask?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = ToastMessage(message: message, type: type)
        }

        dismissTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.currentToast = nil
                }
            }
        }
    }

    @MainActor
    func showLoading(_ message: String) {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = ToastMessage(message: message, type: .loading)
        }
    }

    @MainActor
    func dismiss() {
        dismissTask?.cancel()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast Types

enum ToastType {
    case info
    case success
    case warning
    case error
    case loading

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .loading: return "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }

    var color: Color {
        switch self {
        case .info: return .cleanBlue
        case .success: return .cleanGreen
        case .warning: return .cleanOrange
        case .error: return .cleanRed
        case .loading: return .cleanPurple
        }
    }
}

struct ToastMessage: Equatable {
    let id = UUID()
    let message: String
    let type: ToastType

    static func == (lhs: ToastMessage, rhs: ToastMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: ToastMessage
    @State private var isRotating = false

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if toast.type == .loading {
                    Image(systemName: toast.type.icon)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .onAppear {
                            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                isRotating = true
                            }
                        }
                } else {
                    Image(systemName: toast.type.icon)
                }
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(toast.type.color)

            Text(toast.message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: 400)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            toast.type.color.opacity(0.4),
                            toast.type.color.opacity(0.1),
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

// MARK: - Toast Container Modifier

struct ToastContainerModifier: ViewModifier {
    @Bindable var toastManager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .padding(.bottom, 24)
                        .padding(.trailing, 24)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                }
            }
    }
}

extension View {
    func toastContainer(_ manager: ToastManager) -> some View {
        modifier(ToastContainerModifier(toastManager: manager))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ToastView(toast: ToastMessage(message: "Loading dashboard data...", type: .loading))
        ToastView(toast: ToastMessage(message: "Scan complete!", type: .success))
        ToastView(toast: ToastMessage(message: "Low disk space warning", type: .warning))
        ToastView(toast: ToastMessage(message: "Something went wrong", type: .error))
    }
    .padding()
    .frame(width: 500, height: 400)
    .liquidGlassBackground()
}
