import Foundation
import Darwin

// MARK: - System Stats

struct SystemStats {
    var cpuUsage: Double = 0
    var memoryUsed: UInt64 = 0
    var memoryTotal: UInt64 = 0
    var memoryPressure: Double = 0

    var formattedCPU: String {
        "\(Int(cpuUsage))%"
    }

    var formattedMemory: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsed), countStyle: .memory)
    }

    var formattedMemoryTotal: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryTotal), countStyle: .memory)
    }

    var memoryUsagePercent: Double {
        guard memoryTotal > 0 else { return 0 }
        return Double(memoryUsed) / Double(memoryTotal) * 100
    }
}

// MARK: - System Stats Provider

/// Thread-safe system stats provider for menu bar and other displays
class SystemStatsProvider: ObservableObject {
    static let shared = SystemStatsProvider()

    @Published var stats = SystemStats()
    @Published var isMonitoring = false

    private var timer: Timer?
    private var cpuInfo: processor_info_array_t?
    private var prevCpuInfo: processor_info_array_t?
    private var numCpuInfo: mach_msg_type_number_t = 0
    private var numPrevCpuInfo: mach_msg_type_number_t = 0
    private var numCPUs: UInt32 = 0

    private let queue = DispatchQueue(label: "com.mymaccleaner.stats", qos: .utility)

    private init() {
        // Initialize CPU info
        var numCPUsU: natural_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCpuInfo)
        if result == KERN_SUCCESS {
            numCPUs = numCPUsU
        }
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Monitoring Control

    func startMonitoring(interval: TimeInterval = 2.0) {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Initial update
        updateStats()

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    func setUpdateInterval(_ interval: TimeInterval) {
        guard isMonitoring else { return }
        stopMonitoring()
        startMonitoring(interval: interval)
    }

    // MARK: - Stats Update

    private func updateStats() {
        queue.async { [weak self] in
            guard let self = self else { return }

            let cpu = self.calculateCPUUsage()
            let memory = self.calculateMemoryUsage()

            DispatchQueue.main.async {
                self.stats.cpuUsage = cpu
                self.stats.memoryUsed = memory.used
                self.stats.memoryTotal = memory.total
                self.stats.memoryPressure = memory.pressure
            }
        }
    }

    // MARK: - CPU Usage

    private func calculateCPUUsage() -> Double {
        var numCPUsU: natural_t = 0
        var newInfo: processor_info_array_t?
        var numInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &newInfo, &numInfo)

        guard result == KERN_SUCCESS, let newInfo = newInfo else { return 0 }

        var totalUsage: Double = 0

        if let prevInfo = prevCpuInfo, numCPUs > 0 {
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

            // Deallocate previous info
            let prevSize = vm_size_t(numPrevCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevInfo), prevSize)
        }

        prevCpuInfo = newInfo
        numPrevCpuInfo = numInfo

        return numCPUs > 0 ? (totalUsage / Double(numCPUs)) * 100 : 0
    }

    // MARK: - Memory Usage

    private func calculateMemoryUsage() -> (used: UInt64, total: UInt64, pressure: Double) {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return (0, ProcessInfo.processInfo.physicalMemory, 0)
        }

        let pageSize = UInt64(vm_kernel_page_size)

        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize

        // Used = Active + Wired + Compressed (matches Activity Monitor)
        let used = active + wired + compressed
        let total = ProcessInfo.processInfo.physicalMemory

        // Memory pressure (0-1 scale)
        let pressure = Double(used) / Double(total)

        return (used, total, pressure)
    }

    // MARK: - Snapshot

    /// Get current stats without starting monitoring
    func getSnapshot() -> SystemStats {
        let cpu = calculateCPUUsage()
        let memory = calculateMemoryUsage()

        return SystemStats(
            cpuUsage: cpu,
            memoryUsed: memory.used,
            memoryTotal: memory.total,
            memoryPressure: memory.pressure
        )
    }
}
