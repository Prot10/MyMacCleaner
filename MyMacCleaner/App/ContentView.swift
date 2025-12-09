import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            DetailView()
        }
        .navigationSplitViewStyle(.balanced)
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        List(selection: $state.selectedNavigation) {
            Section {
                ForEach([NavigationItem.dashboard, .cleaner, .uninstaller, .optimizer]) { item in
                    NavigationLink(value: item) {
                        Label {
                            Text(item.rawValue)
                                .font(.system(.body, design: .rounded))
                        } icon: {
                            Image(systemName: item.systemImage)
                                .foregroundStyle(item.accentColor)
                        }
                    }
                }
            }

            Section {
                NavigationLink(value: NavigationItem.settings) {
                    Label {
                        Text("Settings")
                            .font(.system(.body, design: .rounded))
                    } icon: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .toolbar(removing: .sidebarToggle)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
    }
}

// MARK: - Detail View

struct DetailView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.selectedNavigation {
            case .dashboard:
                DashboardView()
            case .cleaner:
                CleanerView()
            case .uninstaller:
                UninstallerView()
            case .optimizer:
                OptimizerView()
            case .settings:
                SettingsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
