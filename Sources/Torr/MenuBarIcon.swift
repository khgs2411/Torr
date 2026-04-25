import AppKit

enum MenuBarIconColor: Equatable {
    case green
    case yellow
    case red

    var nsColor: NSColor {
        switch self {
        case .green:
            return NSColor.systemGreen
        case .yellow:
            return NSColor.systemYellow
        case .red:
            return NSColor.systemRed
        }
    }
}

struct MenuBarIconState: Equatable {
    let pressureColor: MenuBarIconColor
    let swapBadgeColor: MenuBarIconColor?
    let usesColor: Bool

    init(pressureLevel: MemoryMonitor.PressureLevel, swapUsed: Int64, usesColor: Bool = true) {
        self.pressureColor = Self.pressureColor(for: pressureLevel)
        self.swapBadgeColor = usesColor ? Self.swapBadgeColor(for: swapUsed) : nil
        self.usesColor = usesColor
    }

    static func pressureColor(for level: MemoryMonitor.PressureLevel) -> MenuBarIconColor {
        switch level {
        case .nominal:
            return .green
        case .warning:
            return .yellow
        case .critical:
            return .red
        }
    }

    static func swapBadgeColor(for swapUsed: Int64) -> MenuBarIconColor? {
        guard swapUsed > 0 else { return nil }
        let oneGB: Int64 = 1_073_741_824
        return swapUsed > oneGB ? .red : .yellow
    }
}

enum MenuBarIconRenderer {
    static let statusItemLength: CGFloat = 20

    static func makeImage(state: MenuBarIconState) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        drawChip(
            in: NSRect(x: 3.2, y: 3.0, width: 13.6, height: 12.0),
            fillColor: state.usesColor ? state.pressureColor.nsColor : NSColor.labelColor.withAlphaComponent(0.12),
            strokeColor: NSColor.black
        )

        if let badgeColor = state.swapBadgeColor {
            drawSwapBadge(color: badgeColor.nsColor)
        }

        image.isTemplate = false
        return image
    }

    private static func drawChip(in rect: NSRect, fillColor: NSColor, strokeColor: NSColor) {
        let body = NSBezierPath(roundedRect: rect, xRadius: 1.8, yRadius: 1.8)
        fillColor.setFill()
        body.fill()
        strokeColor.setStroke()
        body.lineWidth = 1.4
        body.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 9.5, weight: .black),
            .foregroundColor: strokeColor,
            .paragraphStyle: paragraph
        ]
        "T".draw(in: NSRect(x: rect.minX, y: rect.minY + 0.7, width: rect.width, height: rect.height), withAttributes: attributes)

        drawPins(rect: rect, color: strokeColor)
    }

    private static func drawPins(rect: NSRect, color: NSColor) {
        color.setStroke()
        let pins = NSBezierPath()
        let horizontalPins = [rect.minY + 3.0, rect.maxY - 3.0]
        for y in horizontalPins {
            pins.move(to: NSPoint(x: rect.minX - 2.2, y: y))
            pins.line(to: NSPoint(x: rect.minX - 0.1, y: y))
            pins.move(to: NSPoint(x: rect.maxX + 0.1, y: y))
            pins.line(to: NSPoint(x: rect.maxX + 2.2, y: y))
        }

        let verticalPins = [rect.minX + 3.0, rect.maxX - 3.0]
        for x in verticalPins {
            pins.move(to: NSPoint(x: x, y: rect.maxY + 0.2))
            pins.line(to: NSPoint(x: x, y: rect.maxY + 1.8))
        }

        pins.lineWidth = 1.35
        pins.stroke()
    }

    private static func drawSwapBadge(color: NSColor) {
        let badgeRect = NSRect(x: 11.0, y: 0.8, width: 6.2, height: 8.2)
        let badge = NSBezierPath(roundedRect: badgeRect, xRadius: 3.1, yRadius: 3.1)
        color.setFill()
        badge.fill()

        NSColor.black.withAlphaComponent(0.75).setStroke()
        badge.lineWidth = 0.8
        badge.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 7.5, weight: .black),
            .foregroundColor: NSColor.black,
            .paragraphStyle: paragraph
        ]
        "!".draw(in: NSRect(x: badgeRect.minX, y: badgeRect.minY + 0.6, width: badgeRect.width, height: badgeRect.height), withAttributes: attributes)
    }
}
