import SwiftUI
import Combine

// MARK: - Update Available Notification
extension Notification.Name {
    static let updateAvailabilityChanged = Notification.Name("updateAvailabilityChanged")
}

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
    var updateAvailable: Bool = false {
        didSet {
            if updateAvailable != oldValue {
                print("[UpdateManager] updateAvailable changed: \(oldValue) -> \(updateAvailable)")
                // Broadcast notification for views that might not observe @Observable properly
                NotificationCenter.default.post(name: .updateAvailabilityChanged, object: nil)
            }
        }
    }
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

        print("[UpdateManager] Initializing...")

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

        // Check for updates immediately on launch
        print("[UpdateManager] Starting initial update check...")
        Task { @MainActor in
            await self.checkAppcastForUpdates()
        }
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
    @MainActor
    private func checkAppcastForUpdates() async {
        // Use hardcoded URL with cache-busting query parameter
        let timestamp = Int(Date().timeIntervalSince1970)
        let feedURLString = "https://raw.githubusercontent.com/Prot10/MyMacCleaner/main/appcast.xml?t=\(timestamp)"
        guard let feedURL = URL(string: feedURLString) else {
            print("[UpdateManager] ERROR: Invalid feed URL")
            return
        }

        print("[UpdateManager] Fetching appcast from: \(feedURL)")

        // Create a URL request with no caching
        var request = URLRequest(url: feedURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Log response status
            if let httpResponse = response as? HTTPURLResponse {
                print("[UpdateManager] HTTP Response: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("[UpdateManager] ERROR: Non-200 status code")
                    return
                }
            }

            // Log data size
            print("[UpdateManager] Received \(data.count) bytes")

            // Parse the appcast
            let parser = AppcastParser()
            if let latestVersion = parser.parseLatestVersion(from: data) {
                let currentBuildStr = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                let currentShortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

                print("[UpdateManager] Current: v\(currentShortVersion) (build \(currentBuildStr))")
                print("[UpdateManager] Latest:  v\(latestVersion.displayVersion) (build \(latestVersion.buildNumber))")

                // Compare build numbers
                if let latestBuild = Int(latestVersion.buildNumber),
                   let currentBuild = Int(currentBuildStr) {
                    print("[UpdateManager] Comparing builds: \(latestBuild) > \(currentBuild) = \(latestBuild > currentBuild)")

                    if latestBuild > currentBuild {
                        print("[UpdateManager] ✅ UPDATE AVAILABLE! Setting updateAvailable = true")
                        self.availableVersion = latestVersion.displayVersion
                        self.updateAvailable = true
                        self.updateDismissed = false
                    } else {
                        print("[UpdateManager] ℹ️ No update available (current >= latest)")
                        self.updateAvailable = false
                    }
                } else {
                    print("[UpdateManager] ERROR: Could not parse build numbers as integers")
                    print("[UpdateManager]   latestBuild: '\(latestVersion.buildNumber)' -> \(Int(latestVersion.buildNumber) as Any)")
                    print("[UpdateManager]   currentBuild: '\(currentBuildStr)' -> \(Int(currentBuildStr) as Any)")
                }
            } else {
                print("[UpdateManager] ERROR: Failed to parse appcast XML")
                // Log first 500 chars of data for debugging
                if let xmlString = String(data: data.prefix(500), encoding: .utf8) {
                    print("[UpdateManager] XML preview: \(xmlString)")
                }
            }
        } catch {
            print("[UpdateManager] ERROR: Network request failed: \(error.localizedDescription)")
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
