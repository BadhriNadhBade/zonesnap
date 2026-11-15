# ZoneSnap

Snap windows into place with a keyboard shortcut or by dragging to a screen edge. Made for people with more than one monitor, including **rotated (vertical) monitors**, where you want one window on top and another below.

- **Zones** – halves, thirds, quarters, center and maximize, plus your own.
- **Shortcuts** – `Ctrl + Option` with the arrow keys. Press again to cycle sizes.
- **Drag to snap** – drag a window to an edge or corner and a preview shows where it lands.
- **Neighbors follow** – resize one window and the window next to it fills the gap.
- **Vertical screens get their own zones** – top, middle and bottom instead of left and right.
- **One small menu** in the menu bar. No Dock icon, no account, no network.

Built for **macOS 12 (Monterey) and later**, and tested on macOS 12. Tried it on a newer macOS? [Let me know](https://github.com/BadhriNadhBade/ZoneSnap/issues). Free and open source (MIT).

> ZoneSnap is an independent project. It is not affiliated with any other window manager.

---

## Quickstart

You need a Mac running macOS 12 or later and the free Command Line Tools. You do **not** need Xcode.

```bash
# 1. one time: install the Command Line Tools (skip if you already have them)
xcode-select --install

# 2. get the code and install
git clone https://github.com/BadhriNadhBade/ZoneSnap.git
cd ZoneSnap
./scripts/install.sh
```

The script builds the app, puts it in `~/Applications`, and opens it. Then:

3. macOS asks for **Accessibility** access. Open **System Settings → Privacy & Security → Accessibility** and turn **ZoneSnap** on. This is what lets it move windows.
4. Click the ZoneSnap icon in the menu bar. Try **Ctrl + Option + ←** on any window.

That's it.

### Download instead of building

When a release is published, download `ZoneSnap-<version>.zip` from the **Releases** page, unzip it, and drag `ZoneSnap.app` to `Applications`. The app is not notarized, so the first time, right-click it and choose **Open**. If macOS still blocks it, run:

```bash
xattr -dr com.apple.quarantine /Applications/ZoneSnap.app
```

---

## Default shortcuts

All shortcuts are `Ctrl + Option` plus a key. Press the same key again to cycle through the sizes for that key.

| Keys | Landscape screen | Vertical screen |
| --- | --- | --- |
| `←` | Left half → left two-thirds → left third | Left half |
| `→` | Right half → right two-thirds → right third | Right half |
| `↑` | Top half | Top half → top third → top two-thirds |
| `↓` | Bottom half | Bottom half → bottom third → bottom two-thirds |
| `M` | – | Middle third |
| `U` `I` | Top-left, top-right quarter | same |
| `J` `K` | Bottom-left, bottom-right quarter | same |
| `C` | Center | Center |
| `Return` | Maximize | Maximize |

ZoneSnap picks the set from the screen the window is on, so one window on top and another below on a vertical monitor is `Ctrl + Option + ↑` on one and `Ctrl + Option + ↓` on the other.

## Dragging

- Drag a window to the **edge** of a screen to snap it to that half. Drag into a **corner** to snap it to a quarter.
- A colored preview shows where the window will go. Release to snap.
- Hold **Shift** while releasing to cancel the snap.
- On a landscape screen the top edge maximizes. On a vertical screen the top and bottom edges give the top and bottom half.

## Resizing neighbors

Place two windows next to each other (or stacked), then drag the edge they share. The other window follows, so no gap is left behind.

- A window counts as a neighbor if it is within about 24 px of the edge you drag.
- A neighbor never shrinks below 120 px.
- Turn it off in the menu: **Neighbor windows follow resizing**.

## Customizing

Open the menu bar icon → **Settings…**. For each zone you can:

- turn it on or off,
- choose which screens it applies to (any, landscape only, vertical only),
- set the key and modifiers (several zones on one key cycle in list order),
- set its position and size (`X`, `Y`, `W`, `H` are fractions from 0 to 1, measured from the top-left of the screen),
- choose a **Drag edge** so dragging there snaps to it.

Zones are saved to `~/Library/Application Support/ZoneSnap/zones.json` once you change something. Delete that file, or press **Reset to defaults**, to start over.

The menu also has **Open at login** and **Snap when dragging to edges**.

---

## Troubleshooting

**Nothing moves when I press a shortcut.**
Open the ZoneSnap menu. If it starts with "⚠️ Accessibility not allowed", click it and turn ZoneSnap on. If ZoneSnap is already listed as on but still does nothing, the entry is stale (this happens after you rebuild or update the app). Select it, press **−**, add it again, or run:

```bash
tccutil reset Accessibility com.local.ZoneSnap
```

then reopen ZoneSnap and allow it again.

**A shortcut does nothing, but others work.**
Another app may already use that shortcut. Change the key in **Settings…**, or turn the other app's shortcut off.

**One app's window won't resize the way I asked.**
Some windows have a minimum or fixed size. ZoneSnap asks politely; the app decides.

**Drag snapping triggers when I don't want it.**
Hold **Shift** when you release, or turn off **Snap when dragging to edges** in the menu.

**See what ZoneSnap is doing.**

```bash
/usr/bin/log show --last 5m --predicate 'process == "ZoneSnap"'
```

## Uninstall

Quit ZoneSnap from its menu, then:

```bash
rm -rf ~/Applications/ZoneSnap.app
rm -rf ~/Library/Application\ Support/ZoneSnap
rm -f ~/Library/LaunchAgents/com.local.ZoneSnap.login.plist   # only if you enabled Open at login
tccutil reset Accessibility com.local.ZoneSnap
```

---

## Build from source

```bash
./build.sh                 # makes build/ZoneSnap.app, signed ad-hoc
./scripts/package.sh       # also writes build/ZoneSnap-<version>.zip for a release
```

`build.sh` calls `swiftc` directly, so only the Command Line Tools are needed. It builds for the Mac you run it on (Intel or Apple silicon) with a macOS 12 target.

Each rebuild changes the ad-hoc signature, so macOS may ask you to allow Accessibility again. See Troubleshooting.

## Contributing

Bug reports, ideas and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first; it explains the code layout and how to test a change by hand. Please follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security issues: see [SECURITY.md](SECURITY.md).

## Privacy

ZoneSnap does not connect to the internet and collects no data. It reads window positions through macOS Accessibility only to move them.

## License

[MIT](LICENSE) © 2026 ZoneSnap contributors.
