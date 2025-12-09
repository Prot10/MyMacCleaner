import Foundation

/// Manages app updates via Sparkle (placeholder until Sparkle is added)
@Observable
final class UpdateService {
    // Placeholder implementation - will be replaced when Sparkle is added
    var canCheckForUpdates: Bool { true }

    var automaticallyChecksForUpdates: Bool = true
    var automaticallyDownloadsUpdates: Bool = false
    var lastUpdateCheckDate: Date? = nil

    init() { }

    func checkForUpdates() {
        // TODO: Implement with Sparkle
        print("Check for updates - Sparkle not yet configured")
    }
}
