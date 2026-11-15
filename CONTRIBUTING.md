# Contributing to ZoneSnap

Thanks for helping. ZoneSnap is small on purpose, so most changes are easy to
review. You do **not** need Xcode.

## Set up

You need macOS 12 or later and the Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/<your-fork>/ZoneSnap.git
cd ZoneSnap
./build.sh                 # builds build/ZoneSnap.app
./scripts/install.sh       # builds, installs to ~/Applications and opens it
```

Allow ZoneSnap under System Settings > Privacy & Security > Accessibility.
Every rebuild changes the ad-hoc signature, so if windows stop moving, remove
ZoneSnap from that list and add it again (or run
`tccutil reset Accessibility com.local.ZoneSnap`).

## Where things are

| File | What it does |
| --- | --- |
| `Sources/Zone.swift` | The zone model, key table and default zones |
| `Sources/ZoneStore.swift` | Saves zones and settings |
| `Sources/WindowAccess.swift` | Accessibility (AX) calls and screen math |
| `Sources/Snapper.swift` | Moves a window into a zone, cycling |
| `Sources/HotkeyCenter.swift` | Global shortcuts |
| `Sources/DragSnap.swift` | Drag-to-edge snapping and the preview |
| `Sources/LinkedResize.swift` | Neighbors follow a resized edge |
| `Sources/StatusMenu.swift` | The menu bar menu |
| `Sources/SettingsView.swift` | The settings window |

## Rules of thumb

- Keep it building with **Swift 5.7** and a **macOS 12** target. No APIs that
  need macOS 13 or later without an `#available` check and a fallback.
- Coordinates: Accessibility uses a top-left origin, Cocoa (`NSScreen`) uses
  bottom-left. Convert with `ScreenGeometry`; do not mix them.
- Keep changes small and focused. One idea per pull request.
- Do not add network access or analytics.

## Testing a change

There is no test suite yet, so please try the change by hand and say what you
did in the pull request:

- Shortcuts: snap a window with a few zones, and press a key twice to cycle.
- Drag: drag a window to each edge and corner. Hold Shift to skip.
- Resize: place two windows side by side (and stacked), drag the shared edge,
  and check the other window follows.
- Vertical monitor: if the change touches zones or resizing, test on a rotated
  display.

Adding unit tests for the zone math is a welcome contribution.

## Pull requests

1. Fork, then create a branch: `git checkout -b my-change`.
2. Make the change and run `./build.sh`.
3. Update `CHANGELOG.md` under "Unreleased".
4. Open a pull request and fill in the template.

By contributing you agree your work is released under the [MIT License](LICENSE).
