import SwiftUI
import Combine

// MARK: - Update Manager
// Handles auto-updates via Sparkle framework
// Note: Sparkle must be added via File > Add Package Dependencies in Xcode
// URL: https://github.com/sparkle-project/Sparkle

#if canImport(Sparkle)
import Sparkle

@Observable
final class UpdateManager {
    private let updaterController: SPUStandardUpdaterController
    private var cancellables = Set<AnyCancellable>()

    var canCheckForUpdates: Bool = false
    var lastUpdateCheck: Date?

    var automaticChecksEnabled: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Default to automatically checking for updates on first launch
        if !UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore") {
            updaterController.updater.automaticallyChecksForUpdates = true
            UserDefaults.standard.set(true, forKey: "SUHasLaunchedBefore")
        }

        // Observe canCheckForUpdates
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canCheck in
                self?.canCheckForUpdates = canCheck
            }
            .store(in: &cancellables)

        // Observe last update check date
        updaterController.updater.publisher(for: \.lastUpdateCheckDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] date in
                self?.lastUpdateCheck = date
            }
            .store(in: &cancellables)
    }

    /// Check for updates interactively (shows UI)
    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }

    /// Check for updates in background (no UI unless update available)
    func checkForUpdatesInBackground() {
        updaterController.updater.checkForUpdatesInBackground()
    }
}

#else

// Fallback when Sparkle is not available
@Observable
final class UpdateManager {
    var canCheckForUpdates: Bool = false
    var lastUpdateCheck: Date? = nil
    var automaticChecksEnabled: Bool = true

    init() {
        print("⚠️ Sparkle framework not available. Add via File > Add Package Dependencies")
        print("   URL: https://github.com/sparkle-project/Sparkle")
    }

    func checkForUpdates() {
        print("⚠️ Updates not available - Sparkle not installed")
    }

    func checkForUpdatesInBackground() {
        print("⚠️ Updates not available - Sparkle not installed")
    }
}

#endif
