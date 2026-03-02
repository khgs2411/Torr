import SwiftUI

struct OverlayView: View {
    @ObservedObject var monitor: MemoryMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Torr")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                pressureIndicator
            }

            Divider()
                .background(Color.white.opacity(0.2))

            statRow(label: "Physical Memory", value: formatTotal(monitor.totalRAM))
            statRow(label: "Memory Used", value: MemoryMonitor.formatBytes(monitor.memoryUsed))
            statRow(label: "Cached Files", value: MemoryMonitor.formatBytes(monitor.cachedFiles))
            swapRow

            pressureBar

            MemoryGraphView(
                data: monitor.usageHistory,
                lineColor: pressureColor,
                fillColor: pressureColor.opacity(0.15)
            )
            .frame(height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(12)
        .frame(width: 220)
    }

    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    private var swapRow: some View {
        HStack {
            Text("Swap Used")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(MemoryMonitor.formatBytes(monitor.swapUsed))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(swapColor)
        }
    }

    private var pressureBar: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Memory Pressure")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 2)
                        .fill(pressureColor)
                        .frame(width: geo.size.width * CGFloat(monitor.usageRatio))
                }
            }
            .frame(height: 6)
        }
    }

    private var pressureIndicator: some View {
        Circle()
            .fill(pressureColor)
            .frame(width: 6, height: 6)
    }

    private var pressureColor: Color {
        switch monitor.pressureLevel {
        case .nominal:  return .green
        case .warning:  return .yellow
        case .critical: return .red
        }
    }

    private var swapColor: Color {
        if monitor.swapUsed == 0 {
            return .white
        }
        let oneGB: Int64 = 1_073_741_824
        return monitor.swapUsed > oneGB ? .red : .yellow
    }

    private func formatTotal(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824.0
        return String(format: "%.0f GB", gb)
    }
}
