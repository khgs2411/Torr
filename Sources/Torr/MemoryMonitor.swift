import Foundation
import Dispatch
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
    @Published var usageRatio: Double = 0.0
    @Published var pressureLevel: PressureLevel = .nominal
    @Published var usageHistory: [Double] = []

    let totalRAM: UInt64 = ProcessInfo.processInfo.physicalMemory

    private let maxHistory = 60
    private var timer: Timer?
    private var pressureSource: DispatchSourceMemoryPressure?

    func startPolling(interval: TimeInterval = 2.0) {
        stopPolling()
        refresh()
        startPressureMonitoring()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        pressureSource?.cancel()
        pressureSource = nil
    }

    deinit {
        stopPolling()
    }

    func refresh() {
        guard let stats = Self.getVMStats() else { return }

        let pageSize = Int64(vm_kernel_page_size)

        let free = Int64(stats.free_count) * pageSize
        let purgeable = Int64(stats.purgeable_count) * pageSize
        let external = Int64(stats.external_page_count) * pageSize

        let total = Int64(totalRAM)

        let cached = purgeable + external
        let used = total - free - cached

        memoryUsed = max(used, 0)
        cachedFiles = max(cached, 0)

        usageRatio = total > 0 ? min(Double(memoryUsed) / Double(total), 1.0) : 0.0

        if let swap = Self.getSwapUsage() {
            swapUsed = Int64(swap.xsu_used)
        } else {
            swapUsed = 0
        }

        usageHistory.append(usageRatio)
        if usageHistory.count > maxHistory {
            usageHistory.removeFirst(usageHistory.count - maxHistory)
        }
    }

    private func startPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: .all, queue: .main)
        source.setEventHandler { [weak self] in
            guard let self else { return }
            let event = DispatchSource.MemoryPressureEvent(rawValue: source.data)
            if event.contains(.critical) {
                self.pressureLevel = .critical
            } else if event.contains(.warning) {
                self.pressureLevel = .warning
            } else {
                self.pressureLevel = .nominal
            }
        }
        source.resume()
        pressureSource = source
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
