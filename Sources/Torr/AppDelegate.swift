import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private static let colorMenuBarIconKey = "torr.colorMenuBarIcon"

    private var statusItem: NSStatusItem?
    private var colorMenuItem: NSMenuItem?
    private var panel: FloatingPanel?
    private let monitor = MemoryMonitor()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarIcon()
        setupPanel()
        bindMenuBarIcon()
        monitor.startPolling(interval: 2.0)
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stopPolling()
    }

    private func setupMenuBarIcon() {
        registerDefaults()

        statusItem = NSStatusBar.system.statusItem(withLength: MenuBarIconRenderer.statusItemLength)

        if let button = statusItem?.button {
            button.image = MenuBarIconRenderer.makeImage(state: currentMenuBarIconState)
            button.imagePosition = .imageOnly
            button.action = #selector(togglePanel)
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Overlay", action: #selector(togglePanel), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        let colorItem = NSMenuItem(title: "Color Menu Bar Icon", action: #selector(toggleColorMenuBarIcon), keyEquivalent: "")
        colorItem.target = self
        colorMenuItem = colorItem
        menu.addItem(colorItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Torr", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
        updateColorMenuItem()
    }

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [Self.colorMenuBarIconKey: true])
    }

    private func bindMenuBarIcon() {
        Publishers.CombineLatest(monitor.$pressureLevel, monitor.$swapUsed)
            .receive(on: RunLoop.main)
            .sink { [weak self] pressureLevel, swapUsed in
                self?.updateMenuBarIcon(pressureLevel: pressureLevel, swapUsed: swapUsed)
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarIcon(pressureLevel: MemoryMonitor.PressureLevel, swapUsed: Int64) {
        let state = MenuBarIconState(pressureLevel: pressureLevel, swapUsed: swapUsed, usesColor: usesColorMenuBarIcon)
        statusItem?.button?.image = MenuBarIconRenderer.makeImage(state: state)
    }

    private var currentMenuBarIconState: MenuBarIconState {
        MenuBarIconState(pressureLevel: monitor.pressureLevel, swapUsed: monitor.swapUsed, usesColor: usesColorMenuBarIcon)
    }

    private var usesColorMenuBarIcon: Bool {
        UserDefaults.standard.bool(forKey: Self.colorMenuBarIconKey)
    }

    private func updateColorMenuItem() {
        colorMenuItem?.state = usesColorMenuBarIcon ? .on : .off
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

    @objc private func toggleColorMenuBarIcon() {
        UserDefaults.standard.set(!usesColorMenuBarIcon, forKey: Self.colorMenuBarIconKey)
        updateColorMenuItem()
        updateMenuBarIcon(pressureLevel: monitor.pressureLevel, swapUsed: monitor.swapUsed)
    }
}
