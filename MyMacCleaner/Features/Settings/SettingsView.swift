import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab bar with glass effect
            HStack(spacing: 4) {
                GlassSettingsTab(
                    title: "General",
                    icon: "gearshape.fill",
                    isSelected: selectedTab == 0
                ) { selectedTab = 0 }

                GlassSettingsTab(
                    title: "Permissions",
                    icon: "lock.shield.fill",
                    isSelected: selectedTab == 1
                ) { selectedTab = 1 }

                GlassSettingsTab(
                    title: "Updates",
                    icon: "arrow.triangle.2.circlepath",
                    isSelected: selectedTab == 2
                ) { selectedTab = 2 }

                GlassSettingsTab(
                    title: "About",
                    icon: "info.circle.fill",
                    isSelected: selectedTab == 3
                ) { selectedTab = 3 }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 24)

            // Content
            Group {
                switch selectedTab {
                case 0: GlassGeneralSettingsView()
                case 1: GlassPermissionsSettingsView()
                case 2: GlassUpdateSettingsView()
                case 3: GlassAboutSettingsView()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        }
    }
}

// MARK: - Glass Settings Tab

struct GlassSettingsTab: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .secondary)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                } else {
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings

struct GlassGeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("askBeforeDelete") private var askBeforeDelete = true
    @AppStorage("moveToTrash") private var moveToTrash = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Startup section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Startup")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 2) {
                        GlassToggleRow(
                            title: "Launch at Login",
                            description: "Start MyMacCleaner when you log in",
                            isOn: $launchAtLogin,
                            icon: "power"
                        )

                        GlassToggleRow(
                            title: "Show Menu Bar Icon",
                            description: "Quick access from the menu bar",
                            isOn: $showMenuBarIcon,
                            icon: "menubar.rectangle"
                        )

                        GlassToggleRow(
                            title: "Enable Notifications",
                            description: "Get notified about cleanup recommendations",
                            isOn: $notificationsEnabled,
                            icon: "bell.fill"
                        )
                    }
                    .liquidGlassCard(cornerRadius: 16, style: .thin, padding: 4)
                }

                // Cleanup section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Cleanup Behavior")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 2) {
                        GlassToggleRow(
                            title: "Ask Before Deleting",
                            description: "Confirm before removing files",
                            isOn: $askBeforeDelete,
                            icon: "questionmark.circle.fill"
                        )

                        GlassToggleRow(
                            title: "Move to Trash",
                            description: "Move files to Trash instead of permanent delete",
                            isOn: $moveToTrash,
                            icon: "trash.fill"
                        )
                    }
                    .liquidGlassCard(cornerRadius: 16, style: .thin, padding: 4)
                }
            }
            .padding(24)
        }
    }
}

struct GlassToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Permissions Settings

struct GlassPermissionsSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Full Disk Access
                GlassPermissionCard(
                    title: "Full Disk Access",
                    description: appState.permissionsService.hasFullDiskAccess
                        ? "Granted - MyMacCleaner can scan all files"
                        : "Required to scan protected Library directories",
                    icon: "folder.fill.badge.gearshape",
                    isGranted: appState.permissionsService.hasFullDiskAccess,
                    buttonTitle: "Open Settings",
                    action: {
                        appState.permissionsService.openFullDiskAccessSettings()
                    }
                )

                // Helper Tool
                GlassPermissionCard(
                    title: "Helper Tool",
                    description: helperStatusText,
                    icon: "wrench.and.screwdriver.fill",
                    isGranted: appState.helperService.isReady,
                    buttonTitle: helperButtonTitle,
                    action: {
                        if appState.helperService.status == .notRegistered {
                            Task {
                                try? await appState.helperService.register()
                            }
                        } else if appState.helperService.status == .requiresApproval {
                            appState.helperService.openLoginItemsSettings()
                        }
                    }
                )
            }
            .padding(24)
        }
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
            return "Required for memory optimization and system cleanup"
        case .requiresApproval:
            return "Pending approval in System Settings"
        case .notFound:
            return "Helper not found - Please reinstall"
        case .unknown:
            return "Checking status..."
        }
    }

    private var helperButtonTitle: String {
        switch appState.helperService.status {
        case .notRegistered: return "Enable"
        case .requiresApproval: return "Open Settings"
        default: return "View Settings"
        }
    }
}

struct GlassPermissionCard: View {
    let title: String
    let description: String
    let icon: String
    let isGranted: Bool
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(isGranted ? Color.cleanGreen.opacity(0.15) : Color.cleanOrange.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: isGranted ? "checkmark.shield.fill" : icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isGranted ? Color.cleanGreen : Color.cleanOrange)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    if isGranted {
                        Text("Granted")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.cleanGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cleanGreen.opacity(0.15), in: Capsule())
                    }
                }

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !isGranted || buttonTitle == "Open Settings" || buttonTitle == "View Settings" {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(LiquidGlassButtonStyle(isProminent: !isGranted))
            }
        }
        .liquidGlassCard(cornerRadius: 18, style: .thin, padding: 18)
    }
}

// MARK: - Update Settings

struct GlassUpdateSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Update preferences
                VStack(alignment: .leading, spacing: 16) {
                    Text("Update Preferences")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)

                    VStack(spacing: 2) {
                        GlassToggleRow(
                            title: "Check Automatically",
                            description: "Automatically check for updates",
                            isOn: Binding(
                                get: { appState.updateService.automaticallyChecksForUpdates },
                                set: { appState.updateService.automaticallyChecksForUpdates = $0 }
                            ),
                            icon: "arrow.clockwise"
                        )

                        GlassToggleRow(
                            title: "Download Automatically",
                            description: "Download updates in the background",
                            isOn: Binding(
                                get: { appState.updateService.automaticallyDownloadsUpdates },
                                set: { appState.updateService.automaticallyDownloadsUpdates = $0 }
                            ),
                            icon: "arrow.down.circle.fill"
                        )
                    }
                    .liquidGlassCard(cornerRadius: 16, style: .thin, padding: 4)
                }

                // Check for updates
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Check for Updates")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)

                        if let lastCheck = appState.updateService.lastUpdateCheckDate {
                            Text("Last checked: \(lastCheck, style: .relative) ago")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never checked")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        appState.updateService.checkForUpdates()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("Check Now")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .buttonStyle(LiquidGlassButtonStyle(isProminent: true))
                    .disabled(!appState.updateService.canCheckForUpdates)
                }
                .liquidGlassCard(cornerRadius: 18, style: .thin, padding: 18)
            }
            .padding(24)
        }
    }
}

// MARK: - About Settings

struct GlassAboutSettingsView: View {
    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // App icon with glass effect
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.cleanBlue.opacity(0.3), .cleanPurple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cleanBlue, .cleanPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: .cleanBlue.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(spacing: 8) {
                Text("MyMacCleaner")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Version 1.0.0")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Text("A native macOS maintenance utility\nbuilt with Swift and SwiftUI")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            // Links
            HStack(spacing: 20) {
                GlassLinkButton(title: "Website", icon: "globe", url: "https://github.com/Prot10/MyMacCleaner")
                GlassLinkButton(title: "Privacy", icon: "hand.raised.fill", url: "https://github.com/Prot10/MyMacCleaner")
                GlassLinkButton(title: "License", icon: "doc.text.fill", url: "https://github.com/Prot10/MyMacCleaner/blob/main/LICENSE")
            }

            Text("Made with SwiftUI")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
    }
}

struct GlassLinkButton: View {
    let title: String
    let icon: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .frame(width: 550, height: 450)
}
