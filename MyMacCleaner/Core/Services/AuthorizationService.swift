import Foundation
import Security

/// Service that manages admin authorization, requesting it once and reusing for subsequent commands
actor AuthorizationService {
    static let shared = AuthorizationService()

    private var authRef: AuthorizationRef?
    private var isAuthorized = false

    private init() {}

    /// Request authorization from the user (shows password dialog once)
    func requestAuthorization() async -> Bool {
        // If already authorized, return true
        if isAuthorized && authRef != nil {
            return true
        }

        return await withCheckedContinuation { continuation in
            var auth: AuthorizationRef?

            // Create authorization reference
            let createStatus = AuthorizationCreate(nil, nil, [], &auth)
            guard createStatus == errAuthorizationSuccess, let authRef = auth else {
                continuation.resume(returning: false)
                return
            }

            // Define the right we need
            var rightName = "system.privilege.admin"
            let rightNameData = rightName.withCString { ptr in
                AuthorizationItem(name: ptr, valueLength: 0, value: nil, flags: 0)
            }

            var rights = withUnsafePointer(to: rightNameData) { ptr in
                AuthorizationRights(count: 1, items: UnsafeMutablePointer(mutating: ptr))
            }

            let flags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]

            // Request authorization (this shows the password dialog)
            let authStatus = AuthorizationCopyRights(authRef, &rights, nil, flags, nil)

            if authStatus == errAuthorizationSuccess {
                self.authRef = authRef
                self.isAuthorized = true
                continuation.resume(returning: true)
            } else {
                AuthorizationFree(authRef, [])
                continuation.resume(returning: false)
            }
        }
    }

    /// Run a command with the stored authorization
    func runAuthorizedCommand(_ command: String, arguments: [String] = []) async -> Bool {
        // First ensure we have authorization
        guard await requestAuthorization() else {
            return false
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Build the full command
                let fullCommand: String
                if arguments.isEmpty {
                    fullCommand = command
                } else {
                    let escapedArgs = arguments.map { arg in
                        "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'"
                    }.joined(separator: " ")
                    fullCommand = "\(command) \(escapedArgs)"
                }

                // Use AppleScript to run with admin privileges
                // The system caches the authorization after the first prompt
                let script = """
                do shell script "\(fullCommand)" with administrator privileges
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

    /// Run multiple commands with a single authorization request
    func runAuthorizedCommands(_ commands: [(command: String, arguments: [String])]) async -> [Bool] {
        // First ensure we have authorization
        guard await requestAuthorization() else {
            return commands.map { _ in false }
        }

        var results: [Bool] = []

        for (command, arguments) in commands {
            let result = await runAuthorizedCommand(command, arguments: arguments)
            results.append(result)
        }

        return results
    }

    /// Check if we currently have valid authorization
    func hasAuthorization() -> Bool {
        return isAuthorized && authRef != nil
    }

    /// Clear the stored authorization
    func clearAuthorization() {
        if let auth = authRef {
            AuthorizationFree(auth, [])
        }
        authRef = nil
        isAuthorized = false
    }
}
