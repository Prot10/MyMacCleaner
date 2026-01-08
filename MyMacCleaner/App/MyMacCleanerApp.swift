import SwiftUI

@main
struct MyMacCleanerApp: App {
    /// Shared app state that persists across section switches
    @StateObject private var appState = AppState()

    /// Update manager for Sparkle auto-updates
    @State private var updateManager = UpdateManager()

    /// Menu bar controller
    @StateObject private var menuBarController = MenuBarController.shared

    /// Menu bar visibility setting
    @AppStorage("showInMenuBar") private var showInMenuBar = false

    init() {
        // Load saved display mode
        MenuBarController.shared.loadSavedDisplayMode()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(LocalizationManager.shared)
                .environment(updateManager)
                .onAppear {
                    // Setup menu bar if enabled
                    if showInMenuBar {
                        menuBarController.setup()
                    }
                }
                .onChange(of: showInMenuBar) { _, newValue in
                    if newValue {
                        menuBarController.setup()
                    } else {
                        menuBarController.teardown()
                    }
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1100, height: 700)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)
                .keyboardShortcut("U", modifiers: [.command])
            }
        }

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(LocalizationManager.shared)
                .environment(updateManager)
                .environmentObject(menuBarController)
        }
        #endif
    }
}

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(String(localized: "settings.general"), systemImage: "gear")
                }

            LanguageSettingsView()
                .tabItem {
                    Label(String(localized: "settings.language"), systemImage: "globe")
                }

            UpdateSettingsView()
                .tabItem {
                    Label(String(localized: "settings.updates"), systemImage: "arrow.triangle.2.circlepath")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label(String(localized: "settings.permissions"), systemImage: "lock.shield")
                }

            AboutSettingsView()
                .tabItem {
                    Label(String(localized: "settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 320)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @EnvironmentObject var menuBarController: MenuBarController

    var body: some View {
        Form {
            Toggle(String(localized: "settings.launchAtLogin"), isOn: $launchAtLogin)

            Section {
                Toggle(String(localized: "settings.showInMenuBar"), isOn: $showInMenuBar)

                if showInMenuBar {
                    Picker(String(localized: "settings.menuBarDisplay"), selection: Binding(
                        get: { menuBarController.displayMode },
                        set: { menuBarController.setDisplayMode($0) }
                    )) {
                        ForEach(MenuBarController.DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(String(localized: "settings.menuBarDescription"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}

struct LanguageSettingsView: View {
    @Environment(LocalizationManager.self) var localization

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.language"))
                .font(.headline)

            Picker(String(localized: "settings.language"), selection: Binding(
                get: { localization.currentLanguage },
                set: { localization.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Text(String(localized: "settings.languageNote"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct UpdateSettingsView: View {
    @Environment(UpdateManager.self) var updateManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.updates"))
                .font(.headline)

            Toggle(String(localized: "settings.autoCheckUpdates"), isOn: Binding(
                get: { updateManager.automaticChecksEnabled },
                set: { updateManager.automaticChecksEnabled = $0 }
            ))

            HStack {
                Button(String(localized: "settings.checkNow")) {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)

                Spacer()

                if let lastCheck = updateManager.lastUpdateCheck {
                    Text(String(localized: "settings.lastChecked \(lastCheck.formatted())"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(String(localized: "settings.updatesDescription"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct PermissionsSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "settings.permissions"))
                .font(.headline)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(String(localized: "settings.fullDiskAccess"))
                Spacer()
                Button(String(localized: "settings.openSettings")) {
                    openSystemPreferences()
                }
            }

            Text(String(localized: "settings.fdaDescription"))
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
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.blue.gradient)

            Text("MyMacCleaner")
                .font(.title.bold())

            Text("Version \(appVersion)")
                .foregroundStyle(.secondary)

            Text(String(localized: "settings.aboutDescription"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Link(String(localized: "settings.viewOnGitHub"), destination: URL(string: "https://github.com/Prot10/MyMacCleaner")!)
                .font(.caption)

            Spacer()
        }
        .padding()
    }
}
