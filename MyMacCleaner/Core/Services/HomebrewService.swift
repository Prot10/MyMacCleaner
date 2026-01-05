import Foundation
import AppKit

// MARK: - Homebrew Models

struct HomebrewCask: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let installedVersion: String?
    let description: String?
    let homepage: URL?
    let hasUpdate: Bool

    var displayName: String {
        name.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }
}

struct HomebrewFormula: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let description: String?
    let hasUpdate: Bool
}

// MARK: - Homebrew Service

actor HomebrewService {

    // MARK: - Homebrew Detection

    /// Check if Homebrew is installed
    func isHomebrewInstalled() async -> Bool {
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"       // Intel
        ]

        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        return false
    }

    /// Get the Homebrew executable path
    private func brewPath() -> String? {
        let paths = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew"
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    // MARK: - List Installed Casks

    /// Get list of installed Homebrew casks
    func listInstalledCasks() async throws -> [HomebrewCask] {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        // Get installed casks
        let output = try await runCommand(brew, arguments: ["list", "--cask", "-1"])
        let caskNames = output.split(separator: "\n").map { String($0) }

        var casks: [HomebrewCask] = []

        // Get info for each cask
        for name in caskNames {
            if let cask = try? await getCaskInfo(name) {
                casks.append(cask)
            }
        }

        return casks
    }

    /// Get detailed info for a specific cask
    private func getCaskInfo(_ name: String) async throws -> HomebrewCask {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        let output = try await runCommand(brew, arguments: ["info", "--cask", "--json=v2", name])

        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let casks = json["casks"] as? [[String: Any]],
              let caskInfo = casks.first
        else {
            return HomebrewCask(
                name: name,
                version: "Unknown",
                installedVersion: nil,
                description: nil,
                homepage: nil,
                hasUpdate: false
            )
        }

        let version = caskInfo["version"] as? String ?? "Unknown"
        let desc = caskInfo["desc"] as? String
        let homepageString = caskInfo["homepage"] as? String
        let homepage = homepageString.flatMap { URL(string: $0) }

        // Get installed version
        let installedOutput = try? await runCommand(brew, arguments: ["list", "--cask", "--versions", name])
        let installedVersion = installedOutput?.split(separator: " ").last.map { String($0) }

        let hasUpdate = installedVersion != nil && installedVersion != version

        return HomebrewCask(
            name: name,
            version: version,
            installedVersion: installedVersion,
            description: desc,
            homepage: homepage,
            hasUpdate: hasUpdate
        )
    }

    // MARK: - List Installed Formulas

    /// Get list of installed Homebrew formulas
    func listInstalledFormulas() async throws -> [HomebrewFormula] {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        let output = try await runCommand(brew, arguments: ["list", "--formula", "-1"])
        let formulaNames = output.split(separator: "\n").map { String($0) }

        var formulas: [HomebrewFormula] = []

        for name in formulaNames {
            formulas.append(HomebrewFormula(
                name: name,
                version: "",
                description: nil,
                hasUpdate: false
            ))
        }

        return formulas
    }

    // MARK: - Check for Updates

    /// Check for outdated casks
    func getOutdatedCasks() async throws -> [HomebrewCask] {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        let output = try await runCommand(brew, arguments: ["outdated", "--cask", "--greedy"])
        let outdatedNames = output.split(separator: "\n").map { String($0).split(separator: " ").first.map { String($0) } ?? "" }

        var casks: [HomebrewCask] = []
        for name in outdatedNames where !name.isEmpty {
            if let cask = try? await getCaskInfo(name) {
                casks.append(cask)
            }
        }

        return casks
    }

    // MARK: - Cask Operations

    /// Install a cask
    func installCask(_ name: String) async throws {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        _ = try await runCommand(brew, arguments: ["install", "--cask", name])
    }

    /// Uninstall a cask
    func uninstallCask(_ name: String) async throws {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        _ = try await runCommand(brew, arguments: ["uninstall", "--cask", name])
    }

    /// Upgrade a cask
    func upgradeCask(_ name: String) async throws {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        _ = try await runCommand(brew, arguments: ["upgrade", "--cask", name])
    }

    /// Upgrade all outdated casks
    func upgradeAllCasks() async throws {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        _ = try await runCommand(brew, arguments: ["upgrade", "--cask", "--greedy"])
    }

    // MARK: - Cleanup

    /// Clean up old versions and cache
    func cleanup() async throws {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        _ = try await runCommand(brew, arguments: ["cleanup", "--prune=all"])
    }

    /// Get cleanup size estimate
    func getCleanupSize() async throws -> Int64 {
        guard let brew = brewPath() else {
            throw HomebrewError.notInstalled
        }

        let output = try await runCommand(brew, arguments: ["cleanup", "-n", "--prune=all"])

        // Parse output to estimate size
        var totalSize: Int64 = 0

        // Look for size patterns like "1.2GB" or "500MB"
        let regex = try? NSRegularExpression(pattern: "(\\d+\\.?\\d*)\\s*(GB|MB|KB)", options: .caseInsensitive)
        let range = NSRange(output.startIndex..<output.endIndex, in: output)

        regex?.enumerateMatches(in: output, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let valueRange = Range(match.range(at: 1), in: output),
                  let unitRange = Range(match.range(at: 2), in: output)
            else { return }

            let value = Double(output[valueRange]) ?? 0
            let unit = output[unitRange].uppercased()

            switch unit {
            case "GB": totalSize += Int64(value * 1_073_741_824)
            case "MB": totalSize += Int64(value * 1_048_576)
            case "KB": totalSize += Int64(value * 1024)
            default: break
            }
        }

        return totalSize
    }

    // MARK: - Helper

    private func runCommand(_ command: String, arguments: [String]) async throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        // Set PATH to include Homebrew
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "")
        process.environment = env

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - Errors

enum HomebrewError: LocalizedError {
    case notInstalled
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Homebrew is not installed. Visit https://brew.sh to install it."
        case .commandFailed(let message):
            return "Homebrew command failed: \(message)"
        }
    }
}
