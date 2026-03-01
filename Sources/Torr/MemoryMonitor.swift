import Foundation
import Darwin

final class MemoryMonitor: ObservableObject {

    enum PressureLevel: String {
        case nominal
        case warning
        case critical
    }

    @Published var memoryUsed: Int64 = 0
    @Published var cachedFiles: Int64 = 0
    @Published var swapUsed: Int64 = 0
    @Published var compressedRatio: Double = 0.0
    @Published var pressureLevel: PressureLevel = .nominal
    @Published var usageHistory: [Double] = []

    let totalRAM: UInt64 = ProcessInfo.processInfo.physicalMemory

    private let maxHistory = 60
    private var timer: Timer?

    func startPolling(interval: TimeInterval = 2.0) {
        stopPolling()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        guard let stats = Self.getVMStats() else { return }

        let pageSize = Int64(vm_kernel_page_size)

        let free = Int64(stats.free_count) * pageSize
        let inactive = Int64(stats.inactive_count) * pageSize
        let purgeable = Int64(stats.purgeable_count) * pageSize
        let external = Int64(stats.external_page_count) * pageSize
        let compressed = Int64(stats.compressor_page_count) * pageSize

        let total = Int64(totalRAM)

        let cached = purgeable + external
        let used = total - free - inactive - cached

        memoryUsed = max(used, 0)
        cachedFiles = max(cached, 0)

        let denominator = Double(used + compressed)
        if denominator > 0 {
            compressedRatio = min(Double(compressed) / denominator, 1.0)
        } else {
            compressedRatio = 0.0
        }

        if compressedRatio < 0.5 {
            pressureLevel = .nominal
        } else if compressedRatio < 0.8 {
            pressureLevel = .warning
        } else {
            pressureLevel = .critical
        }

        if let swap = Self.getSwapUsage() {
            swapUsed = Int64(swap.xsu_used)
        } else {
            swapUsed = 0
        }

        let fraction = total > 0 ? min(Double(memoryUsed) / Double(total), 1.0) : 0.0
        usageHistory.append(fraction)
        if usageHistory.count > maxHistory {
            usageHistory.removeFirst(usageHistory.count - maxHistory)
        }
    }

    private static func getVMStats() -> vm_statistics64_data_t? {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        return result == KERN_SUCCESS ? stats : nil
    }

    private static func getSwapUsage() -> xsw_usage? {
        var usage = xsw_usage()
        var len = MemoryLayout<xsw_usage>.size
        let result = sysctlbyname("vm.swapusage", &usage, &len, nil, 0)
        return result == 0 ? usage : nil
    }

    static func formatBytes(_ bytes: Int64) -> String {
        if bytes == 0 { return "0 MB" }
        let gb = Double(bytes) / 1_073_741_824.0
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        }
        let mb = Double(bytes) / 1_048_576.0
        return String(format: "%.2f MB", mb)
    }
}
