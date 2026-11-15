import AppKit

/// While a window's edge is dragged, windows touching that edge follow it, so
/// the gap closes (or the neighbor shrinks) instead of leaving a hole.
final class LinkedResize {
    private enum Edge { case left, right, top, bottom }

    private struct Neighbor {
        let window: AXWindow
        let start: CGRect
        /// Neighbor edge -> (dragged edge it follows, gap that was between them)
        let links: [(mine: Edge, follows: Edge, gap: CGFloat)]
    }

    private static let tolerance: CGFloat = 24
    private static let minSide: CGFloat = 120

    private var dragged: AXWindow?
    private var start = CGRect.zero
    private var neighbors: [Neighbor] = []
    private var lastApply = Date.distantPast

    func begin(dragged: AXWindow, start: CGRect) {
        self.dragged = dragged
        self.start = start
        neighbors = AXWindow.otherVisible(excluding: dragged).compactMap { win in
            guard let f = win.frame else { return nil }
            var links: [(Edge, Edge, CGFloat)] = []
            let vOverlap = min(start.maxY, f.maxY) - max(start.minY, f.minY)
            let hOverlap = min(start.maxX, f.maxX) - max(start.minX, f.minX)
            let tol = Self.tolerance
            if vOverlap > 0.4 * min(start.height, f.height) {
                if abs(f.minX - start.maxX) <= tol { links.append((.left, .right, f.minX - start.maxX)) }
                if abs(f.maxX - start.minX) <= tol { links.append((.right, .left, start.minX - f.maxX)) }
            }
            if hOverlap > 0.4 * min(start.width, f.width) {
                if abs(f.minY - start.maxY) <= tol { links.append((.top, .bottom, f.minY - start.maxY)) }
                if abs(f.maxY - start.minY) <= tol { links.append((.bottom, .top, start.minY - f.maxY)) }
            }
            return links.isEmpty ? nil : Neighbor(window: win, start: f, links: links)
        }
    }

    var isActive: Bool { dragged != nil && !neighbors.isEmpty }

    /// Applies the neighbors' new frames; throttled unless `force`.
    func update(force: Bool = false) {
        guard let dragged = dragged, !neighbors.isEmpty, let now = dragged.frame else { return }
        if !force && Date().timeIntervalSince(lastApply) < 0.03 { return }
        lastApply = Date()
        for n in neighbors {
            var minX = n.start.minX, maxX = n.start.maxX, minY = n.start.minY, maxY = n.start.maxY
            for link in n.links {
                switch (link.mine, link.follows) {
                case (.left, .right) where abs(now.maxX - start.maxX) > 0.5: minX = now.maxX + link.gap
                case (.right, .left) where abs(now.minX - start.minX) > 0.5: maxX = now.minX - link.gap
                case (.top, .bottom) where abs(now.maxY - start.maxY) > 0.5: minY = now.maxY + link.gap
                case (.bottom, .top) where abs(now.minY - start.minY) > 0.5: maxY = now.minY - link.gap
                default: break
                }
            }
            // never collapse a neighbor: stop the moving edge at the minimum size
            if maxX - minX < Self.minSide { if minX != n.start.minX { minX = maxX - Self.minSide } else { maxX = minX + Self.minSide } }
            if maxY - minY < Self.minSide { if minY != n.start.minY { minY = maxY - Self.minSide } else { maxY = minY + Self.minSide } }
            let target = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            if target != n.start || n.window.frame != n.start { n.window.setFrame(target) }
        }
    }

    func end() {
        update(force: true)
        dragged = nil
        neighbors = []
    }
}
