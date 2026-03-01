# Torr - macOS Memory Monitor Widget

## Overview

Torr is a lightweight, always-on-top macOS memory monitor widget. It displays real-time memory statistics in a small transparent overlay, similar to FPS monitor overlays used in gaming. Named after the unit of pressure (Torricelli), referencing memory pressure monitoring.

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI + AppKit (NSPanel)
- **Memory APIs:** Mach kernel (`host_statistics64`, `sysctl`)
- **Min macOS:** 13.0 (Ventura)
- **Target footprint:** < 20MB RAM

## Architecture

### Menu Bar App with Floating Overlay

- Lives in the menu bar (no Dock icon via `LSUIElement`)
- Clicking menu bar icon toggles the floating overlay
- NSPanel with `.floating` level - always visible, doesn't steal focus
- Translucent background via `NSVisualEffectView`
- Draggable, remembers position, click-through when not interacting

### Data Source

Direct Mach kernel calls - no shelling out to `vm_stat` or subprocess parsing.

- `host_statistics64()` with `HOST_VM_INFO64` - page counts for free, active, inactive, wired, compressed, cached
- `sysctl("hw.memsize")` - total physical RAM (one-time read)
- `sysctl("vm.swapusage")` - swap total, used, free

### Calculations

- **Memory Used** = total - free - inactive - cached
- **Cached Files** = purgeable + file-backed pages
- **Memory Pressure** = thresholds based on compressed memory ratio: green (<50%), yellow (50-80%), red (>80%)

## UI Layout

Compact widget, approximately 220x160px.

### Displayed Stats
- Physical Memory (total RAM, static)
- Memory Used (dynamic)
- Cached Files (dynamic)
- Swap Used (dynamic, highlighted yellow/red when non-zero)
- Memory Pressure (horizontal bar: green/yellow/red)

### Mini Graph
- Sparkline-style line graph at the bottom
- Rolling buffer of last 60 readings (~2 minutes at 2s interval)
- Thin line on subtle grid

### Visual Style
- Dark translucent background (vibrancy material)
- Monospace font for numbers
- Rounded corners
- Small title area with app name

### Menu Bar Icon
- Tiny memory gauge icon with color indicator (green/yellow/red based on pressure)

## Project Structure

```
Torr/
├── Torr/
│   ├── TorrApp.swift             # App entry point, menu bar setup
│   ├── MemoryMonitor.swift       # Mach API calls, data polling
│   ├── OverlayWindow.swift       # NSPanel configuration
│   ├── OverlayView.swift         # SwiftUI view (stats + graph)
│   ├── MemoryGraphView.swift     # Sparkline graph component
│   ├── Assets.xcassets/          # Menu bar icon
│   └── Info.plist
├── docs/
│   └── plans/
├── README.md
└── LICENSE
```

## Data Flow

1. `MemoryMonitor` class polls every 2 seconds via `Timer`
2. Publishes updates via `@Published` properties
3. Graph stores rolling buffer of last 60 readings
4. SwiftUI views bind directly to published values

## Preferences (UserDefaults)

- Overlay position (x, y)
- Update interval
- Launch at login toggle

## Distribution

- GitHub releases with `.dmg`
- Homebrew Cask formula (future)
- MIT License
