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
    @AppStorage("showInMenuBar") private var showInMenuBar = true

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
    @Environment(LocalizationManager.self) var localization

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label(L("settings.general"), systemImage: "gear")
                }

            LanguageSettingsView()
                .tabItem {
                    Label(L("settings.language"), systemImage: "globe")
                }

            UpdateSettingsView()
                .tabItem {
                    Label(L("settings.updates"), systemImage: "arrow.triangle.2.circlepath")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label(L("settings.permissions"), systemImage: "lock.shield")
                }

            AboutSettingsView()
                .tabItem {
                    Label(L("settings.about"), systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 320)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @EnvironmentObject var menuBarController: MenuBarController
    @Environment(LocalizationManager.self) var localization

    var body: some View {
        Form {
            Toggle(L("settings.launchAtLogin"), isOn: $launchAtLogin)

            Section {
                Toggle(L("settings.showInMenuBar"), isOn: $showInMenuBar)

                if showInMenuBar {
                    Picker(L("settings.menuBarDisplay"), selection: Binding(
                        get: { menuBarController.displayMode },
                        set: { menuBarController.setDisplayMode($0) }
                    )) {
                        ForEach(MenuBarController.DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(L("settings.menuBarDescription"))
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
            Text(L("settings.language"))
                .font(.headline)

            Picker(L("settings.language"), selection: Binding(
                get: { localization.currentLanguage },
                set: { localization.setLanguage($0) }
            )) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()

            Text(L("settings.languageNote"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct UpdateSettingsView: View {
    @Environment(UpdateManager.self) var updateManager
    @Environment(LocalizationManager.self) var localization

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("settings.updates"))
                .font(.headline)

            Toggle(L("settings.autoCheckUpdates"), isOn: Binding(
                get: { updateManager.automaticChecksEnabled },
                set: { updateManager.automaticChecksEnabled = $0 }
            ))

            HStack {
                Button(L("settings.checkNow")) {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.canCheckForUpdates)

                Spacer()

                if let lastCheck = updateManager.lastUpdateCheck {
                    Text(LFormat("settings.lastChecked %@", lastCheck.formatted()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(L("settings.updatesDescription"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

struct PermissionsSettingsView: View {
    @Environment(LocalizationManager.self) var localization

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("settings.permissions"))
                .font(.headline)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(L("settings.fullDiskAccess"))
                Spacer()
                Button(L("settings.openSettings")) {
                    openSystemPreferences()
                }
            }

            Text(L("settings.fdaDescription"))
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
    @Environment(LocalizationManager.self) var localization

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

            Text(L("settings.aboutDescription"))
                .font(.caption)
                .foregroundStyle(.secondary)

            Link(L("settings.viewOnGitHub"), destination: URL(string: "https://github.com/Prot10/MyMacCleaner")!)
                .font(.caption)

            Spacer()
        }
        .padding()
    }
}
