import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            GlassSidebar()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
        .toastContainer(appState.toastManager)
        .task {
            // Start background preloading when app launches
            await appState.startBackgroundPreloading()
        }
    }
}

// MARK: - Glass Sidebar

struct GlassSidebar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // App Title with futuristic gradient
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cleanPurple, Color.electricBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("MyMacCleaner")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, 16)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach([NavigationItem.dashboard, .cleaner, .uninstaller, .optimizer]) { item in
                    GlassSidebarItem(
                        title: item.rawValue,
                        icon: item.systemImage,
                        color: item.accentColor,
                        isSelected: state.selectedNavigation == item,
                        isLoading: !state.loadingState.state(for: item)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            state.selectedNavigation = item
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)

            Spacer()

            Divider()
                .padding(.horizontal, 16)

            // Settings
            GlassSidebarItem(
                title: "Settings",
                icon: "gearshape.fill",
                color: .gray,
                isSelected: state.selectedNavigation == .settings
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    state.selectedNavigation = .settings
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 200)
        .background {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.5)

                // Futuristic violet-cyan gradient overlay
                LinearGradient(
                    colors: [
                        Color.neonViolet.opacity(0.06),
                        Color.cleanPurple.opacity(0.04),
                        Color.electricBlue.opacity(0.03),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .toolbar(removing: .sidebarToggle)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
    }
}

// MARK: - Detail View

struct DetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.selectedNavigation {
            case .dashboard:
                // Show dashboard as soon as we have any data (progressive)
                if appState.loadingState.dashboard.data != nil {
                    DashboardView()
                } else {
                    DashboardSkeletonView()
                }
            case .cleaner:
                if appState.loadingState.cleaner.isLoaded {
                    CleanerView()
                } else {
                    CleanerSkeletonView()
                }
            case .uninstaller:
                if appState.loadingState.uninstaller.isLoaded {
                    UninstallerView()
                } else {
                    UninstallerSkeletonView()
                }
            case .optimizer:
                if appState.loadingState.optimizer.isLoaded {
                    OptimizerView()
                } else {
                    OptimizerSkeletonView()
                }
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassBackground()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
