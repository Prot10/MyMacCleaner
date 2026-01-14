import SwiftUI

/// Central app state that holds all ViewModels
/// This ensures state is preserved when switching between sections
@MainActor
class AppState: ObservableObject {
    // MARK: - Singleton ViewModels

    /// Home section state
    let homeViewModel = HomeViewModel()

    /// Disk Cleaner section state
    let diskCleanerViewModel = DiskCleanerViewModel()

    /// Space Lens section state
    let spaceLensViewModel = SpaceLensViewModel()

    /// Performance section state
    let performanceViewModel = PerformanceViewModel()

    /// Applications section state
    let applicationsViewModel = ApplicationsViewModel()

    /// Port Management section state
    let portManagementViewModel = PortManagementViewModel()

    /// System Health section state
    let systemHealthViewModel = SystemHealthViewModel()

    /// Startup Items section state
    let startupItemsViewModel = StartupItemsViewModel()

    /// Permissions section state
    let permissionsViewModel = PermissionsViewModel()

    /// Orphaned Files section state
    let orphanedFilesViewModel = OrphanedFilesViewModel()

    /// Duplicates section state
    let duplicatesViewModel = DuplicatesViewModel()

    // MARK: - Initialization

    init() {
        // ViewModels are initialized as properties and may perform
        // lightweight init tasks. Heavy operations (like scanning) are
        // only started when the user explicitly triggers them.
        // Note: PermissionsViewModel skips TCC-triggerable folders at startup
        // to avoid showing permission dialogs when the app opens.
    }

    // MARK: - Cleanup

    /// Call this when app is about to terminate to cleanup resources
    func cleanup() {
        performanceViewModel.stopProcessMonitoring()
    }
}
