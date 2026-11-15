import AppKit
import Combine

/// A single native menu: the zones for the screen the focused window is on,
/// then Settings, drag-to-snap and Quit.
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private var target: AXWindow?
    var openSettings: () -> Void = {}

    override init() {
        super.init()
        item.button?.image = NSImage(systemSymbolName: "rectangle.split.2x2", accessibilityDescription: "ZoneSnap")
        menu.delegate = self
        item.menu = menu
    }

    // the window to move is the one focused before the menu opened
    func menuWillOpen(_ menu: NSMenu) { target = AXWindow.focused() }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        target = AXWindow.focused()
        let screen = target?.frame.flatMap { ScreenGeometry.screen(containing: $0) } ?? NSScreen.main ?? NSScreen.screens[0]
        let portrait = ScreenGeometry.isPortrait(screen)
        let header = NSMenuItem(title: portrait ? "Zones — vertical screen" : "Zones", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for zone in ZoneStore.shared.zones where zone.applies(toPortrait: portrait) {
            let mi = NSMenuItem(title: zone.name.trimmingCharacters(in: .whitespaces), action: #selector(pick(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = zone.id
            mi.image = Self.icon(zone)
            if let key = zone.key {
                mi.attributedTitle = NSAttributedString(
                    string: "\(mi.title)    \(KeyTable.symbols(zone.modifiers, key))",
                    attributes: [.font: NSFont.menuFont(ofSize: 0)])
            }
            menu.addItem(mi)
        }
        menu.addItem(.separator())
        let drag = NSMenuItem(title: "Snap when dragging to edges", action: #selector(toggleDrag), keyEquivalent: "")
        drag.target = self
        drag.state = ZoneStore.shared.dragSnapEnabled ? .on : .off
        menu.addItem(drag)
        let linked = NSMenuItem(title: "Neighbor windows follow resizing", action: #selector(toggleLinked), keyEquivalent: "")
        linked.target = self
        linked.state = ZoneStore.shared.linkedResizeEnabled ? .on : .off
        menu.addItem(linked)
        let login = NSMenuItem(title: "Open at login", action: #selector(toggleLogin), keyEquivalent: "")
        login.target = self
        login.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(login)
        let settings = NSMenuItem(title: "Settings…", action: #selector(settings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem(title: "Quit ZoneSnap", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc private func pick(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID,
              let zone = ZoneStore.shared.zones.first(where: { $0.id == id }), let w = target else { return }
        Snapper.snap(w, to: zone)
    }

    @objc private func toggleDrag() { ZoneStore.shared.dragSnapEnabled.toggle() }
    @objc private func toggleLinked() { ZoneStore.shared.linkedResizeEnabled.toggle() }
    @objc private func toggleLogin() { LoginItem.setEnabled(!LoginItem.isEnabled) }
    @objc private func settings() { openSettings() }

    /// A small picture of the zone inside a screen outline.
    static func icon(_ zone: Zone) -> NSImage {
        let size = NSSize(width: 20, height: 14)
        return NSImage(size: size, flipped: true) { rect in
            let outer = rect.insetBy(dx: 0.5, dy: 0.5)
            NSColor.labelColor.withAlphaComponent(0.55).setStroke()
            let frame = NSBezierPath(roundedRect: outer, xRadius: 2, yRadius: 2)
            frame.lineWidth = 1
            frame.stroke()
            let r = NSRect(x: outer.minX + outer.width * zone.x, y: outer.minY + outer.height * zone.y,
                           width: outer.width * zone.w, height: outer.height * zone.h).insetBy(dx: 1.5, dy: 1.5)
            NSColor.labelColor.withAlphaComponent(0.85).setFill()
            NSBezierPath(roundedRect: r, xRadius: 1, yRadius: 1).fill()
            return true
        }
    }
}
