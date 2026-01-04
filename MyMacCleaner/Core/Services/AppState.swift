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

    // MARK: - Initialization

    init() {
        // ViewModels are initialized lazily when accessed
        // No auto-start of heavy operations here
    }

    // MARK: - Cleanup

    /// Call this when app is about to terminate to cleanup resources
    func cleanup() {
        performanceViewModel.stopProcessMonitoring()
    }
}
