import Foundation
import SwiftUI

// MARK: - Startup Item Model

struct StartupItem: Identifiable, Hashable {
    let id: String
    let name: String
    let label: String
    let type: StartupItemType
    let path: String
    let executablePath: String?
    let isEnabled: Bool
    let isRunning: Bool
    let isSystemItem: Bool
    let developer: String?
    let bundleIdentifier: String?

    var displayName: String {
        // Clean up the name for display
        if name.isEmpty {
            return label
        }
        return name
    }

    var icon: String {
        switch type {
        case .launchAgent:
            return "person.crop.circle"
        case .launchDaemon:
            return "gearshape.2"
        case .loginItem:
            return "arrow.right.circle"
        case .userLaunchAgent:
            return "person.circle"
        }
    }

    var typeColor: Color {
        switch type {
        case .launchAgent:
            return .blue
        case .launchDaemon:
            return .orange
        case .loginItem:
            return .green
        case .userLaunchAgent:
            return .purple
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: StartupItem, rhs: StartupItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Startup Item Type

enum StartupItemType: String, CaseIterable {
    case launchAgent
    case launchDaemon
    case loginItem
    case userLaunchAgent

    var localizedName: String {
        L(key: "startupItems.type.\(rawValue)")
    }

    var localizedDescription: String {
        L(key: "startupItems.typeDesc.\(rawValue)")
    }

    var icon: String {
        switch self {
        case .launchAgent: return "person.crop.circle"
        case .launchDaemon: return "gearshape.2"
        case .loginItem: return "arrow.right.circle"
        case .userLaunchAgent: return "person.circle"
        }
    }
}

// MARK: - Startup Items Service

actor StartupItemsService {
    static let shared = StartupItemsService()

    private init() {}

    // MARK: - Directory Paths

    private var userLaunchAgentsPath: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/LaunchAgents"
    }

    private let globalLaunchAgentsPath = "/Library/LaunchAgents"
    private let globalLaunchDaemonsPath = "/Library/LaunchDaemons"
    private let systemLaunchAgentsPath = "/System/Library/LaunchAgents"
    private let systemLaunchDaemonsPath = "/System/Library/LaunchDaemons"

    // MARK: - Scanning

    func scanAllItems() async -> [StartupItem] {
        var items: [StartupItem] = []
        var seenIdentifiers = Set<String>()

        // Primary: Parse BTM database (most comprehensive on macOS 13+)
        let btmItems = await parseBTMDatabase()
        for item in btmItems {
            if !seenIdentifiers.contains(item.label) {
                items.append(item)
                seenIdentifiers.insert(item.label)
            }
        }

        // Get running items for status check
        let runningLabels = await getRunningLabels()

        // Fallback: Scan plist directories for items not in BTM
        let directories: [(path: String, type: StartupItemType, isSystem: Bool)] = [
            (userLaunchAgentsPath, .userLaunchAgent, false),
            (globalLaunchAgentsPath, .launchAgent, false),
            (globalLaunchDaemonsPath, .launchDaemon, false)
        ]

        for (path, type, isSystem) in directories {
            let dirItems = await scanDirectory(
                path: path,
                type: type,
                isSystem: isSystem,
                runningLabels: runningLabels
            )
            for item in dirItems {
                if !seenIdentifiers.contains(item.label) {
                    items.append(item)
                    seenIdentifiers.insert(item.label)
                }
            }
        }

        // Fallback: Traditional login items via AppleScript
        let loginItems = await getLoginItems()
        for item in loginItems {
            if !seenIdentifiers.contains(item.label) {
                items.append(item)
                seenIdentifiers.insert(item.label)
            }
        }

        return items.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }

    // MARK: - BTM Database Parsing

    private func parseBTMDatabase() async -> [StartupItem] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [StartupItem] = []

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/sfltool")
                process.arguments = ["dumpbtm"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        items = StartupItemsService.parseBTMOutput(output)
                    }
                } catch {
                    print("Error running sfltool: \(error)")
                }

                continuation.resume(returning: items)
            }
        }
    }

    private static nonisolated func parseBTMOutput(_ output: String) -> [StartupItem] {
        var items: [StartupItem] = []
        let lines = output.components(separatedBy: "\n")

        var currentItem: [String: String] = [:]
        var inItem = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Start of a new item
            if trimmed.hasPrefix("#") && trimmed.contains(":") {
                // Save previous item if exists
                if inItem, let item = StartupItemsService.createItemFromBTMData(currentItem) {
                    items.append(item)
                }
                currentItem = [:]
                inItem = true
                continue
            }

            // Skip section headers
            if trimmed.hasPrefix("===") || trimmed.hasPrefix("Records for UID") {
                continue
            }

            // Parse key-value pairs
            if inItem && trimmed.contains(":") {
                let parts = trimmed.split(separator: ":", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    currentItem[key] = value
                }
            }
        }

        // Don't forget the last item
        if inItem, let item = StartupItemsService.createItemFromBTMData(currentItem) {
            items.append(item)
        }

        return items
    }

    private static func createItemFromBTMData(_ data: [String: String]) -> StartupItem? {
        guard let name = data["Name"], !name.isEmpty,
              let identifier = data["Identifier"]
        else { return nil }

        // Skip Apple system items
        if identifier.contains("com.apple.") {
            return nil
        }

        // Parse type
        let typeString = data["Type"] ?? ""
        let itemType: StartupItemType
        if typeString.contains("login item") {
            itemType = .loginItem
        } else if typeString.contains("daemon") {
            itemType = .launchDaemon
        } else if typeString.contains("agent") {
            itemType = .launchAgent
        } else if typeString.contains("app") {
            // Skip app entries - we want their embedded items, not the app itself
            return nil
        } else if typeString.contains("developer") {
            // Skip developer entries - these are groupings
            return nil
        } else {
            itemType = .launchAgent
        }

        // Parse disposition for enabled status
        let disposition = data["Disposition"] ?? ""
        let isEnabled = disposition.contains("enabled")

        // Parse URL for path
        var path = ""
        if let url = data["URL"] {
            // Clean up file:// URLs
            path = url.replacingOccurrences(of: "file://", with: "")
                .removingPercentEncoding ?? url
            // Handle relative paths
            if !path.hasPrefix("/") && path.contains("Contents/") {
                // This is a relative path inside an app bundle
                if let bundleId = data["Bundle Identifier"] ?? data["Parent Identifier"] {
                    // Try to find the parent app
                    path = "Embedded in app: \(bundleId)"
                }
            }
        }

        // Get executable path
        let executablePath = data["Executable Path"]?.removingPercentEncoding

        // Get developer
        let developer = data["Developer Name"]

        // Get bundle identifier
        let bundleIdentifier = data["Bundle Identifier"]

        // Create a unique ID
        let id = "btm:\(identifier)"

        return StartupItem(
            id: id,
            name: name,
            label: identifier,
            type: itemType,
            path: path,
            executablePath: executablePath,
            isEnabled: isEnabled,
            isRunning: false, // Will be updated separately
            isSystemItem: false,
            developer: developer,
            bundleIdentifier: bundleIdentifier
        )
    }

    private func scanDirectory(
        path: String,
        type: StartupItemType,
        isSystem: Bool,
        runningLabels: Set<String>
    ) async -> [StartupItem] {
        var items: [StartupItem] = []

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: path) else { return items }

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)

            for filename in contents {
                guard filename.hasSuffix(".plist") else { continue }

                let plistPath = "\(path)/\(filename)"
                if let item = parsePlist(at: plistPath, type: type, isSystem: isSystem, runningLabels: runningLabels) {
                    items.append(item)
                }
            }
        } catch {
            print("Error scanning \(path): \(error)")
        }

        return items
    }

    private func parsePlist(
        at path: String,
        type: StartupItemType,
        isSystem: Bool,
        runningLabels: Set<String>
    ) -> StartupItem? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }

        // Extract label (required)
        guard let label = plist["Label"] as? String else { return nil }

        // Skip Apple system items unless specifically requested
        if label.hasPrefix("com.apple.") && !isSystem {
            return nil
        }

        // Extract executable path
        var executablePath: String?
        if let program = plist["Program"] as? String {
            executablePath = program
        } else if let programArgs = plist["ProgramArguments"] as? [String], !programArgs.isEmpty {
            executablePath = programArgs[0]
        }

        // Determine if disabled
        let isDisabled = plist["Disabled"] as? Bool ?? false

        // Determine if running
        let isRunning = runningLabels.contains(label)

        // Extract name from label
        let name = extractNameFromLabel(label)

        // Try to get developer info from executable
        var developer: String?
        if let execPath = executablePath {
            developer = Self.getCodeSigningTeam(for: execPath)
        }

        return StartupItem(
            id: path,
            name: name,
            label: label,
            type: type,
            path: path,
            executablePath: executablePath,
            isEnabled: !isDisabled,
            isRunning: isRunning,
            isSystemItem: isSystem || label.hasPrefix("com.apple."),
            developer: developer,
            bundleIdentifier: label
        )
    }

    private func extractNameFromLabel(_ label: String) -> String {
        // Extract a readable name from the label
        // e.g., "com.docker.helper" -> "Docker Helper"
        let components = label.components(separatedBy: ".")

        // Take the last meaningful component
        var name = components.last ?? label

        // If it's a common suffix, take the one before
        if ["helper", "agent", "daemon", "service", "launcher"].contains(name.lowercased()) {
            if components.count >= 2 {
                name = components[components.count - 2]
            }
        }

        // Capitalize and clean up
        name = name.replacingOccurrences(of: "-", with: " ")
        name = name.replacingOccurrences(of: "_", with: " ")

        // Title case
        let words = name.components(separatedBy: " ")
        let titleCased = words.map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }

        return titleCased.joined(separator: " ")
    }

    private func getRunningLabels() async -> Set<String> {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var labels = Set<String>()

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["list"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        let lines = output.components(separatedBy: "\n")
                        for line in lines.dropFirst() { // Skip header
                            let components = line.split(separator: "\t", omittingEmptySubsequences: false)
                            if components.count >= 3 {
                                let label = String(components[2])
                                if !label.isEmpty {
                                    labels.insert(label)
                                }
                            }
                        }
                    }
                } catch {
                    print("Error getting running labels: \(error)")
                }

                continuation.resume(returning: labels)
            }
        }
    }

    // MARK: - Login Items

    private func getLoginItems() async -> [StartupItem] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [StartupItem] = []

                // Use AppleScript to get login items
                let script = """
                tell application "System Events"
                    set loginItems to every login item
                    set output to ""
                    repeat with loginItem in loginItems
                        set itemName to name of loginItem
                        set itemPath to path of loginItem
                        set isHidden to hidden of loginItem
                        set output to output & itemName & "|||" & itemPath & "|||" & isHidden & "\\n"
                    end repeat
                    return output
                end tell
                """

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8) {
                        let lines = output.components(separatedBy: "\n")
                        for line in lines {
                            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { continue }

                            let parts = trimmed.components(separatedBy: "|||")
                            guard parts.count >= 2 else { continue }

                            let name = parts[0]
                            let path = parts[1]
                            // parts[2] contains isHidden but not used currently

                            let item = StartupItem(
                                id: "loginitem:\(path)",
                                name: name,
                                label: name,
                                type: .loginItem,
                                path: path,
                                executablePath: path,
                                isEnabled: true,
                                isRunning: false, // We can't easily determine this
                                isSystemItem: false,
                                developer: StartupItemsService.getCodeSigningTeam(for: path),
                                bundleIdentifier: nil
                            )
                            items.append(item)
                        }
                    }
                } catch {
                    print("Error getting login items: \(error)")
                }

                continuation.resume(returning: items)
            }
        }
    }

    // MARK: - Management Actions

    @discardableResult
    func setItemEnabled(_ item: StartupItem, enabled: Bool) async -> Bool {
        // BTM items (from sfltool) need special handling
        if item.id.hasPrefix("btm:") {
            // For BTM login items, try using the bundled helper approach
            if item.type == .loginItem {
                // Modern login items can't be toggled programmatically without the app's cooperation
                // Open System Settings instead
                openLoginItemsSettings()
                return true // Return true since we opened settings
            }

            // For BTM agents/daemons, try launchctl if we have the plist path
            if item.path.hasSuffix(".plist") {
                return await setLaunchItemEnabled(item, enabled: enabled)
            }

            // Otherwise open System Settings
            openLoginItemsSettings()
            return true
        }

        switch item.type {
        case .loginItem:
            return await setLoginItemEnabled(item, enabled: enabled)
        case .userLaunchAgent, .launchAgent, .launchDaemon:
            return await setLaunchItemEnabled(item, enabled: enabled)
        }
    }

    func openLoginItemsSettings() {
        // Open System Settings > General > Login Items
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func setLaunchItemEnabled(_ item: StartupItem, enabled: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Get service name from plist filename (e.g., com.example.agent from com.example.agent.plist)
                let serviceName = (item.path as NSString).lastPathComponent
                    .replacingOccurrences(of: ".plist", with: "")

                // Determine target (gui/uid for user agents, system for system daemons)
                let uid = getuid()
                let isUserAgent = item.path.contains("/Library/LaunchAgents") ||
                                  item.path.contains("\(NSHomeDirectory())/Library/LaunchAgents")
                let target = isUserAgent ? "gui/\(uid)" : "system"

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")

                if enabled {
                    // Modern approach: bootout then bootstrap (equivalent to unload then load)
                    // This is safer than enable/disable which requires the service to be loaded
                    if isUserAgent {
                        // For user agents: bootstrap into user domain
                        process.arguments = ["bootstrap", target, item.path]
                    } else {
                        // For system daemons: use load (requires admin)
                        // Note: bootstrap for system services requires root
                        process.arguments = ["load", "-w", item.path]
                    }
                } else {
                    if isUserAgent {
                        // For user agents: bootout from user domain
                        process.arguments = ["bootout", "\(target)/\(serviceName)"]
                    } else {
                        // For system daemons: use unload (requires admin)
                        process.arguments = ["unload", "-w", item.path]
                    }
                }

                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    // bootout may return non-zero if service wasn't running, which is OK
                    let success = process.terminationStatus == 0 ||
                                  (!enabled && process.terminationStatus == 3) // "No such process" is OK for unload
                    continuation.resume(returning: success)
                } catch {
                    print("Error setting item enabled: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func setLoginItemEnabled(_ item: StartupItem, enabled: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let escapedName = item.name.replacingOccurrences(of: "\"", with: "\\\"")

                let script: String
                if enabled {
                    // Add login item
                    let escapedPath = item.path.replacingOccurrences(of: "\"", with: "\\\"")
                    script = """
                    tell application "System Events"
                        make login item at end with properties {path:"\(escapedPath)", hidden:false}
                    end tell
                    """
                } else {
                    // Remove login item
                    script = """
                    tell application "System Events"
                        delete login item "\(escapedName)"
                    end tell
                    """
                }

                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
                process.arguments = ["-e", script]

                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    print("Error setting login item enabled: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    func removeItem(_ item: StartupItem) async -> Bool {
        switch item.type {
        case .loginItem:
            return await setItemEnabled(item, enabled: false)
        case .userLaunchAgent:
            // For user launch agents, we can delete the plist
            return await removeLaunchItem(item, requiresAdmin: false)
        case .launchAgent, .launchDaemon:
            // For system-level items, require admin
            return await removeLaunchItem(item, requiresAdmin: true)
        }
    }

    private func removeLaunchItem(_ item: StartupItem, requiresAdmin: Bool) async -> Bool {
        // First unload the item
        let unloaded = await setItemEnabled(item, enabled: false)
        if !unloaded {
            print("Warning: Could not unload item before removal")
        }

        // Then move to trash
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let fileURL = URL(fileURLWithPath: item.path)
                    try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
                    continuation.resume(returning: true)
                } catch {
                    print("Error removing item: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - Code Signing

    private static nonisolated func getCodeSigningTeam(for path: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["-dv", "--verbose=2", path]

        let pipe = Pipe()
        process.standardOutput = FileHandle.nullDevice
        process.standardError = pipe // codesign outputs to stderr

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for TeamIdentifier line
                for line in output.components(separatedBy: "\n") {
                    if line.contains("TeamIdentifier=") {
                        let team = line.replacingOccurrences(of: "TeamIdentifier=", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if team != "not set" && !team.isEmpty {
                            return team
                        }
                    }
                    // Also try Authority line for developer name
                    if line.contains("Authority=Developer ID Application:") {
                        var developer = line.replacingOccurrences(of: "Authority=Developer ID Application: ", with: "")
                        // Remove the team ID in parentheses
                        if let range = developer.range(of: " (", options: .backwards) {
                            developer = String(developer[..<range.lowerBound])
                        }
                        return developer.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        } catch {
            // Silent fail
        }

        return nil
    }

    func revealInFinder(_ item: StartupItem) {
        let url = URL(fileURLWithPath: item.path)
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}
