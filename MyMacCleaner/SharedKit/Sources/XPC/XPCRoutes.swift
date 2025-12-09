import Foundation

/// XPC route definitions for communication with the privileged helper
/// Note: SecureXPC will be added later for production use
public enum HelperRoutes {
    // Route names for XPC communication
    public static let deleteFiles = "deleteFiles"
    public static let validatePaths = "validatePaths"
    public static let purgeMemory = "purgeMemory"
    public static let getSystemInfo = "getSystemInfo"
    public static let manageLaunchItem = "manageLaunchItem"
    public static let getHelperStatus = "getHelperStatus"
}
