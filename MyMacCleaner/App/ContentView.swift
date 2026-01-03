import SwiftUI

struct ContentView: View {
    @State private var selectedSection: NavigationSection = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var isDetailVisible = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedSection)
        } detail: {
            DetailView(section: selectedSection)
                .id(selectedSection) // Force view refresh on selection change
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            withAnimation(Theme.Animation.springSmooth) {
                isDetailVisible = true
            }
        }
    }
}

// MARK: - Navigation Section

enum NavigationSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case diskCleaner = "Disk Cleaner"
    case performance = "Performance"
    case applications = "Applications"
    case portManagement = "Port Management"
    case systemHealth = "System Health"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .diskCleaner: return "internaldrive.fill"
        case .performance: return "gauge.with.needle.fill"
        case .applications: return "square.grid.2x2.fill"
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
        case .portManagement: return "View active ports"
        case .systemHealth: return "Monitor system health"
        }
    }

    var color: Color {
        switch self {
        case .home: return Theme.Colors.accent
        case .diskCleaner: return Theme.Colors.storage
        case .performance: return Theme.Colors.memory
        case .applications: return Theme.Colors.apps
        case .portManagement: return Theme.Colors.ports
        case .systemHealth: return Theme.Colors.health
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: NavigationSection
    @State private var hoveredSection: NavigationSection?

    var body: some View {
        List(NavigationSection.allCases, selection: $selection) { section in
            NavigationLink(value: section) {
                SidebarRow(
                    section: section,
                    isSelected: selection == section,
                    isHovered: hoveredSection == section
                )
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .onHover { isHovered in
                withAnimation(Theme.Animation.fast) {
                    hoveredSection = isHovered ? section : nil
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        .safeAreaInset(edge: .top) {
            // App header
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue.gradient)

                Text("MyMacCleaner")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .safeAreaInset(edge: .bottom) {
            SystemStatusBadge()
        }
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
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? section.color.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)

                Image(systemName: section.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? section.color : .secondary)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(section.rawValue)
                    .font(.body)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Text(section.description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered && !isSelected ? Color.white.opacity(0.05) : Color.clear)
        )
        .contentShape(Rectangle())
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

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isHovered ? Color.white.opacity(0.03) : Color.clear)
            .onHover { hovering in
                withAnimation(Theme.Animation.fast) {
                    isHovered = hovering
                }
            }
        }
    }
}

// MARK: - Detail View

struct DetailView: View {
    let section: NavigationSection
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()

            // Content
            Group {
                switch section {
                case .home:
                    HomeView()
                case .diskCleaner:
                    ComingSoonView(section: section)
                case .performance:
                    ComingSoonView(section: section)
                case .applications:
                    ComingSoonView(section: section)
                case .portManagement:
                    ComingSoonView(section: section)
                case .systemHealth:
                    ComingSoonView(section: section)
                }
            }
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
        }
        .onAppear {
            withAnimation(Theme.Animation.springSmooth.delay(0.1)) {
                isVisible = true
            }
        }
        .onDisappear {
            isVisible = false
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
                withAnimation(Theme.Animation.spring) {
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
}
