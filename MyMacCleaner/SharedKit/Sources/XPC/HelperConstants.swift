import Foundation

/// Constants for XPC service configuration
public enum HelperConstants {
    /// The Mach service name for the privileged helper
    public static let machServiceName = "com.mymaccleaner.helper"

    /// The plist filename for the LaunchDaemon
    public static let daemonPlistName = "com.mymaccleaner.helper.plist"

    /// The Mach service name for the Sentinel (trash monitor)
    public static let sentinelServiceName = "com.mymaccleaner.sentinel"

    /// The plist filename for the Sentinel LaunchAgent
    public static let sentinelPlistName = "com.mymaccleaner.sentinel.plist"

    /// Bundle identifier for the main app
    public static let mainAppBundleId = "com.mymaccleaner.app"
}
