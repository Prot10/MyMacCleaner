import Foundation
import Darwin

/// Repository for fetching system statistics (memory, CPU, disk)
final class SystemStatsRepository: Sendable {

    // MARK: - Memory Statistics

    /// Get current memory statistics using host_statistics64
    func getMemoryStats() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    ptr,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            return MemoryStats.empty
        }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = getTotalMemory()

        return MemoryStats(
            free: UInt64(stats.free_count) * pageSize,
            active: UInt64(stats.active_count) * pageSize,
            inactive: UInt64(stats.inactive_count) * pageSize,
            wired: UInt64(stats.wire_count) * pageSize,
            compressed: UInt64(stats.compressor_page_count) * pageSize,
            purgeable: UInt64(stats.purgeable_count) * pageSize,
            speculative: UInt64(stats.speculative_count) * pageSize,
            total: total
        )
    }

    /// Get total physical memory
    func getTotalMemory() -> UInt64 {
        var size = MemoryLayout<UInt64>.size
        var memSize: UInt64 = 0
        var mib: [Int32] = [CTL_HW, HW_MEMSIZE]

        sysctl(&mib, 2, &memSize, &size, nil, 0)
        return memSize
    }

    // MARK: - CPU Statistics

    /// Get current CPU usage percentage
    func getCPUUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS, let cpuInfo = cpuInfo else {
            return 0
        }

        var totalUsage: Double = 0
        let cpuLoadInfo = cpuInfo.withMemoryRebound(
            to: processor_cpu_load_info.self,
            capacity: Int(numCPUs)
        ) { ptr in
            Array(UnsafeBufferPointer(start: ptr, count: Int(numCPUs)))
        }

        for cpu in cpuLoadInfo {
            let user = Double(cpu.cpu_ticks.0)   // CPU_STATE_USER
            let system = Double(cpu.cpu_ticks.1) // CPU_STATE_SYSTEM
            let idle = Double(cpu.cpu_ticks.2)   // CPU_STATE_IDLE
            let nice = Double(cpu.cpu_ticks.3)   // CPU_STATE_NICE

            let total = user + system + idle + nice
            if total > 0 {
                totalUsage += (user + system + nice) / total
            }
        }

        // Deallocate the memory
        let size = vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), size)

        return numCPUs > 0 ? totalUsage / Double(numCPUs) : 0
    }

    // MARK: - Disk Statistics

    /// Get disk usage for the main volume
    func getDiskUsage() -> DiskUsage {
        let fileURL = URL(fileURLWithPath: "/")

        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])

            let total = Int64(values.volumeTotalCapacity ?? 0)
            let availableImportant = values.volumeAvailableCapacityForImportantUsage ?? 0
            let availableFallback = Int64(values.volumeAvailableCapacity ?? 0)
            let available = availableImportant > 0 ? availableImportant : availableFallback
            let used = total - available

            return DiskUsage(
                total: total,
                used: used,
                available: available
            )
        } catch {
            return DiskUsage(total: 0, used: 0, available: 0)
        }
    }

    /// Get disk usage breakdown by category
    func getDiskUsageBreakdown() async -> [DiskCategory] {
        let home = NSHomeDirectory()
        let fm = FileManager.default

        var categories: [DiskCategory] = []

        // Calculate sizes for each category (this can be slow)
        let paths: [(name: String, path: String, color: String)] = [
            ("Applications", "/Applications", "blue"),
            ("Documents", "\(home)/Documents", "orange"),
            ("Downloads", "\(home)/Downloads", "green"),
            ("Library", "\(home)/Library", "purple"),
            ("System", "/System", "gray"),
        ]

        for (name, path, color) in paths {
            if let size = try? calculateDirectorySize(at: path) {
                categories.append(DiskCategory(name: name, sizeBytes: size, colorName: color))
            }
        }

        return categories.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private func calculateDirectorySize(at path: String) throws -> Int64 {
        let fm = FileManager.default
        var totalSize: Int64 = 0

        guard fm.fileExists(atPath: path) else { return 0 }

        // Use a shallow enumeration for performance
        if let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                   let isDirectory = values.isDirectory,
                   !isDirectory,
                   let size = values.fileSize {
                    totalSize += Int64(size)
                }
            }
        }

        return totalSize
    }
}

// MARK: - Types

struct DiskUsage: Sendable {
    let total: Int64
    let used: Int64
    let available: Int64

    var usagePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    var formattedUsed: String {
        ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
    }

    var formattedAvailable: String {
        ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
    }
}

struct DiskCategory: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let sizeBytes: Int64
    let colorName: String

    init(name: String, sizeBytes: Int64, colorName: String) {
        self.id = UUID()
        self.name = name
        self.sizeBytes = sizeBytes
        self.colorName = colorName
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    static func == (lhs: DiskCategory, rhs: DiskCategory) -> Bool {
        lhs.name == rhs.name && lhs.sizeBytes == rhs.sizeBytes
    }
}

// MemoryStats is defined in SharedKit/Sources/Models/MemoryStats.swift
