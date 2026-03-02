import XCTest
@testable import Torr

final class MemoryMonitorTests: XCTestCase {

    var monitor: MemoryMonitor!

    override func setUp() {
        super.setUp()
        monitor = MemoryMonitor()
    }

    override func tearDown() {
        monitor.stopPolling()
        monitor = nil
        super.tearDown()
    }

    func testTotalRAMIsPositive() {
        XCTAssertGreaterThan(monitor.totalRAM, 0)
    }

    func testTotalRAMIsReasonable() {
        let oneGB: UInt64 = 1_073_741_824
        let oneTB: UInt64 = 1_099_511_627_776
        XCTAssertGreaterThanOrEqual(monitor.totalRAM, oneGB)
        XCTAssertLessThanOrEqual(monitor.totalRAM, oneTB)
    }

    func testRefreshPopulatesMemoryUsed() {
        monitor.refresh()
        XCTAssertGreaterThan(monitor.memoryUsed, 0)
    }

    func testRefreshPopulatesCachedFiles() {
        monitor.refresh()
        XCTAssertGreaterThanOrEqual(monitor.cachedFiles, 0)
    }

    func testRefreshPopulatesSwapUsed() {
        monitor.refresh()
        XCTAssertGreaterThanOrEqual(monitor.swapUsed, 0)
    }

    func testMemoryUsedDoesNotExceedTotal() {
        monitor.refresh()
        XCTAssertLessThanOrEqual(monitor.memoryUsed, Int64(monitor.totalRAM))
    }

    func testPressureLevelAfterRefresh() {
        monitor.refresh()
        let validLevels: [MemoryMonitor.PressureLevel] = [.nominal, .warning, .critical]
        XCTAssertTrue(validLevels.contains(monitor.pressureLevel))
    }

    func testPressureRatioIsNonNegative() {
        monitor.refresh()
        XCTAssertGreaterThanOrEqual(monitor.pressureRatio, 0.0)
        XCTAssertLessThanOrEqual(monitor.pressureRatio, 1.0)
    }

    func testHistoryStartsEmpty() {
        XCTAssertTrue(monitor.pressureHistory.isEmpty)
    }

    func testRefreshAppendsToHistory() {
        monitor.refresh()
        XCTAssertEqual(monitor.pressureHistory.count, 1)
        monitor.refresh()
        XCTAssertEqual(monitor.pressureHistory.count, 2)
    }

    func testHistoryCapsAt60() {
        for _ in 0..<65 {
            monitor.refresh()
        }
        XCTAssertEqual(monitor.pressureHistory.count, 60)
    }

    func testHistoryValuesAreBetweenZeroAndOne() {
        monitor.refresh()
        for value in monitor.pressureHistory {
            XCTAssertGreaterThanOrEqual(value, 0.0)
            XCTAssertLessThanOrEqual(value, 1.0)
        }
    }

    func testFormatBytesGB() {
        let twoGB: Int64 = 2_147_483_648
        XCTAssertEqual(MemoryMonitor.formatBytes(twoGB), "2.00 GB")
    }

    func testFormatBytesMB() {
        let fiveHundredMB: Int64 = 524_288_000
        XCTAssertEqual(MemoryMonitor.formatBytes(fiveHundredMB), "500.00 MB")
    }

    func testFormatBytesZero() {
        XCTAssertEqual(MemoryMonitor.formatBytes(0), "0 MB")
    }
}
