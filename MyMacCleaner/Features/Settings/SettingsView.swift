import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            PermissionsSettingsView()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }

            UpdateSettingsView()
                .tabItem {
                    Label("Updates", systemImage: "arrow.triangle.2.circlepath")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                Toggle("Show Menu Bar Icon", isOn: $showMenuBarIcon)
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
            }

            Section("Cleanup") {
                Toggle("Ask before deleting files", isOn: .constant(true))
                Toggle("Move to Trash instead of permanent delete", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Permissions Settings

struct PermissionsSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: appState.permissionsService.hasFullDiskAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.permissionsService.hasFullDiskAccess ? .green : .red)

                    VStack(alignment: .leading) {
                        Text("Full Disk Access")
                            .font(.headline)
                        Text(appState.permissionsService.hasFullDiskAccess
                             ? "Granted - MyMacCleaner can scan all files"
                             : "Not Granted - Some features will be limited")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Open Settings") {
                        appState.permissionsService.openFullDiskAccessSettings()
                    }
                }
            }

            Section {
                HStack {
                    Image(systemName: appState.helperService.isReady ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(appState.helperService.isReady ? .green : .orange)

                    VStack(alignment: .leading) {
                        Text("Helper Tool")
                            .font(.headline)
                        Text(helperStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if appState.helperService.status == .notRegistered {
                        Button("Enable") {
                            Task {
                                try? await appState.helperService.register()
                            }
                        }
                    } else if appState.helperService.status == .requiresApproval {
                        Button("Open Settings") {
                            appState.helperService.openLoginItemsSettings()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            appState.permissionsService.checkPermissions()
            appState.helperService.updateStatus()
        }
    }

    private var helperStatusText: String {
        switch appState.helperService.status {
        case .enabled:
            return "Enabled - Privileged operations available"
        case .notRegistered:
            return "Not registered - Click Enable to set up"
        case .requiresApproval:
            return "Pending approval in System Settings"
        case .notFound:
            return "Helper not found - Please reinstall"
        case .unknown:
            return "Unknown status"
        }
    }
}

// MARK: - Update Settings

struct UpdateSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section {
                Toggle("Automatically check for updates",
                       isOn: Binding(
                        get: { appState.updateService.automaticallyChecksForUpdates },
                        set: { appState.updateService.automaticallyChecksForUpdates = $0 }
                       ))

                Toggle("Automatically download updates",
                       isOn: Binding(
                        get: { appState.updateService.automaticallyDownloadsUpdates },
                        set: { appState.updateService.automaticallyDownloadsUpdates = $0 }
                       ))
            }

            Section {
                HStack {
                    if let lastCheck = appState.updateService.lastUpdateCheckDate {
                        Text("Last checked: \(lastCheck, style: .relative) ago")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Check Now") {
                        appState.updateService.checkForUpdates()
                    }
                    .disabled(!appState.updateService.canCheckForUpdates)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("MyMacCleaner")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("A native macOS maintenance utility")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            HStack {
                Link("Website", destination: URL(string: "https://example.com")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Link("License", destination: URL(string: "https://example.com/license")!)
            }
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
}
