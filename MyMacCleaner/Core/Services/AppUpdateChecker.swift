import Foundation

// MARK: - App Update Models

struct AppUpdate: Identifiable {
    let id = UUID()
    let appName: String
    let bundleIdentifier: String
    let currentVersion: String
    let latestVersion: String
    let downloadURL: URL?
    let releaseNotes: String?
    let source: UpdateSource

    enum UpdateSource: String {
        case sparkle = "Sparkle"
        case homebrew = "Homebrew"
        case macAppStore = "Mac App Store"
    }

    var hasUpdate: Bool {
        compareVersions(currentVersion, latestVersion) == .orderedAscending
    }
}

// MARK: - App Update Checker

actor AppUpdateChecker {

    // MARK: - Check for Sparkle Updates

    /// Check if an app has Sparkle update feed and get latest version
    func checkSparkleUpdate(for appURL: URL) async -> AppUpdate? {
        guard let bundle = Bundle(url: appURL),
              let infoPlist = bundle.infoDictionary,
              let bundleID = bundle.bundleIdentifier,
              let appName = infoPlist["CFBundleName"] as? String ?? infoPlist["CFBundleDisplayName"] as? String,
              let currentVersion = infoPlist["CFBundleShortVersionString"] as? String ?? infoPlist["CFBundleVersion"] as? String
        else {
            return nil
        }

        // Look for Sparkle feed URL
        guard let feedURLString = infoPlist["SUFeedURL"] as? String,
              let feedURL = URL(string: feedURLString)
        else {
            return nil
        }

        // Fetch and parse appcast
        do {
            let (data, _) = try await URLSession.shared.data(from: feedURL)
            if let latestInfo = parseAppcast(data) {
                return AppUpdate(
                    appName: appName,
                    bundleIdentifier: bundleID,
                    currentVersion: currentVersion,
                    latestVersion: latestInfo.version,
                    downloadURL: latestInfo.downloadURL,
                    releaseNotes: latestInfo.releaseNotes,
                    source: .sparkle
                )
            }
        } catch {
            print("Failed to fetch Sparkle feed for \(appName): \(error)")
        }

        return nil
    }

    /// Parse Sparkle appcast XML to get latest version info
    private func parseAppcast(_ data: Data) -> (version: String, downloadURL: URL?, releaseNotes: String?)? {
        let parser = AppcastParser()
        return parser.parse(data)
    }

    // MARK: - Check Multiple Apps

    /// Check updates for multiple apps concurrently
    func checkUpdates(for appURLs: [URL], progress: @escaping (Double) -> Void) async -> [AppUpdate] {
        var updates: [AppUpdate] = []
        let total = appURLs.count

        let results = await withTaskGroup(of: AppUpdate?.self, returning: [AppUpdate?].self) { group in
            for appURL in appURLs {
                group.addTask {
                    await self.checkSparkleUpdate(for: appURL)
                }
            }

            var collected: [AppUpdate?] = []
            for await update in group {
                collected.append(update)
                let currentProgress = Double(collected.count) / Double(total)
                await MainActor.run {
                    progress(currentProgress)
                }
            }
            return collected
        }

        for result in results {
            if let update = result, update.hasUpdate {
                updates.append(update)
            }
        }

        return updates
    }
}

// MARK: - Appcast XML Parser

private class AppcastParser: NSObject, XMLParserDelegate {
    private var currentElement = ""
    private var currentVersion = ""
    private var currentDownloadURL = ""
    private var currentReleaseNotes = ""
    private var items: [(version: String, downloadURL: URL?, releaseNotes: String?)] = []
    private var isInItem = false
    private var isInReleaseNotes = false

    func parse(_ data: Data) -> (version: String, downloadURL: URL?, releaseNotes: String?)? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        // Return the first (latest) item
        return items.first
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName

        if elementName == "item" {
            isInItem = true
            currentVersion = ""
            currentDownloadURL = ""
            currentReleaseNotes = ""
        } else if elementName == "enclosure" && isInItem {
            // Sparkle enclosure contains download URL and version
            if let url = attributeDict["url"] {
                currentDownloadURL = url
            }
            if let version = attributeDict["sparkle:shortVersionString"] ?? attributeDict["sparkle:version"] {
                currentVersion = version
            }
        } else if elementName == "sparkle:releaseNotesLink" || elementName == "description" {
            isInReleaseNotes = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if isInItem {
            if currentElement == "sparkle:shortVersionString" || currentElement == "sparkle:version" {
                currentVersion += trimmed
            } else if isInReleaseNotes {
                currentReleaseNotes += trimmed
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" && isInItem {
            if !currentVersion.isEmpty {
                items.append((
                    version: currentVersion,
                    downloadURL: URL(string: currentDownloadURL),
                    releaseNotes: currentReleaseNotes.isEmpty ? nil : currentReleaseNotes
                ))
            }
            isInItem = false
        } else if elementName == "sparkle:releaseNotesLink" || elementName == "description" {
            isInReleaseNotes = false
        }
    }
}

// MARK: - Version Comparison

private func compareVersions(_ version1: String, _ version2: String) -> ComparisonResult {
    let v1Components = version1.split(separator: ".").compactMap { Int($0) }
    let v2Components = version2.split(separator: ".").compactMap { Int($0) }

    let maxLength = max(v1Components.count, v2Components.count)

    for i in 0..<maxLength {
        let v1 = i < v1Components.count ? v1Components[i] : 0
        let v2 = i < v2Components.count ? v2Components[i] : 0

        if v1 < v2 {
            return .orderedAscending
        } else if v1 > v2 {
            return .orderedDescending
        }
    }

    return .orderedSame
}
