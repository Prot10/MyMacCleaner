import SwiftUI

// MARK: - App Theme

enum Theme {
    // MARK: - Colors (Apple Music Dark Style)

    enum Colors {
        // Primary colors
        static let accent = Color.blue
        static let accentGradient = LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        // Background colors
        static let background = Color(nsColor: .windowBackgroundColor)
        static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
        static let tertiaryBackground = Color(nsColor: .underPageBackgroundColor)

        // Surface colors (for cards)
        static let surfaceLight = Color.white.opacity(0.05)
        static let surfaceMedium = Color.white.opacity(0.08)
        static let surfaceHover = Color.white.opacity(0.12)

        // Text colors
        static let textPrimary = Color(nsColor: .labelColor)
        static let textSecondary = Color(nsColor: .secondaryLabelColor)
        static let textTertiary = Color(nsColor: .tertiaryLabelColor)

        // Semantic colors
        static let success = Color.green
        static let warning = Color.yellow
        static let error = Color.red
        static let info = Color.blue

        // Section colors (8 distinct colors)
        static let home = Color.blue                    // Blue
        static let storage = Color.orange               // Orange
        static let memory = Color.purple                // Purple
        static let apps = Color.green                   // Green
        static let startup = Color.yellow               // Yellow
        static let ports = Color.cyan                   // Cyan / Light Blue
        static let health = Color.red                   // Red
        static let permissions = Color.indigo           // Indigo
        static let orphans = Color.pink                 // Pink
        static let duplicates = Color.teal              // Teal
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.bold()
        static let title2 = Font.title2.bold()
        static let title3 = Font.title3.bold()
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
        static let caption2 = Font.caption2

        // Monospace for numbers/code
        static let mono = Font.system(.body, design: .monospaced)
        static let monoSmall = Font.system(.caption, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 40
        static let xl: CGFloat = 48
        static let xxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Control Sizes (Standardized UI Controls)

    enum ControlSize {
        /// Standard toolbar control height (matches macOS native .regular)
        static let toolbarHeight: CGFloat = 28

        /// Search field max width for consistency across views
        static let searchFieldMaxWidth: CGFloat = 300

        /// Horizontal padding for glass controls
        static let horizontalPadding: CGFloat = 12

        /// Vertical padding for glass controls
        static let verticalPadding: CGFloat = 6

        /// Standard font for controls
        static let controlFont: Font = .system(size: 13, weight: .medium)

        /// Icon size in controls
        static let controlIconSize: CGFloat = 12

        /// Corner radius for control backgrounds
        static let controlRadius: CGFloat = 8

        /// Spacing between controls in a filter bar
        static let controlSpacing: CGFloat = 8
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 4, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, y: 8)
    }

    // MARK: - Animation

    enum Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let springSmooth = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
    }

    // MARK: - Thresholds & Constants

    enum Thresholds {
        /// Minimum file size to include in scans (1 KB)
        static let minimumFileSize: Int64 = 1024

        /// Disk space thresholds for health warnings
        enum DiskSpace {
            /// Below this is critical (20 GB)
            static let criticalFreeSpace: Int64 = 20 * 1024 * 1024 * 1024
            /// Below this is warning (50 GB)
            static let warningFreeSpace: Int64 = 50 * 1024 * 1024 * 1024
        }

        /// Startup items thresholds for health score
        enum StartupItems {
            /// Above this is warning
            static let warningCount = 10
            /// Above this is critical
            static let criticalCount = 20
        }

        /// Memory usage thresholds (percentage)
        enum Memory {
            /// Above this is warning (80%)
            static let warningUsage: Double = 0.80
            /// Above this is critical (90%)
            static let criticalUsage: Double = 0.90
        }
    }

    // MARK: - Timing Constants

    enum Timing {
        /// Short delay for visual feedback (50ms)
        static let visualFeedback: UInt64 = 50_000_000
        /// Delay for progress display (80ms)
        static let progressStep: UInt64 = 80_000_000
        /// Medium delay (200ms)
        static let shortPause: UInt64 = 200_000_000
        /// Delay to show completion (300ms)
        static let completionDisplay: UInt64 = 300_000_000
        /// Auto-dismiss toast (3s)
        static let toastDuration: UInt64 = 3_000_000_000
        /// Clear results delay (5s)
        static let clearResultsDelay: UInt64 = 5_000_000_000
        /// Process refresh interval (seconds)
        static let processRefreshInterval: TimeInterval = 2.0
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions

extension View {
    func themeShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: 0, y: style.y)
    }
}

// MARK: - Color Extensions

extension Color {
    static let theme = Theme.Colors.self
}

// MARK: - Gradient Presets

extension LinearGradient {
    static let accentGradient = Theme.Colors.accentGradient

    static let glassGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let shimmerGradient = LinearGradient(
        colors: [
            Color.clear,
            Color.white.opacity(0.1),
            Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
