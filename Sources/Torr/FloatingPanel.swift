import AppKit
import SwiftUI

final class FloatingPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        hasShadow = true

        hidesOnDeactivate = false

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove(_:)),
            name: NSWindow.didMoveNotification,
            object: self
        )

        restorePosition()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setContent<V: View>(_ view: V) {
        let hostingView = NSHostingView(rootView: view)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let visualEffect = NSVisualEffectView()
        visualEffect.appearance = NSAppearance(named: .darkAqua)
        visualEffect.material = .underWindowBackground
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 12
        visualEffect.layer?.masksToBounds = true
        visualEffect.translatesAutoresizingMaskIntoConstraints = false

        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
        ])

        contentView = visualEffect
    }

    @objc private func windowDidMove(_ notification: Notification) {
        savePosition()
    }

    private func savePosition() {
        let origin = frame.origin
        UserDefaults.standard.set(origin.x, forKey: "torr.panel.x")
        UserDefaults.standard.set(origin.y, forKey: "torr.panel.y")
    }

    private func restorePosition() {
        let x = UserDefaults.standard.double(forKey: "torr.panel.x")
        let y = UserDefaults.standard.double(forKey: "torr.panel.y")
        guard x != 0 || y != 0 else { return }

        let proposedFrame = NSRect(origin: NSPoint(x: x, y: y), size: frame.size)

        // Check if the window would be visible on any connected screen
        let isOnScreen = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(proposedFrame)
        }

        if isOnScreen {
            setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            // Fallback: place in top-right of the main screen
            if let screen = NSScreen.main {
                let visibleFrame = screen.visibleFrame
                let safeX = visibleFrame.maxX - frame.width - 20
                let safeY = visibleFrame.maxY - frame.height - 20
                setFrameOrigin(NSPoint(x: safeX, y: safeY))
            }
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
