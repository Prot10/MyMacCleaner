import SwiftUI
import IOKit
import IOKit.ps

// MARK: - System Health View Model

@MainActor
class SystemHealthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var healthScore: Int = 0
    @Published var healthStatus: HealthStatus = .unknown
    @Published var healthChecks: [HealthCheck] = []
    @Published var batteryInfo: BatteryInfo?
    @Published var diskInfo: [DiskInfo] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?

    enum HealthStatus: String {
        case excellent
        case good
        case fair
        case poor
        case unknown

        var localizedName: String {
            L(key: "systemHealth.status.\(rawValue)")
        }

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            case .unknown: return .gray
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "checkmark.seal.fill"
            case .good: return "checkmark.circle.fill"
            case .fair: return "exclamationmark.triangle.fill"
            case .poor: return "xmark.octagon.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }

    // MARK: - Initialization

    init() {
        runHealthCheck()
    }

    // MARK: - Public Methods

    func runHealthCheck() {
        isLoading = true
        healthChecks = []

        Task {
            // Run all health checks
            await checkDiskSpace()
            await checkMemoryPressure()
            await checkBattery()
            await checkDiskHealth()
            await checkStartupItems()
            await checkSystemUpdates()

            // Calculate overall score
            calculateHealthScore()

            lastUpdated = Date()
            isLoading = false
        }
    }

    // MARK: - Health Check Methods

    private func checkDiskSpace() async {
        let check = HealthCheck(
            id: "disk_space",
            title: L("systemHealth.check.diskSpace"),
            description: L("systemHealth.check.diskSpace.checking"),
            icon: "internaldrive.fill",
            status: .checking
        )
        healthChecks.append(check)

        // Get disk space
        let fileManager = FileManager.default
        if let homeURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
           let values = try? homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]) {

            let available = values.volumeAvailableCapacityForImportantUsage ?? 0
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let usedPercent = total > 0 ? Double(total - available) / Double(total) * 100 : 0

            let availableGB = Double(available) / 1_000_000_000
            let availableFormatted = String(format: "%.1f GB", availableGB)

            if availableGB > 50 {
                updateCheck(id: "disk_space", status: .passed, description: LFormat("systemHealth.check.diskSpace.passed %@", availableFormatted))
            } else if availableGB > 20 {
                updateCheck(id: "disk_space", status: .warning, description: LFormat("systemHealth.check.diskSpace.warning %@", availableFormatted))
            } else {
                updateCheck(id: "disk_space", status: .failed, description: LFormat("systemHealth.check.diskSpace.failed %@", availableFormatted))
            }

            // Store disk info
            let info = DiskInfo(
                name: "Macintosh HD",
                totalSpace: total,
                availableSpace: available,
                usedPercent: usedPercent
            )
            diskInfo = [info]
        } else {
            updateCheck(id: "disk_space", status: .failed, description: L("systemHealth.check.diskSpace.error"))
        }
    }

    private func checkMemoryPressure() async {
        let check = HealthCheck(
            id: "memory",
            title: L("systemHealth.check.memory"),
            description: L("systemHealth.check.memory.checking"),
            icon: "memorychip.fill",
            status: .checking
        )
        healthChecks.append(check)

        // Get memory info using host_statistics64
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let pageSize = UInt64(vm_page_size)
            let active = UInt64(stats.active_count) * pageSize
            // inactive is not used in calculation (excluded from "used" memory)
            _ = UInt64(stats.inactive_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize

            let used = active + wired + compressed
            let total = ProcessInfo.processInfo.physicalMemory
            let usedPercent = Double(used) / Double(total) * 100
            let percentFormatted = String(format: "%.0f%%", usedPercent)

            if usedPercent < 70 {
                updateCheck(id: "memory", status: .passed, description: LFormat("systemHealth.check.memory.passed %@", percentFormatted))
            } else if usedPercent < 85 {
                updateCheck(id: "memory", status: .warning, description: LFormat("systemHealth.check.memory.warning %@", percentFormatted))
            } else {
                updateCheck(id: "memory", status: .failed, description: LFormat("systemHealth.check.memory.failed %@", percentFormatted))
            }
        } else {
            updateCheck(id: "memory", status: .warning, description: L("systemHealth.check.memory.error"))
        }
    }

    private func checkBattery() async {
        let check = HealthCheck(
            id: "battery",
            title: L("systemHealth.check.battery"),
            description: L("systemHealth.check.battery.checking"),
            icon: "battery.100",
            status: .checking
        )
        healthChecks.append(check)

        // Check if this is a laptop
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array

        if sources.isEmpty {
            updateCheck(id: "battery", status: .passed, description: L("systemHealth.check.battery.desktop"))
            return
        }

        // Get battery info
        if let source = sources.first,
           let info = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {

            let currentCapacity = info[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maxCapacity = info[kIOPSMaxCapacityKey] as? Int ?? 100
            let isCharging = info[kIOPSIsChargingKey] as? Bool ?? false
            let cycleCount = info["BatteryCycleCount"] as? Int
            let health = info["BatteryHealth"] as? String

            let healthPercent = maxCapacity > 0 ? Double(currentCapacity) / Double(maxCapacity) * 100 : 0

            batteryInfo = BatteryInfo(
                percentage: Int(healthPercent),
                isCharging: isCharging,
                cycleCount: cycleCount,
                health: health ?? "Normal",
                maxCapacity: maxCapacity
            )

            if health == "Good" || health == "Normal" {
                updateCheck(id: "battery", status: .passed, description: LFormat("systemHealth.check.battery.passed %@", health ?? "Good"))
            } else if health == "Fair" {
                updateCheck(id: "battery", status: .warning, description: L("systemHealth.check.battery.warning"))
            } else {
                updateCheck(id: "battery", status: .failed, description: L("systemHealth.check.battery.failed"))
            }
        } else {
            updateCheck(id: "battery", status: .warning, description: L("systemHealth.check.battery.error"))
        }
    }

    private func checkDiskHealth() async {
        let check = HealthCheck(
            id: "disk_health",
            title: L("systemHealth.check.diskHealth"),
            description: L("systemHealth.check.diskHealth.checking"),
            icon: "externaldrive.fill",
            status: .checking
        )
        healthChecks.append(check)

        // Run diskutil to check SMART status
        let result = await runCommand("/usr/sbin/diskutil", arguments: ["info", "/"])

        if result.contains("SMART Status") {
            if result.contains("Verified") {
                updateCheck(id: "disk_health", status: .passed, description: L("systemHealth.check.diskHealth.verified"))
            } else if result.contains("Not Supported") {
                updateCheck(id: "disk_health", status: .passed, description: L("systemHealth.check.diskHealth.ssd"))
            } else {
                updateCheck(id: "disk_health", status: .warning, description: L("systemHealth.check.diskHealth.unknown"))
            }
        } else {
            updateCheck(id: "disk_health", status: .passed, description: L("systemHealth.check.diskHealth.healthy"))
        }
    }

    private func checkStartupItems() async {
        let check = HealthCheck(
            id: "startup",
            title: L("systemHealth.check.startup"),
            description: L("systemHealth.check.startup.checking"),
            icon: "power",
            status: .checking
        )
        healthChecks.append(check)

        // Check launch agents
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentsPath = homeDir.appendingPathComponent("Library/LaunchAgents")

        var itemCount = 0
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: launchAgentsPath.path) {
            itemCount = contents.filter { $0.hasSuffix(".plist") }.count
        }

        if itemCount < 10 {
            updateCheck(id: "startup", status: .passed, description: LFormat("systemHealth.check.startup.passed %lld", itemCount))
        } else if itemCount < 20 {
            updateCheck(id: "startup", status: .warning, description: LFormat("systemHealth.check.startup.warning %lld", itemCount))
        } else {
            updateCheck(id: "startup", status: .failed, description: LFormat("systemHealth.check.startup.failed %lld", itemCount))
        }
    }

    private func checkSystemUpdates() async {
        let check = HealthCheck(
            id: "updates",
            title: L("systemHealth.check.updates"),
            description: L("systemHealth.check.updates.checking"),
            icon: "arrow.down.circle.fill",
            status: .checking
        )
        healthChecks.append(check)

        // Check macOS version
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        // For simplicity, we'll just report the current version
        // A full implementation would check software update
        if version.majorVersion >= 14 {
            updateCheck(id: "updates", status: .passed, description: LFormat("systemHealth.check.updates.passed %@", versionString))
        } else if version.majorVersion >= 13 {
            updateCheck(id: "updates", status: .warning, description: LFormat("systemHealth.check.updates.warning %@", versionString))
        } else {
            updateCheck(id: "updates", status: .failed, description: LFormat("systemHealth.check.updates.failed %@", versionString))
        }
    }

    // MARK: - Helper Methods

    private func updateCheck(id: String, status: HealthCheck.Status, description: String) {
        if let index = healthChecks.firstIndex(where: { $0.id == id }) {
            healthChecks[index].status = status
            healthChecks[index].description = description
        }
    }

    private func calculateHealthScore() {
        let passedCount = healthChecks.filter { $0.status == .passed }.count
        let warningCount = healthChecks.filter { $0.status == .warning }.count
        let totalChecks = healthChecks.count

        guard totalChecks > 0 else {
            healthScore = 0
            healthStatus = .unknown
            return
        }

        // Calculate score: passed = 100%, warning = 50%, failed = 0%
        let score = (passedCount * 100 + warningCount * 50) / totalChecks
        healthScore = score

        if score >= 90 {
            healthStatus = .excellent
        } else if score >= 70 {
            healthStatus = .good
        } else if score >= 50 {
            healthStatus = .fair
        } else {
            healthStatus = .poor
        }
    }

    private func runCommand(_ command: String, arguments: [String]) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: command)
                process.arguments = arguments

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
}

// MARK: - Health Check Model

struct HealthCheck: Identifiable {
    let id: String
    var title: String
    var description: String
    var icon: String
    var status: Status

    enum Status {
        case checking
        case passed
        case warning
        case failed

        var color: Color {
            switch self {
            case .checking: return .gray
            case .passed: return .green
            case .warning: return .orange
            case .failed: return .red
            }
        }

        var icon: String {
            switch self {
            case .checking: return "ellipsis.circle"
            case .passed: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Battery Info Model

struct BatteryInfo {
    let percentage: Int
    let isCharging: Bool
    let cycleCount: Int?
    let health: String
    let maxCapacity: Int
}

// MARK: - Disk Info Model

struct DiskInfo: Identifiable {
    let id = UUID()
    let name: String
    let totalSpace: Int64
    let availableSpace: Int64
    let usedPercent: Double

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: totalSpace - availableSpace, countStyle: .file)
    }
}
