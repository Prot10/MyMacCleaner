import SwiftUI

@main
struct MyMacCleanerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appState.updateService.checkForUpdates()
                }
                .disabled(!appState.updateService.canCheckForUpdates)
            }

            CommandGroup(replacing: .help) {
                Button("MyMacCleaner Help") {
                    // Open help documentation
                }
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

// MARK: - App State

@Observable
final class AppState {
    var helperService: HelperConnectionService
    var permissionsService: PermissionsService
    var updateService: UpdateService

    var selectedNavigation: NavigationItem = .dashboard
    var isScanning = false
    var scanProgress: Double = 0

    init() {
        self.helperService = HelperConnectionService()
        self.permissionsService = PermissionsService()
        self.updateService = UpdateService()
    }
}

// MARK: - Navigation

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case cleaner = "Cleaner"
    case uninstaller = "Uninstaller"
    case optimizer = "Optimizer"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.bottom.50percent"
        case .cleaner: return "trash"
        case .uninstaller: return "app.badge.checkmark"
        case .optimizer: return "bolt.fill"
        case .settings: return "gearshape"
        }
    }

    var accentColor: Color {
        switch self {
        case .dashboard: return .cleanPurple      // Electric Violet - primary action
        case .cleaner: return .cleanGreen         // Neon Lime - cleanup/success
        case .uninstaller: return .cleanRed       // Hot Pink - removal/danger
        case .optimizer: return .cleanBlue        // Electric Cyan - performance
        case .settings: return .slate400          // Neutral slate
        }
    }
}
