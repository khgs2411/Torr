import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var panel: FloatingPanel?
    private let monitor = MemoryMonitor()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarIcon()
        setupPanel()
        monitor.startPolling(interval: 2.0)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stopPolling()
    }

    private func setupMenuBarIcon() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            let image = NSImage(
                systemSymbolName: "memorychip",
                accessibilityDescription: "Torr Memory Monitor"
            )
            image?.isTemplate = false
            button.image = image
            button.action = #selector(togglePanel)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(togglePanel), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Torr", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    private func setupPanel() {
        let panelRect = NSRect(x: 0, y: 0, width: 220, height: 220)
        panel = FloatingPanel(contentRect: panelRect)

        let overlayView = OverlayView(monitor: monitor)
        panel?.setContent(overlayView)

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.maxX - 240
            let y = screenFrame.maxY - 240
            let savedX = UserDefaults.standard.double(forKey: "torr.panel.x")
            let savedY = UserDefaults.standard.double(forKey: "torr.panel.y")
            if savedX == 0 && savedY == 0 {
                panel?.setFrameOrigin(NSPoint(x: x, y: y))
            }
        }

        panel?.orderFront(nil)
    }

    @objc private func togglePanel() {
        guard let panel = panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFront(nil)
        }
    }

    @objc private func quitApp() {
        monitor.stopPolling()
        NSApplication.shared.terminate(nil)
    }
}
