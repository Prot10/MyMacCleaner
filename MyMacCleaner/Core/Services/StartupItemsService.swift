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
    case launchAgent = "Launch Agent"
    case launchDaemon = "Launch Daemon"
    case loginItem = "Login Item"
    case userLaunchAgent = "User Agent"

    var description: String {
        switch self {
        case .launchAgent:
            return "System-wide per-user background services"
        case .launchDaemon:
            return "System-wide background services (root)"
        case .loginItem:
            return "Apps that open when you log in"
        case .userLaunchAgent:
            return "Your personal background services"
        }
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

        // Get running items for status check
        let runningLabels = await getRunningLabels()

        // Scan user launch agents
        let userAgents = await scanDirectory(
            path: userLaunchAgentsPath,
            type: .userLaunchAgent,
            isSystem: false,
            runningLabels: runningLabels
        )
        items.append(contentsOf: userAgents)

        // Scan global launch agents
        let globalAgents = await scanDirectory(
            path: globalLaunchAgentsPath,
            type: .launchAgent,
            isSystem: false,
            runningLabels: runningLabels
        )
        items.append(contentsOf: globalAgents)

        // Scan global launch daemons
        let globalDaemons = await scanDirectory(
            path: globalLaunchDaemonsPath,
            type: .launchDaemon,
            isSystem: false,
            runningLabels: runningLabels
        )
        items.append(contentsOf: globalDaemons)

        // Scan login items
        let loginItems = await getLoginItems()
        items.append(contentsOf: loginItems)

        return items.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
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
            developer = getCodeSigningTeam(for: execPath)
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
                            let isHidden = parts.count >= 3 ? parts[2] == "true" : false

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
                                developer: self.getCodeSigningTeam(for: path),
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

    func setItemEnabled(_ item: StartupItem, enabled: Bool) async -> Bool {
        switch item.type {
        case .loginItem:
            return await setLoginItemEnabled(item, enabled: enabled)
        case .userLaunchAgent, .launchAgent, .launchDaemon:
            return await setLaunchItemEnabled(item, enabled: enabled)
        }
    }

    private func setLaunchItemEnabled(_ item: StartupItem, enabled: Bool) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // For launch agents/daemons, we use launchctl to load/unload
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")

                if enabled {
                    // Load the item
                    process.arguments = ["load", "-w", item.path]
                } else {
                    // Unload the item
                    process.arguments = ["unload", "-w", item.path]
                }

                process.standardOutput = FileHandle.nullDevice
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
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

    private func getCodeSigningTeam(for path: String) -> String? {
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
