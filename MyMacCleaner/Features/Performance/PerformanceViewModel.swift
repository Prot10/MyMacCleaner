import SwiftUI
import Combine

// MARK: - Performance View Model

@MainActor
class PerformanceViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var cpuUsage: Double = 0
    @Published var isMonitoring = false

    @Published var maintenanceTasks: [MaintenanceTask] = MaintenanceTask.allTasks
    @Published var runningTaskId: String?
    @Published var taskProgress: Double = 0

    // Run All state
    @Published var isRunningAll = false
    @Published var runAllCurrentIndex = 0
    @Published var runAllTotalCount = 0
    @Published var taskResults: [String: TaskResult] = [:]

    enum TaskResult {
        case pending
        case running
        case success
        case failed
        case skipped
    }

    // Process monitoring
    @Published var topProcesses: [RunningProcess] = []
    @Published var isLoadingProcesses = false
    private var processTimer: Timer?

    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    enum ToastType {
        case success, error, info
    }

    // MARK: - Private Properties

    private var monitorTimer: Timer?
    private var cpuInfo: processor_info_array_t?
    private var prevCpuInfo: processor_info_array_t?
    private var numCpuInfo: mach_msg_type_number_t = 0
    private var numPrevCpuInfo: mach_msg_type_number_t = 0
    private var numCPUs: uint = 0

    // MARK: - Initialization

    init() {
        var numCPUsU: natural_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        if result == KERN_SUCCESS {
            numCPUs = uint(numCPUsU)
        }
        startMonitoring()
    }

    deinit {
        monitorTimer?.invalidate()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        updateMemoryUsage()
        updateCPUUsage()

        monitorTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
                self?.updateCPUUsage()
            }
        }
    }

    func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
        isMonitoring = false
    }

    private func updateMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)

        let active = UInt64(stats.active_count) * pageSize
        let inactive = UInt64(stats.inactive_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let purgeable = UInt64(stats.purgeable_count) * pageSize
        let speculative = UInt64(stats.speculative_count) * pageSize

        // Get actual physical memory
        let total = ProcessInfo.processInfo.physicalMemory

        // "Used" like htop: Active + Wired (what's actually in use)
        // Compressed is part of the physical used space
        let appMemory = active + wired + compressed

        // Free = Total - (Active + Inactive + Wired + Compressed + Speculative)
        let accountedFor = active + inactive + wired + compressed + speculative
        let free = total > accountedFor ? total - accountedFor : 0

        // Get swap info
        let swapInfo = getSwapUsage()

        memoryUsage = MemoryUsage(
            total: total,
            used: appMemory,
            free: free,
            active: active,
            inactive: inactive,
            wired: wired,
            compressed: compressed,
            purgeable: purgeable,
            swapUsed: swapInfo.used,
            swapTotal: swapInfo.total
        )
    }

    private func getSwapUsage() -> (used: UInt64, total: UInt64) {
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size

        let result = sysctlbyname("vm.swapusage", &swapUsage, &size, nil, 0)

        if result == 0 {
            return (used: swapUsage.xsu_used, total: swapUsage.xsu_total)
        }
        return (used: 0, total: 0)
    }

    private func updateCPUUsage() {
        var numCPUsU: natural_t = 0
        var newInfo: processor_info_array_t?
        var numInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &newInfo, &numInfo)

        guard result == KERN_SUCCESS, let newInfo = newInfo else { return }

        var totalUsage: Double = 0

        if let prevInfo = prevCpuInfo {
            for i in 0..<Int(numCPUs) {
                let offset = Int32(CPU_STATE_MAX) * Int32(i)

                let userDiff = Double(newInfo[Int(offset + CPU_STATE_USER)]) - Double(prevInfo[Int(offset + CPU_STATE_USER)])
                let systemDiff = Double(newInfo[Int(offset + CPU_STATE_SYSTEM)]) - Double(prevInfo[Int(offset + CPU_STATE_SYSTEM)])
                let niceDiff = Double(newInfo[Int(offset + CPU_STATE_NICE)]) - Double(prevInfo[Int(offset + CPU_STATE_NICE)])
                let idleDiff = Double(newInfo[Int(offset + CPU_STATE_IDLE)]) - Double(prevInfo[Int(offset + CPU_STATE_IDLE)])

                let total = userDiff + systemDiff + niceDiff + idleDiff
                if total > 0 {
                    totalUsage += (userDiff + systemDiff + niceDiff) / total
                }
            }

            cpuUsage = (totalUsage / Double(numCPUs)) * 100

            let prevSize = vm_size_t(numPrevCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevInfo), prevSize)
        }

        prevCpuInfo = newInfo
        numPrevCpuInfo = numInfo
    }

    // MARK: - Maintenance Tasks

    func runTask(_ task: MaintenanceTask) {
        guard runningTaskId == nil && !isRunningAll else { return }

        runningTaskId = task.id
        taskProgress = 0
        taskResults[task.id] = .running

        Task {
            do {
                for i in 1...10 {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    taskProgress = Double(i) / 10.0
                }

                let success = await executeTask(task)

                runningTaskId = nil
                taskProgress = 0
                taskResults[task.id] = success ? .success : .failed

                if success {
                    showToastMessage("\(task.name) completed successfully", type: .success)
                } else {
                    if task.requiresAdmin {
                        showToastMessage("\(task.name) was cancelled", type: .info)
                    } else {
                        showToastMessage("\(task.name) failed", type: .error)
                    }
                }

            } catch {
                runningTaskId = nil
                taskProgress = 0
                taskResults[task.id] = .failed
                showToastMessage("Failed: \(error.localizedDescription)", type: .error)
            }
        }
    }

    func runAllTasks() {
        guard !isRunningAll && runningTaskId == nil else { return }

        isRunningAll = true
        runAllCurrentIndex = 0
        runAllTotalCount = maintenanceTasks.count

        // Reset all task results
        for task in maintenanceTasks {
            taskResults[task.id] = .pending
        }

        Task {
            // Separate admin and non-admin tasks
            let adminTasks = maintenanceTasks.filter { $0.requiresAdmin }
            let nonAdminTasks = maintenanceTasks.filter { !$0.requiresAdmin }

            // Build batch of admin commands
            var adminCommands: [(command: String, arguments: [String])] = []
            for task in adminTasks {
                if let cmd = getCommandForTask(task) {
                    adminCommands.append(cmd)
                }
            }

            // Run all admin tasks in ONE batch (single password prompt)
            var adminResults: [Bool] = []
            if !adminCommands.isEmpty {
                // Show first admin task as running
                if let firstAdmin = adminTasks.first {
                    runAllCurrentIndex = maintenanceTasks.firstIndex(where: { $0.id == firstAdmin.id })! + 1
                    runningTaskId = firstAdmin.id
                    taskResults[firstAdmin.id] = .running
                }

                // Run batch with SINGLE password prompt
                adminResults = await AuthorizationService.shared.runBatchCommands(adminCommands)

                // Update results for admin tasks
                for (index, task) in adminTasks.enumerated() {
                    let success = index < adminResults.count ? adminResults[index] : false
                    taskResults[task.id] = success ? .success : .failed
                }
            }

            // Now run non-admin tasks individually with progress
            for task in nonAdminTasks {
                guard isRunningAll else {
                    taskResults[task.id] = .skipped
                    continue
                }

                runAllCurrentIndex = maintenanceTasks.firstIndex(where: { $0.id == task.id })! + 1
                runningTaskId = task.id
                taskProgress = 0
                taskResults[task.id] = .running

                // Animate progress
                for i in 1...10 {
                    try? await Task.sleep(nanoseconds: 80_000_000)
                    taskProgress = Double(i) / 10.0
                }

                let success = await executeTask(task)
                taskResults[task.id] = success ? .success : .failed

                taskProgress = 0
                runningTaskId = nil

                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            isRunningAll = false
            runAllCurrentIndex = 0
            runningTaskId = nil

            // Count results
            let successCount = taskResults.values.filter { $0 == .success }.count
            let failedCount = taskResults.values.filter { $0 == .failed }.count

            // Show summary toast
            if failedCount == 0 {
                showToastMessage("All \(successCount) tasks completed successfully!", type: .success)
            } else {
                showToastMessage("\(successCount) succeeded, \(failedCount) failed or cancelled", type: .info)
            }

            // Clear results after a delay
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            taskResults.removeAll()
        }
    }

    /// Get the command and arguments for a task
    private func getCommandForTask(_ task: MaintenanceTask) -> (command: String, arguments: [String])? {
        switch task.id {
        case "purge_ram":
            return ("/usr/sbin/purge", [])
        case "flush_dns":
            return ("/usr/bin/dscacheutil", ["-flushcache"])
        case "kill_dns":
            return ("/usr/bin/killall", ["-HUP", "mDNSResponder"])
        case "clear_font_cache":
            return ("/usr/bin/atsutil", ["databases", "-remove"])
        case "rebuild_spotlight":
            return ("/usr/bin/mdutil", ["-E", "/"])
        case "rebuild_launch":
            // Note: -kill was removed in recent macOS. Using -gc (garbage collect) instead
            return ("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", ["-gc"])
        case "clear_quicklook":
            return ("/usr/bin/qlmanage", ["-r", "cache"])
        case "verify_disk":
            return ("/usr/sbin/diskutil", ["verifyVolume", "/"])
        default:
            return nil
        }
    }

    func cancelRunAll() {
        // This will stop after the current task completes
        isRunningAll = false
    }

    // MARK: - Process Management

    func startProcessMonitoring() {
        // Initial fetch
        refreshProcesses()

        // Auto-refresh every 2 seconds
        processTimer?.invalidate()
        processTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshProcesses()
            }
        }
    }

    func stopProcessMonitoring() {
        processTimer?.invalidate()
        processTimer = nil
    }

    func refreshProcesses() {
        // Don't show loading indicator for auto-refresh
        let isFirstLoad = topProcesses.isEmpty
        if isFirstLoad {
            isLoadingProcesses = true
        }

        Task {
            let processes = await getTopProcesses()
            await MainActor.run {
                self.topProcesses = processes
                self.isLoadingProcesses = false
            }
        }
    }

    func killProcess(_ process: RunningProcess) {
        Task {
            let success = await runCommand("/bin/kill", arguments: ["-9", "\(process.pid)"])

            if success {
                showToastMessage("Killed \(process.name)", type: .success)
            } else {
                // Try with sudo
                let sudoSuccess = await runCommand("/bin/kill", arguments: ["-9", "\(process.pid)"], requiresAdmin: true)
                if sudoSuccess {
                    showToastMessage("Killed \(process.name)", type: .success)
                } else {
                    showToastMessage("Failed to kill \(process.name)", type: .error)
                }
            }
        }
    }

    private func getTopProcesses() async -> [RunningProcess] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Use ps with awk to properly parse and format output
                // This extracts just the executable name from full paths
                let script = """
                ps -axo pid,rss,%cpu,user,comm | tail -n +2 | sort -k2 -rn | head -10 | awk '{
                  pid=$1; rss=$2; cpu=$3; user=$4;
                  path=""; for(i=5;i<=NF;i++) path = path (i>5 ? " " : "") $i;
                  n = split(path, parts, "/");
                  name = parts[n];
                  gsub(/\\.app.*/, "", name);
                  if (name == "") name = path;
                  printf "%d\\t%d\\t%.1f\\t%s\\t%s\\n", pid, rss, cpu, user, name
                }'
                """

                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/bash")
                task.arguments = ["-c", script]

                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = FileHandle.nullDevice

                do {
                    try task.run()
                    task.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let output = String(data: data, encoding: .utf8) else {
                        continuation.resume(returning: [])
                        return
                    }

                    var processes: [RunningProcess] = []
                    let lines = output.components(separatedBy: "\n")

                    for line in lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { continue }

                        // Split by tab
                        let components = trimmed.components(separatedBy: "\t")
                        guard components.count >= 5 else { continue }

                        let pid = Int(components[0]) ?? 0
                        let rssKB = Int(components[1]) ?? 0
                        let cpuPercent = Double(components[2]) ?? 0
                        let user = components[3]
                        let command = components[4]

                        guard pid > 0, rssKB > 0 else { continue }

                        let runningProcess = RunningProcess(
                            pid: pid,
                            name: command,
                            user: user,
                            cpuPercent: cpuPercent,
                            memoryPercent: 0,
                            memoryKB: rssKB
                        )
                        processes.append(runningProcess)
                    }

                    continuation.resume(returning: processes)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    private func parseMemoryString(_ str: String) -> Int {
        // Remove whitespace and + suffix, convert to uppercase
        var cleanStr = str.trimmingCharacters(in: .whitespaces).uppercased()
        cleanStr = cleanStr.replacingOccurrences(of: "+", with: "")
        cleanStr = cleanStr.replacingOccurrences(of: "-", with: "")

        if cleanStr.hasSuffix("G") || cleanStr.hasSuffix("GB") {
            let numStr = cleanStr.replacingOccurrences(of: "GB", with: "").replacingOccurrences(of: "G", with: "")
            let num = Double(numStr) ?? 0
            return Int(num * 1024 * 1024) // GB to KB
        } else if cleanStr.hasSuffix("M") || cleanStr.hasSuffix("MB") {
            let numStr = cleanStr.replacingOccurrences(of: "MB", with: "").replacingOccurrences(of: "M", with: "")
            let num = Double(numStr) ?? 0
            return Int(num * 1024) // MB to KB
        } else if cleanStr.hasSuffix("K") || cleanStr.hasSuffix("KB") {
            let numStr = cleanStr.replacingOccurrences(of: "KB", with: "").replacingOccurrences(of: "K", with: "")
            let num = Double(numStr) ?? 0
            return Int(num) // Already KB
        } else if cleanStr.hasSuffix("B") {
            let numStr = cleanStr.replacingOccurrences(of: "B", with: "")
            let num = Double(numStr) ?? 0
            return Int(num / 1024) // Bytes to KB
        } else {
            // Assume bytes if no suffix
            return Int((Double(cleanStr) ?? 0) / 1024)
        }
    }

    private func executeTask(_ task: MaintenanceTask) async -> Bool {
        switch task.id {
        case "purge_ram":
            // purge is in /usr/sbin, not /usr/bin
            return await runCommand("/usr/sbin/purge", requiresAdmin: true)
        case "flush_dns":
            return await runCommand("/usr/bin/dscacheutil", arguments: ["-flushcache"])
        case "kill_dns":
            return await runCommand("/usr/bin/killall", arguments: ["-HUP", "mDNSResponder"], requiresAdmin: true)
        case "clear_font_cache":
            return await runCommand("/usr/bin/atsutil", arguments: ["databases", "-remove"])
        case "rebuild_spotlight":
            return await runCommand("/usr/bin/mdutil", arguments: ["-E", "/"], requiresAdmin: true)
        case "rebuild_launch":
            // Note: -kill was removed in recent macOS. Using -gc (garbage collect) instead
            return await runCommand("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", arguments: ["-gc"])
        case "clear_quicklook":
            return await runCommand("/usr/bin/qlmanage", arguments: ["-r", "cache"])
        case "verify_disk":
            return await runCommand("/usr/sbin/diskutil", arguments: ["verifyVolume", "/"], requiresAdmin: true)
        default:
            return false
        }
    }

    private func runCommand(_ path: String, arguments: [String] = [], requiresAdmin: Bool = false) async -> Bool {
        if requiresAdmin {
            // Use the shared authorization service (prompts once, caches authorization)
            return await AuthorizationService.shared.runAuthorizedCommand(path, arguments: arguments)
        } else {
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: path)
                    process.arguments = arguments
                    process.standardOutput = FileHandle.nullDevice
                    process.standardError = FileHandle.nullDevice

                    do {
                        try process.run()
                        process.waitUntilExit()
                        continuation.resume(returning: process.terminationStatus == 0)
                    } catch {
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    private func showToastMessage(_ message: String, type: ToastType) {
        toastMessage = message
        toastType = type
        showToast = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showToast = false
        }
    }

    func dismissToast() {
        showToast = false
    }
}

// MARK: - Memory Usage Model

struct MemoryUsage {
    var total: UInt64 = 0
    var used: UInt64 = 0       // Active + Wired + Compressed (app memory)
    var free: UInt64 = 0
    var active: UInt64 = 0     // Currently in use
    var inactive: UInt64 = 0   // Cached, can be reclaimed
    var wired: UInt64 = 0      // Cannot be paged out
    var compressed: UInt64 = 0 // Compressed in RAM
    var purgeable: UInt64 = 0  // Can be purged if needed
    var swapUsed: UInt64 = 0
    var swapTotal: UInt64 = 0

    var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }

    var formattedFree: String {
        ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
    }

    var formattedActive: String {
        ByteCountFormatter.string(fromByteCount: Int64(active), countStyle: .memory)
    }

    var formattedInactive: String {
        ByteCountFormatter.string(fromByteCount: Int64(inactive), countStyle: .memory)
    }

    var formattedWired: String {
        ByteCountFormatter.string(fromByteCount: Int64(wired), countStyle: .memory)
    }

    var formattedCompressed: String {
        ByteCountFormatter.string(fromByteCount: Int64(compressed), countStyle: .memory)
    }

    var formattedSwapUsed: String {
        ByteCountFormatter.string(fromByteCount: Int64(swapUsed), countStyle: .memory)
    }

    var formattedSwapTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(swapTotal), countStyle: .memory)
    }

    var hasSwap: Bool {
        swapTotal > 0
    }
}

// MARK: - Maintenance Task Model

struct MaintenanceTask: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let requiresAdmin: Bool

    static let allTasks: [MaintenanceTask] = [
        MaintenanceTask(
            id: "purge_ram",
            name: "Purge Disk Cache",
            description: "Clear filesystem cache to free memory",
            icon: "memorychip",
            color: .blue,
            requiresAdmin: true
        ),
        MaintenanceTask(
            id: "flush_dns",
            name: "Flush DNS Cache",
            description: "Clear the DNS cache to fix network issues",
            icon: "network",
            color: .green,
            requiresAdmin: false
        ),
        MaintenanceTask(
            id: "kill_dns",
            name: "Restart DNS Service",
            description: "Restart the mDNSResponder service",
            icon: "arrow.clockwise",
            color: .orange,
            requiresAdmin: true
        ),
        MaintenanceTask(
            id: "clear_font_cache",
            name: "Clear Font Cache",
            description: "Remove cached font data to fix font issues",
            icon: "textformat",
            color: .purple,
            requiresAdmin: false
        ),
        MaintenanceTask(
            id: "rebuild_spotlight",
            name: "Rebuild Spotlight Index",
            description: "Recreate the Spotlight search index",
            icon: "magnifyingglass",
            color: .pink,
            requiresAdmin: true
        ),
        MaintenanceTask(
            id: "rebuild_launch",
            name: "Rebuild Launch Services",
            description: "Clean up and refresh app associations database",
            icon: "square.grid.2x2",
            color: .cyan,
            requiresAdmin: false
        ),
        MaintenanceTask(
            id: "clear_quicklook",
            name: "Clear QuickLook Cache",
            description: "Reset QuickLook preview cache",
            icon: "eye",
            color: .indigo,
            requiresAdmin: false
        ),
        MaintenanceTask(
            id: "verify_disk",
            name: "Verify Disk",
            description: "Check disk for errors",
            icon: "internaldrive",
            color: .red,
            requiresAdmin: true
        )
    ]
}

// MARK: - Running Process Model

struct RunningProcess: Identifiable {
    let id = UUID()
    let pid: Int
    let name: String
    let user: String
    let cpuPercent: Double
    let memoryPercent: Double
    let memoryKB: Int

    var memoryMB: Double {
        Double(memoryKB) / 1024.0
    }

    var formattedMemory: String {
        if memoryMB >= 1024 {
            return String(format: "%.1f GB", memoryMB / 1024.0)
        } else {
            return String(format: "%.0f MB", memoryMB)
        }
    }
}
