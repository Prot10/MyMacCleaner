import SwiftUI
import Combine

// MARK: - Update Manager
// Handles auto-updates via Sparkle framework
// Note: Sparkle must be added via File > Add Package Dependencies in Xcode
// URL: https://github.com/sparkle-project/Sparkle

#if canImport(Sparkle)
import Sparkle

@Observable
final class UpdateManager: NSObject, SPUUpdaterDelegate {
    private let updaterController: SPUStandardUpdaterController
    private var cancellables = Set<AnyCancellable>()

    var canCheckForUpdates: Bool = false
    var lastUpdateCheck: Date?

    // Update availability state
    var updateAvailable: Bool = false
    var availableVersion: String?
    var updateDismissed: Bool = false

    var automaticChecksEnabled: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    override init() {
        // Initialize controller first without delegate
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        super.init()

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

        // Start the updater
        updaterController.startUpdater()

        // Check for updates once canCheckForUpdates becomes true
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .filter { $0 == true }
            .first()
            .sink { [weak self] _ in
                // Small delay to ensure everything is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.checkForUpdatesQuietly()
                }
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

    /// Check for updates quietly (just to detect if update is available)
    func checkForUpdatesQuietly() {
        print("[UpdateManager] checkForUpdatesQuietly called, canCheckForUpdates: \(canCheckForUpdates)")

        // Check appcast directly - don't wait for canCheckForUpdates
        Task {
            await checkAppcastForUpdates()
        }
    }

    /// Dismiss the update banner
    func dismissUpdateBanner() {
        updateDismissed = true
    }

    /// Reset dismissed state (e.g., when a new version is detected)
    func resetDismissedState() {
        updateDismissed = false
    }

    // MARK: - Manual Appcast Check

    /// Manually fetch and parse the appcast to check for updates
    private func checkAppcastForUpdates() async {
        guard let feedURL = updaterController.updater.feedURL else {
            print("[UpdateManager] No feed URL configured")
            return
        }

        print("[UpdateManager] Fetching appcast from: \(feedURL)")

        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            let parser = AppcastParser()
            if let latestVersion = parser.parseLatestVersion(from: data) {
                let currentBuildStr = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                let currentShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

                print("[UpdateManager] Current: \(currentShortVersion) (build \(currentBuildStr)), Latest: \(latestVersion.displayVersion) (build \(latestVersion.buildNumber))")

                // Compare build numbers
                if let latestBuild = Int(latestVersion.buildNumber),
                   let currentBuild = Int(currentBuildStr),
                   latestBuild > currentBuild {
                    print("[UpdateManager] Update available! Setting updateAvailable = true")
                    await MainActor.run {
                        self.availableVersion = latestVersion.displayVersion
                        self.updateAvailable = true
                        self.updateDismissed = false
                    }
                } else {
                    print("[UpdateManager] No update available (current build \(currentBuildStr) >= latest build \(latestVersion.buildNumber))")
                }
            } else {
                print("[UpdateManager] Failed to parse appcast")
            }
        } catch {
            print("[UpdateManager] Failed to check for updates: \(error)")
        }
    }
}

// MARK: - Appcast Parser

private class AppcastParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var latestVersion: (displayVersion: String, buildNumber: String)?
    private var currentDisplayVersion: String?
    private var currentBuildNumber: String?
    private var isInItem = false

    func parseLatestVersion(from data: Data) -> (displayVersion: String, buildNumber: String)? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return latestVersion
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            isInItem = true
            currentDisplayVersion = nil
            currentBuildNumber = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isInItem else { return }

        switch currentElement {
        case "sparkle:shortVersionString":
            currentDisplayVersion = (currentDisplayVersion ?? "") + trimmed
        case "sparkle:version":
            currentBuildNumber = (currentBuildNumber ?? "") + trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            isInItem = false
            // Only take the first (latest) item
            if latestVersion == nil,
               let displayVersion = currentDisplayVersion,
               let buildNumber = currentBuildNumber {
                latestVersion = (displayVersion, buildNumber)
            }
        }
        currentElement = ""
    }
}

#else

// Fallback when Sparkle is not available
@Observable
final class UpdateManager {
    var canCheckForUpdates: Bool = false
    var lastUpdateCheck: Date? = nil
    var automaticChecksEnabled: Bool = true
    var updateAvailable: Bool = false
    var availableVersion: String? = nil
    var updateDismissed: Bool = false

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

    func checkForUpdatesQuietly() {
        print("⚠️ Updates not available - Sparkle not installed")
    }

    func dismissUpdateBanner() {
        updateDismissed = true
    }

    func resetDismissedState() {
        updateDismissed = false
    }
}

#endif
