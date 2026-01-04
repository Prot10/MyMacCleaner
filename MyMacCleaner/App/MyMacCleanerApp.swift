import SwiftUI

@main
struct MyMacCleanerApp: App {
    /// Shared app state that persists across section switches
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $launchAtLogin)
            Toggle("Show in menu bar", isOn: $showInMenuBar)
        }
        .padding()
    }
}

struct PermissionsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Permissions")
                .font(.headline)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Full Disk Access")
                Spacer()
                Button("Open Settings") {
                    openSystemPreferences()
                }
            }

            Text("Full Disk Access is required to scan system caches and logs.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private func openSystemPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!
        NSWorkspace.shared.open(url)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)

            Text("MyMacCleaner")
                .font(.title.bold())

            Text("Version 1.0.0")
                .foregroundStyle(.secondary)

            Text("A modern, open-source macOS system utility")
                .font(.caption)
                .foregroundStyle(.secondary)

            Link("View on GitHub", destination: URL(string: "https://github.com/yourusername/MyMacCleaner")!)
                .font(.caption)

            Spacer()
        }
        .padding()
    }
}
