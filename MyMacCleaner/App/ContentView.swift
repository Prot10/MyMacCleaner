import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSection: NavigationSection = .home
    @State private var isFullScreen = false

    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selection: $selectedSection)
        } detail: {
            // Detail content
            DetailContentView(
                section: selectedSection,
                appState: appState,
                onNavigate: { sectionName in
                    if let section = NavigationSection.allCases.first(where: {
                        $0.rawValue.lowercased().replacingOccurrences(of: " ", with: "") == sectionName.lowercased()
                    }) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSection = section
                        }
                    }
                },
                isFullScreen: isFullScreen
            )
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1000, minHeight: 650)
        .toolbar(removing: .sidebarToggle)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullScreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullScreen = false
        }
    }
}

// MARK: - Navigation Section

enum NavigationSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case diskCleaner = "Disk Cleaner"
    case performance = "Performance"
    case applications = "Applications"
    case startupItems = "Startup Items"
    case portManagement = "Port Management"
    case systemHealth = "System Health"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .diskCleaner: return "internaldrive.fill"
        case .performance: return "gauge.with.needle.fill"
        case .applications: return "square.grid.2x2.fill"
        case .startupItems: return "power.circle.fill"
        case .portManagement: return "network"
        case .systemHealth: return "heart.text.square.fill"
        }
    }

    var description: String {
        switch self {
        case .home: return "Smart scan and overview"
        case .diskCleaner: return "Clean junk files"
        case .performance: return "Optimize your Mac"
        case .applications: return "Manage installed apps"
        case .startupItems: return "Control startup programs"
        case .portManagement: return "View active ports"
        case .systemHealth: return "Monitor system health"
        }
    }

    var color: Color {
        switch self {
        case .home: return Theme.Colors.home              // Blue
        case .diskCleaner: return Theme.Colors.storage    // Orange
        case .performance: return Theme.Colors.memory     // Purple
        case .applications: return Theme.Colors.apps      // Green
        case .startupItems: return Theme.Colors.startup   // Yellow
        case .portManagement: return Theme.Colors.ports   // Cyan
        case .systemHealth: return Theme.Colors.health    // Red
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selection: NavigationSection
    @State private var hoveredSection: NavigationSection?

    var body: some View {
        VStack(spacing: 0) {
            // App header
            SidebarHeader()
                .padding(.top, 8)
                .padding(.bottom, 8)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Navigation items
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(NavigationSection.allCases) { section in
                        SidebarRow(
                            section: section,
                            isSelected: selection == section,
                            isHovered: hoveredSection == section
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selection = section
                            }
                        }
                        .onHover { isHovered in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredSection = isHovered ? section : nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }

            Spacer()

            // Bottom status
            SystemStatusBadge()
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 260, max: 300)
    }
}

// MARK: - Sidebar Row

struct SidebarRow: View {
    let section: NavigationSection
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? section.color.opacity(0.2) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
                    .frame(width: 36, height: 36)

                Image(systemName: section.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? section.color : .secondary)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(section.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Circle()
                    .fill(section.color)
                    .frame(width: 6, height: 6)
                    .shadow(color: section.color.opacity(0.5), radius: 4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(section.color.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(section.color.opacity(0.2), lineWidth: 0.5)
                    }
            } else if isHovered {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            }
        }
        .contentShape(Rectangle())
        .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
    }
}

// MARK: - Sidebar Header

struct SidebarHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            Image("SidebarLogo")
                .resizable()
                .renderingMode(.original)
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)

            Text("MyMacCleaner")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - System Status Badge

struct SystemStatusBadge: View {
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.5), radius: 4)

                Text("System Healthy")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
        }
    }
}

// MARK: - Detail Content View

struct DetailContentView: View {
    let section: NavigationSection
    let appState: AppState
    let onNavigate: (String) -> Void
    let isFullScreen: Bool

    var body: some View {
        ZStack {
            // Dynamic background gradient
            backgroundGradient
                .ignoresSafeArea()

            // Content with top padding in fullscreen
            contentView
                .padding(.top, isFullScreen ? 28 : 0)
        }
        .ignoresSafeArea(edges: .top)
    }

    private var backgroundGradient: some View {
        ZStack {
            // Base gradient with section color
            LinearGradient(
                colors: [
                    section.color.opacity(0.15),
                    section.color.opacity(0.08),
                    section.color.opacity(0.03),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Secondary radial for depth
            RadialGradient(
                colors: [
                    section.color.opacity(0.12),
                    section.color.opacity(0.05),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 50,
                endRadius: 500
            )

            // Accent glow at bottom
            RadialGradient(
                colors: [
                    section.color.opacity(0.08),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 100,
                endRadius: 400
            )
        }
        .animation(.easeInOut(duration: 0.4), value: section)
    }

    @ViewBuilder
    private var contentView: some View {
        switch section {
        case .home:
            HomeView(viewModel: appState.homeViewModel)
                .onAppear {
                    appState.homeViewModel.onNavigateToSection = onNavigate
                }
        case .diskCleaner:
            DiskCleanerView(
                viewModel: appState.diskCleanerViewModel,
                spaceLensViewModel: appState.spaceLensViewModel
            )
        case .performance:
            PerformanceView(viewModel: appState.performanceViewModel)
        case .applications:
            ApplicationsView(viewModel: appState.applicationsViewModel)
        case .startupItems:
            StartupItemsView(viewModel: appState.startupItemsViewModel)
        case .portManagement:
            PortManagementView(viewModel: appState.portManagementViewModel)
        case .systemHealth:
            SystemHealthView(viewModel: appState.systemHealthViewModel)
        }
    }
}

// MARK: - Coming Soon Placeholder

struct ComingSoonView: View {
    let section: NavigationSection

    @State private var isAnimating = false
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 32) {
            // Icon with animated background
            ZStack {
                // Outer glow
                Circle()
                    .fill(section.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)

                // Icon container
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)

                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [section.color.opacity(0.5), section.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: section.icon)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(section.color.gradient)
                }
                .scaleEffect(isHovered ? 1.05 : 1.0)
            }
            .onHover { hovering in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isHovered = hovering
                }
            }

            // Text content
            VStack(spacing: 12) {
                Text(section.rawValue)
                    .font(.largeTitle.bold())

                Text("Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("This feature is under development")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }

            // Status badge
            HStack(spacing: 8) {
                Image(systemName: "hammer.fill")
                    .font(.caption)

                Text("In Development")
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassPill()
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
