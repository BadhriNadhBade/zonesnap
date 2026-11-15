import AppKit

/// Drag a window to a screen edge or corner to snap it, with a preview.
/// Holding Shift while releasing cancels the snap.
final class DragSnap {
    static let shared = DragSnap()
    private var monitors: [Any] = []
    private var window: AXWindow?
    private var startFrame: CGRect?
    private enum Mode { case undecided, moving, resizing }
    private var mode = Mode.undecided
    private let linked = LinkedResize()
    private var pending: (zone: Zone, screen: NSScreen)?
    private let preview = PreviewWindow()

    func start() {
        let mask: [NSEvent.EventTypeMask] = [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        for m in mask {
            if let mon = NSEvent.addGlobalMonitorForEvents(matching: m, handler: { [weak self] e in self?.handle(e) }) {
                monitors.append(mon)
            }
        }
    }

    private func handle(_ e: NSEvent) {
        switch e.type {
        case .leftMouseDown:
            let p = NSEvent.mouseLocation
            window = AXWindow.at(CGPoint(x: p.x, y: ScreenGeometry.primaryHeight - p.y))
            startFrame = window?.frame
            mode = .undecided
            pending = nil
        case .leftMouseDragged:
            guard let w = window, let start = startFrame else { return }
            if mode == .undecided {
                guard let now = w.frame else { return }
                let resized = abs(now.width - start.width) >= 2 || abs(now.height - start.height) >= 2
                let moved = abs(now.minX - start.minX) + abs(now.minY - start.minY) > 6
                if resized {
                    mode = .resizing
                    if ZoneStore.shared.linkedResizeEnabled { linked.begin(dragged: w, start: start) }
                } else if moved {
                    mode = .moving
                } else { return }
            }
            if mode == .resizing { linked.update(); return }
            guard ZoneStore.shared.dragSnapEnabled else { return }
            if e.modifierFlags.contains(.shift) { pending = nil; preview.hide(); return }
            update(NSEvent.mouseLocation)
        case .leftMouseUp:
            defer { window = nil; startFrame = nil; mode = .undecided; pending = nil; preview.hide() }
            if mode == .resizing { linked.end(); return }
            guard mode == .moving, ZoneStore.shared.dragSnapEnabled, let w = window, let hit = pending,
                  !e.modifierFlags.contains(.shift) else { return }
            w.setFrame(ScreenGeometry.rect(for: hit.zone, on: hit.screen))
        default: break
        }
    }

    private func update(_ p: NSPoint) {
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(p, $0.frame, false) }),
              let edge = Self.edge(of: p, in: screen.frame) else { pending = nil; preview.hide(); return }
        let portrait = ScreenGeometry.isPortrait(screen)
        guard let zone = ZoneStore.shared.zones.first(where: { $0.dragEdge == edge && $0.applies(toPortrait: portrait) }) else {
            pending = nil; preview.hide(); return
        }
        pending = (zone, screen)
        preview.show(cg: ScreenGeometry.rect(for: zone, on: screen))
    }

    /// Edge or corner a Cocoa-space point is touching. Corners need the point near both edges.
    static func edge(of p: NSPoint, in f: NSRect) -> String? {
        let t: CGFloat = 6, corner: CGFloat = 80
        let l = p.x - f.minX, r = f.maxX - p.x, b = p.y - f.minY, top = f.maxY - p.y
        guard min(l, r, b, top) <= t else { return nil }
        let nearL = l <= corner, nearR = r <= corner, nearT = top <= corner, nearB = b <= corner
        if nearT && nearL { return "topLeft" }
        if nearT && nearR { return "topRight" }
        if nearB && nearL { return "bottomLeft" }
        if nearB && nearR { return "bottomRight" }
        if l <= t { return "left" }
        if r <= t { return "right" }
        if top <= t { return "top" }
        return "bottom"
    }
}

private final class PreviewWindow {
    private let window: NSWindow = {
        let w = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.ignoresMouseEvents = true
        w.level = .floating
        w.hasShadow = false
        w.collectionBehavior = [.canJoinAllSpaces, .stationary]
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.22).cgColor
        v.layer?.borderColor = NSColor.controlAccentColor.withAlphaComponent(0.8).cgColor
        v.layer?.borderWidth = 2
        v.layer?.cornerRadius = 10
        w.contentView = v
        return w
    }()

    func show(cg: CGRect) {
        let ns = NSRect(x: cg.minX, y: ScreenGeometry.primaryHeight - cg.maxY, width: cg.width, height: cg.height).insetBy(dx: 4, dy: 4)
        window.setFrame(ns, display: true)
        window.orderFrontRegardless()
    }

    func hide() { window.orderOut(nil) }
}
