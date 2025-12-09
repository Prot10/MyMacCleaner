import Foundation

/// Validates paths to prevent deletion of system-critical files
/// CRITICAL: This must be used before ANY file deletion operation
public final class PathValidator: Sendable {

    /// Result of path validation
    public enum ValidationResult: Sendable {
        case safe
        case protectedPath(String)
        case outsideAllowedPaths
        case symlinkToProtected
        case pathTraversal
        case doesNotExist
        case invalidPath

        public var isValid: Bool {
            if case .safe = self { return true }
            return false
        }

        public var reason: String {
            switch self {
            case .safe:
                return "Path is safe to delete"
            case .protectedPath(let path):
                return "Protected system path: \(path)"
            case .outsideAllowedPaths:
                return "Path is outside allowed deletion directories"
            case .symlinkToProtected:
                return "Symlink points to a protected location"
            case .pathTraversal:
                return "Path contains traversal sequences (..)"
            case .doesNotExist:
                return "Path does not exist"
            case .invalidPath:
                return "Invalid or malformed path"
            }
        }
    }

    // MARK: - Protected Paths (NEVER delete these)

    private static let protectedPaths: Set<String> = [
        "/",
        "/System",
        "/Library",
        "/Users",
        "/Applications",
        "/bin",
        "/sbin",
        "/usr",
        "/var",
        "/private",
        "/etc",
        "/tmp",
        "/cores",
        "/dev",
        "/opt",
        "/Volumes",
        NSHomeDirectory(),
    ]

    /// Specific protected paths within home directory
    private static let protectedHomePaths: [String] = [
        "/Desktop",
        "/Documents",
        "/Downloads",
        "/Movies",
        "/Music",
        "/Pictures",
        "/Public",
    ]

    // MARK: - Allowed Base Paths (deletion only permitted within these)

    private static func allowedBasePaths() -> Set<String> {
        let home = NSHomeDirectory()
        return [
            // User Library paths
            "\(home)/Library/Caches",
            "\(home)/Library/Logs",
            "\(home)/Library/Application Support",
            "\(home)/Library/Containers",
            "\(home)/Library/Saved Application State",
            "\(home)/Library/Cookies",
            "\(home)/Library/HTTPStorages",
            "\(home)/Library/WebKit",
            "\(home)/Library/Preferences",
            "\(home)/Library/Group Containers",
            "\(home)/Library/Application Scripts",
            "\(home)/.Trash",

            // Developer paths
            "\(home)/Library/Developer/Xcode/DerivedData",
            "\(home)/Library/Developer/Xcode/Archives",
            "\(home)/Library/Developer/Xcode/iOS DeviceSupport",
            "\(home)/Library/Developer/CoreSimulator",

            // Package manager caches
            "\(home)/.npm",
            "\(home)/.cache",
            "\(home)/.local/share/Trash",

            // System Library (requires root)
            "/Library/Caches",
            "/Library/Logs",
            "/Library/LaunchAgents",
            "/Library/LaunchDaemons",
            "/Library/Application Support",
            "/private/var/folders",
        ]
    }

    // MARK: - Validation

    /// Validates a single path for safe deletion
    public static func validate(_ path: String) -> ValidationResult {
        // Check for empty or whitespace-only paths
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else {
            return .invalidPath
        }

        // Normalize path (resolve ~, .., symlinks for checking)
        let normalizedPath = (trimmedPath as NSString).standardizingPath

        // Check for path traversal attempts
        if trimmedPath.contains("..") {
            return .pathTraversal
        }

        // Check against absolute protected paths
        for protected in protectedPaths {
            if normalizedPath == protected {
                return .protectedPath(protected)
            }
        }

        // Check protected home subdirectories
        let home = NSHomeDirectory()
        for subpath in protectedHomePaths {
            let protectedPath = home + subpath
            if normalizedPath == protectedPath {
                return .protectedPath(protectedPath)
            }
        }

        // Verify path is within allowed base paths
        let allowed = allowedBasePaths()
        var isWithinAllowed = false

        for allowedBase in allowed {
            // Path must be within the allowed directory (not the directory itself)
            if normalizedPath.hasPrefix(allowedBase + "/") {
                isWithinAllowed = true
                break
            }
            // Also allow the base path itself if it's a specific cache folder
            if normalizedPath == allowedBase && (
                normalizedPath.contains("/Caches/") ||
                normalizedPath.contains("/DerivedData/") ||
                normalizedPath.contains("/.Trash/")
            ) {
                isWithinAllowed = true
                break
            }
        }

        if !isWithinAllowed {
            return .outsideAllowedPaths
        }

        // Check for symlinks pointing to protected locations
        let fm = FileManager.default
        if let destination = try? fm.destinationOfSymbolicLink(atPath: normalizedPath) {
            let resolvedDest = (destination as NSString).standardizingPath
            for protected in protectedPaths {
                // Allow symlinks within Caches subdirectories
                if resolvedDest.hasPrefix(protected) &&
                   !resolvedDest.contains("/Caches/") &&
                   !resolvedDest.contains("/.Trash/") {
                    return .symlinkToProtected
                }
            }
        }

        return .safe
    }

    /// Validates multiple paths and returns results for each
    public static func validateBatch(_ paths: [String]) -> [(path: String, result: ValidationResult)] {
        return paths.map { ($0, validate($0)) }
    }

    /// Filters paths to only include safe ones
    public static func filterSafePaths(_ paths: [String]) -> [String] {
        return paths.filter { validate($0).isValid }
    }

    /// Checks if a path exists
    public static func pathExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    /// Gets the size of a file or directory in bytes
    public static func getSize(at path: String) throws -> Int64 {
        let fm = FileManager.default
        var isDirectory: ObjCBool = false

        guard fm.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw PathValidatorError.pathDoesNotExist
        }

        if isDirectory.boolValue {
            return try getDirectorySize(at: path)
        } else {
            let attrs = try fm.attributesOfItem(atPath: path)
            return attrs[.size] as? Int64 ?? 0
        }
    }

    private static func getDirectorySize(at path: String) throws -> Int64 {
        let fm = FileManager.default
        var totalSize: Int64 = 0

        guard let enumerator = fm.enumerator(atPath: path) else {
            throw PathValidatorError.cannotEnumerateDirectory
        }

        for case let file as String in enumerator {
            let filePath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: filePath),
               let size = attrs[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }
}

// MARK: - Errors

public enum PathValidatorError: Error, LocalizedError {
    case pathDoesNotExist
    case cannotEnumerateDirectory
    case invalidPath

    public var errorDescription: String? {
        switch self {
        case .pathDoesNotExist:
            return "The specified path does not exist"
        case .cannotEnumerateDirectory:
            return "Cannot enumerate the directory contents"
        case .invalidPath:
            return "The specified path is invalid"
        }
    }
}
