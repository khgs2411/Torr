# Torr

[![CI](https://github.com/khgs2411/Torr/actions/workflows/ci.yml/badge.svg)](https://github.com/khgs2411/Torr/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A lightweight macOS memory monitor widget. Named after the unit of pressure (Torricelli).

Torr lives in your menu bar and displays a floating translucent overlay with real-time memory statistics sourced directly from Mach kernel APIs.

## Features

- **Menu bar app** -- no Dock icon, minimal footprint (~1MB)
- **Floating overlay** -- always-on-top translucent HUD, draggable, remembers position
- **Real-time stats** -- Physical Memory, Memory Used, Cached Files, Swap Used
- **Memory Pressure** -- color-coded bar (green/yellow/red) based on compressed memory ratio
- **Sparkline graph** -- rolling 2-minute history of memory usage

## Download

Grab the latest release from the [Releases page](https://github.com/khgs2411/Torr/releases/latest).

1. Download **Torr.dmg**
2. Open the DMG
3. Drag **Torr** to **Applications**
4. Right-click Torr in Applications > **Open** (first launch only, since the app is unsigned)

### Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Build from Source

Clone the repo and build with Swift Package Manager:

```bash
git clone https://github.com/khgs2411/Torr.git
cd Torr
swift build
swift run Torr
```

### Release Build (DMG)

```bash
./scripts/build-app.sh release
```

Produces `build/Torr.dmg` ready to share.

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

Torr is released under the [MIT License](LICENSE).
