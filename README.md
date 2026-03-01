# Torr

A lightweight macOS memory monitor widget. Named after the unit of pressure (Torricelli).

Torr lives in your menu bar and displays a floating translucent overlay with real-time memory statistics sourced directly from Mach kernel APIs.

## Features

- **Menu bar app** -- no Dock icon, minimal footprint
- **Floating overlay** -- always-on-top translucent HUD, draggable, remembers position
- **Real-time stats** -- Physical Memory, Memory Used, Cached Files, Swap Used
- **Memory Pressure** -- color-coded bar (green/yellow/red) based on compressed memory ratio
- **Sparkline graph** -- rolling 2-minute history of memory usage

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Build & Run

### Development (SPM)

```bash
swift build
swift run Torr
```

### App Bundle

```bash
./scripts/build-app.sh release
open build/Torr.app
```

### Tests

```bash
swift test
```

## Architecture

- **MemoryMonitor** -- `ObservableObject` that polls `host_statistics64()` and `sysctl` every 2 seconds
- **FloatingPanel** -- `NSPanel` subclass with `.floating` level and `NSVisualEffectView` backdrop
- **OverlayView** -- SwiftUI view binding to monitor's `@Published` properties
- **MemoryGraphView** -- SwiftUI `Shape`-based sparkline with filled area
- **AppDelegate** -- manages `NSStatusItem` (menu bar icon) and panel lifecycle

## License

MIT
