import Foundation
import Carbon.HIToolbox

/// One snap zone, as fractions of a screen's usable area (origin top-left).
struct Zone: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var x: Double
    var y: Double
    var w: Double
    var h: Double
    var key: String? = nil
    var modifiers: [String] = ["control", "option"]
    var enabled = true
    /// "any", "landscape" or "portrait"
    var orientation = "any"
    /// Screen edge that snaps here while dragging: left, right, top, bottom,
    /// topLeft, topRight, bottomLeft, bottomRight.
    var dragEdge: String? = nil

    func applies(toPortrait portrait: Bool) -> Bool {
        enabled && (orientation == "any" || (orientation == "portrait") == portrait)
    }
}

enum KeyTable {
    static let codes: [String: Int] = {
        var t: [String: Int] = [
            "left": kVK_LeftArrow, "right": kVK_RightArrow, "up": kVK_UpArrow, "down": kVK_DownArrow,
            "return": kVK_Return, "space": kVK_Space, "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal,
        ]
        let letters: [(String, Int)] = [
            ("a", kVK_ANSI_A), ("b", kVK_ANSI_B), ("c", kVK_ANSI_C), ("d", kVK_ANSI_D), ("e", kVK_ANSI_E),
            ("f", kVK_ANSI_F), ("g", kVK_ANSI_G), ("h", kVK_ANSI_H), ("i", kVK_ANSI_I), ("j", kVK_ANSI_J),
            ("k", kVK_ANSI_K), ("l", kVK_ANSI_L), ("m", kVK_ANSI_M), ("n", kVK_ANSI_N), ("o", kVK_ANSI_O),
            ("p", kVK_ANSI_P), ("q", kVK_ANSI_Q), ("r", kVK_ANSI_R), ("s", kVK_ANSI_S), ("t", kVK_ANSI_T),
            ("u", kVK_ANSI_U), ("v", kVK_ANSI_V), ("w", kVK_ANSI_W), ("x", kVK_ANSI_X), ("y", kVK_ANSI_Y),
            ("z", kVK_ANSI_Z),
            ("1", kVK_ANSI_1), ("2", kVK_ANSI_2), ("3", kVK_ANSI_3), ("4", kVK_ANSI_4), ("5", kVK_ANSI_5),
            ("6", kVK_ANSI_6), ("7", kVK_ANSI_7), ("8", kVK_ANSI_8), ("9", kVK_ANSI_9), ("0", kVK_ANSI_0),
        ]
        for (k, v) in letters { t[k] = v }
        return t
    }()

    static var names: [String] { codes.keys.sorted() }

    static func carbonModifiers(_ mods: [String]) -> UInt32 {
        var m: UInt32 = 0
        for mod in mods {
            switch mod {
            case "control": m |= UInt32(controlKey)
            case "option": m |= UInt32(optionKey)
            case "command": m |= UInt32(cmdKey)
            case "shift": m |= UInt32(shiftKey)
            default: break
            }
        }
        return m
    }

    static func symbols(_ mods: [String], _ key: String) -> String {
        var s = ""
        if mods.contains("control") { s += "⌃" }
        if mods.contains("option") { s += "⌥" }
        if mods.contains("shift") { s += "⇧" }
        if mods.contains("command") { s += "⌘" }
        let arrows = ["left": "←", "right": "→", "up": "↑", "down": "↓", "return": "↩", "space": "␣"]
        return s + (arrows[key] ?? key.uppercased())
    }
}

enum DefaultZones {
    static func make() -> [Zone] {
        func z(_ n: String, _ x: Double, _ y: Double, _ w: Double, _ h: Double, key: String? = nil,
               o: String = "any", edge: String? = nil) -> Zone {
            Zone(name: n, x: x, y: y, w: w, h: h, key: key, orientation: o, dragEdge: edge)
        }
        return [
            // landscape
            z("Left half", 0, 0, 0.5, 1, key: "left", o: "landscape", edge: "left"),
            z("Left two-thirds", 0, 0, 2.0 / 3, 1, key: "left", o: "landscape"),
            z("Left third", 0, 0, 1.0 / 3, 1, key: "left", o: "landscape"),
            z("Right half", 0.5, 0, 0.5, 1, key: "right", o: "landscape", edge: "right"),
            z("Right two-thirds", 1.0 / 3, 0, 2.0 / 3, 1, key: "right", o: "landscape"),
            z("Right third", 2.0 / 3, 0, 1.0 / 3, 1, key: "right", o: "landscape"),
            z("Top half", 0, 0, 1, 0.5, key: "up", o: "landscape"),
            z("Bottom half", 0, 0.5, 1, 0.5, key: "down", o: "landscape"),
            // portrait: stack windows top and bottom
            z("Top half ", 0, 0, 1, 0.5, key: "up", o: "portrait", edge: "top"),
            z("Top third", 0, 0, 1, 1.0 / 3, key: "up", o: "portrait"),
            z("Top two-thirds", 0, 0, 1, 2.0 / 3, key: "up", o: "portrait"),
            z("Bottom half ", 0, 0.5, 1, 0.5, key: "down", o: "portrait", edge: "bottom"),
            z("Bottom third", 0, 2.0 / 3, 1, 1.0 / 3, key: "down", o: "portrait"),
            z("Bottom two-thirds", 0, 1.0 / 3, 1, 2.0 / 3, key: "down", o: "portrait"),
            z("Middle third", 0, 1.0 / 3, 1, 1.0 / 3, key: "m", o: "portrait"),
            z("Left half ", 0, 0, 0.5, 1, key: "left", o: "portrait", edge: "left"),
            z("Right half ", 0.5, 0, 0.5, 1, key: "right", o: "portrait", edge: "right"),
            // any orientation
            z("Top left", 0, 0, 0.5, 0.5, key: "u", edge: "topLeft"),
            z("Top right", 0.5, 0, 0.5, 0.5, key: "i", edge: "topRight"),
            z("Bottom left", 0, 0.5, 0.5, 0.5, key: "j", edge: "bottomLeft"),
            z("Bottom right", 0.5, 0.5, 0.5, 0.5, key: "k", edge: "bottomRight"),
            z("Center", 0.15, 0.1, 0.7, 0.8, key: "c"),
            z("Maximize", 0, 0, 1, 1, key: "return", o: "landscape", edge: "top"),
            z("Maximize ", 0, 0, 1, 1, key: "return", o: "portrait"),
        ]
    }
}
