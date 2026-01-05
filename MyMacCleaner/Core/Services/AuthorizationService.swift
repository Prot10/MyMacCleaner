import Foundation
import Security

/// Service that manages admin authorization with a SINGLE password prompt
/// Uses AppleScript's "do shell script with administrator privileges" for secure elevation
final class AuthorizationService {
    static let shared = AuthorizationService()

    private init() {}

    /// Run a single command with admin privileges
    func runAuthorizedCommand(_ command: String, arguments: [String] = []) async -> Bool {
        // Build the full command
        let fullCommand: String
        if arguments.isEmpty {
            fullCommand = command
        } else {
            let escapedArgs = arguments.map { escapeForShell($0) }.joined(separator: " ")
            fullCommand = "\(command) \(escapedArgs)"
        }

        return await runWithAdminPrivileges(fullCommand)
    }

    /// Run multiple commands with a SINGLE password prompt
    func runBatchCommands(_ commands: [(command: String, arguments: [String])]) async -> [Bool] {
        guard !commands.isEmpty else { return [] }

        // Build all commands into a single script
        var scriptCommands: [String] = []
        for (command, arguments) in commands {
            if arguments.isEmpty {
                scriptCommands.append(command)
            } else {
                let escapedArgs = arguments.map { escapeForShell($0) }.joined(separator: " ")
                scriptCommands.append("\(command) \(escapedArgs)")
            }
        }

        // Join with ; and track exit codes
        // We'll run each command and collect results
        let combinedScript = scriptCommands.enumerated().map { index, cmd in
            "\(cmd); echo \"CMD_\(index)_EXIT:$?\""
        }.joined(separator: "; ")

        let result = await runWithAdminPrivilegesAndCapture(combinedScript)

        // Parse results
        var results: [Bool] = Array(repeating: false, count: commands.count)
        if let output = result {
            for index in 0..<commands.count {
                if output.contains("CMD_\(index)_EXIT:0") {
                    results[index] = true
                }
            }
        }

        return results
    }

    /// Request authorization upfront (for UI feedback)
    func requestAuthorization() async -> Bool {
        // Just verify we can run a simple command
        return await runWithAdminPrivileges("/usr/bin/true")
    }

    // MARK: - Private Methods

    private func runWithAdminPrivileges(_ command: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let script = """
                do shell script "\(self.escapeForAppleScript(command))" with administrator privileges
                """

                var error: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    appleScript.executeAndReturnError(&error)
                    continuation.resume(returning: error == nil)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func runWithAdminPrivilegesAndCapture(_ command: String) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let script = """
                do shell script "\(self.escapeForAppleScript(command))" with administrator privileges
                """

                var error: NSDictionary?
                if let appleScript = NSAppleScript(source: script) {
                    let result = appleScript.executeAndReturnError(&error)
                    if error == nil {
                        continuation.resume(returning: result.stringValue)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func escapeForShell(_ string: String) -> String {
        // Escape single quotes for shell
        return "'" + string.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escape a string for safe inclusion in AppleScript's "do shell script"
    /// This prevents command injection by properly escaping all special characters
    private func escapeForAppleScript(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count + 10)

        for char in string {
            switch char {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "\t":
                result += "\\t"
            default:
                // Check for other control characters (ASCII 0-31 except those handled above)
                if let ascii = char.asciiValue, ascii < 32 {
                    // Skip control characters that could be malicious
                    continue
                }
                result.append(char)
            }
        }

        return result
    }
}
