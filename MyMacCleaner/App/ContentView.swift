import SwiftUI

struct ContentView: View {
    @State private var selectedSection: NavigationSection = .home
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selection: $selectedSection)
        } detail: {
            DetailView(section: selectedSection)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 900, minHeight: 600)
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
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: NavigationSection

    var body: some View {
        List(NavigationSection.allCases, selection: $selection) { section in
            NavigationLink(value: section) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.rawValue)
                            .font(.body)
                        Text(section.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: section.icon)
                        .foregroundStyle(section == .home ? .blue : .secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 220, ideal: 250, max: 300)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("System Healthy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Detail View

struct DetailView: View {
    let section: NavigationSection

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Content
            switch section {
            case .home:
                HomeView()
            case .diskCleaner:
                ComingSoonView(title: "Disk Cleaner", icon: "internaldrive.fill")
            case .performance:
                ComingSoonView(title: "Performance", icon: "gauge.with.needle.fill")
            case .applications:
                ComingSoonView(title: "Applications", icon: "square.grid.2x2.fill")
            case .portManagement:
                ComingSoonView(title: "Port Management", icon: "network")
            case .systemHealth:
                ComingSoonView(title: "System Health", icon: "heart.text.square.fill")
            }
        }
    }
}

// MARK: - Coming Soon Placeholder

struct ComingSoonView: View {
    let title: String
    let icon: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.largeTitle.bold())

                Text("Coming Soon")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Text("This feature is under development")
                .font(.body)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    ContentView()
}
