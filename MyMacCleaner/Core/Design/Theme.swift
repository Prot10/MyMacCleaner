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
        // Standard semantic fonts
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

        // Sized fonts for specific UI needs
        static let size8 = Font.system(size: 8)
        static let size9 = Font.system(size: 9)
        static let size9Medium = Font.system(size: 9, weight: .medium)
        static let size9Bold = Font.system(size: 9, weight: .bold)
        static let size10 = Font.system(size: 10)
        static let size10Medium = Font.system(size: 10, weight: .medium)
        static let size10Semibold = Font.system(size: 10, weight: .semibold)
        static let size10Bold = Font.system(size: 10, weight: .bold)
        static let size11 = Font.system(size: 11)
        static let size11Medium = Font.system(size: 11, weight: .medium)
        static let size11Semibold = Font.system(size: 11, weight: .semibold)
        static let size12 = Font.system(size: 12)
        static let size12Medium = Font.system(size: 12, weight: .medium)
        static let size12Semibold = Font.system(size: 12, weight: .semibold)
        static let size12Bold = Font.system(size: 12, weight: .bold)
        static let size13 = Font.system(size: 13)
        static let size13Medium = Font.system(size: 13, weight: .medium)
        static let size13Semibold = Font.system(size: 13, weight: .semibold)
        static let size14 = Font.system(size: 14)
        static let size14Medium = Font.system(size: 14, weight: .medium)
        static let size14Semibold = Font.system(size: 14, weight: .semibold)
        static let size15 = Font.system(size: 15)
        static let size15Medium = Font.system(size: 15, weight: .medium)
        static let size15Semibold = Font.system(size: 15, weight: .semibold)
        static let size16 = Font.system(size: 16)
        static let size16Medium = Font.system(size: 16, weight: .medium)
        static let size16Semibold = Font.system(size: 16, weight: .semibold)
        static let size16Bold = Font.system(size: 16, weight: .bold)
        static let size18 = Font.system(size: 18)
        static let size18Medium = Font.system(size: 18, weight: .medium)
        static let size18Semibold = Font.system(size: 18, weight: .semibold)
        static let size18Bold = Font.system(size: 18, weight: .bold)
        static let size20 = Font.system(size: 20)
        static let size20Medium = Font.system(size: 20, weight: .medium)
        static let size20Semibold = Font.system(size: 20, weight: .semibold)
        static let size20Bold = Font.system(size: 20, weight: .bold)
        static let size22 = Font.system(size: 22)
        static let size22Semibold = Font.system(size: 22, weight: .semibold)
        static let size24Bold = Font.system(size: 24, weight: .bold)
        static let size24BoldRounded = Font.system(size: 24, weight: .bold, design: .rounded)
        static let size28Medium = Font.system(size: 28, weight: .medium)
        static let size28Semibold = Font.system(size: 28, weight: .semibold)
        static let size28Bold = Font.system(size: 28, weight: .bold)
        static let size32Medium = Font.system(size: 32, weight: .medium)
        static let size32Bold = Font.system(size: 32, weight: .bold)
        static let size36Bold = Font.system(size: 36, weight: .bold)
        static let size36BoldRounded = Font.system(size: 36, weight: .bold, design: .rounded)
        static let size44Medium = Font.system(size: 44, weight: .medium)
        static let size44BoldRounded = Font.system(size: 44, weight: .bold, design: .rounded)
        static let size48 = Font.system(size: 48)
        static let size48Bold = Font.system(size: 48, weight: .bold)

        // Monospace for numbers/code
        static let mono = Font.system(.body, design: .monospaced)
        static let monoSmall = Font.system(.caption, design: .monospaced)
        static let monoSize11 = Font.system(size: 11, design: .monospaced)
        static let monoSize12 = Font.system(size: 12, design: .monospaced)
        static let monoSize13 = Font.system(size: 13, design: .monospaced)
        static let monoSize14 = Font.system(size: 14, design: .monospaced)
        static let monoSize20Bold = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let monoSize24Bold = Font.system(size: 24, weight: .bold, design: .monospaced)
        static let monoSize28Bold = Font.system(size: 28, weight: .bold, design: .monospaced)
        static let monoSize32Bold = Font.system(size: 32, weight: .bold, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let tiny: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xxxs: CGFloat = 6
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let section: CGFloat = 28
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
        static let huge: CGFloat = 48
        static let massive: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let tiny: CGFloat = 4
        static let xs: CGFloat = 6
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
