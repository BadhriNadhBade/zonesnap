import SwiftUI

struct SettingsView: View {
    @ObservedObject var store = ZoneStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zones").font(.title2.bold())
            Text("Positions are fractions of the screen, from the top-left. Zones that share a shortcut cycle when you press it again. Hold Shift while dragging to skip snapping.")
                .font(.caption).foregroundColor(.secondary)
            List {
                ForEach($store.zones) { $zone in
                    ZoneRow(zone: $zone)
                    Divider()
                }
                .onDelete { store.zones.remove(atOffsets: $0) }
            }
            HStack {
                Button("Add zone") { store.addZone() }
                Button("Reset to defaults") { store.resetToDefaults() }
                Spacer()
                Toggle("Neighbors follow resizing", isOn: $store.linkedResizeEnabled)
                Toggle("Snap when dragging to edges", isOn: $store.dragSnapEnabled)
            }
        }
        .padding(16)
        .frame(minWidth: 760, minHeight: 520)
    }
}

private struct ZoneRow: View {
    @Binding var zone: Zone
    private let edges = ["", "left", "right", "top", "bottom", "topLeft", "topRight", "bottomLeft", "bottomRight"]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Toggle("", isOn: $zone.enabled).labelsHidden()
                TextField("Name", text: $zone.name).frame(width: 150)
                Picker("", selection: $zone.orientation) {
                    Text("Any screen").tag("any")
                    Text("Landscape only").tag("landscape")
                    Text("Vertical only").tag("portrait")
                }.labelsHidden().frame(width: 140)
                Picker("Key", selection: Binding(get: { zone.key ?? "" }, set: { zone.key = $0.isEmpty ? nil : $0 })) {
                    Text("None").tag("")
                    ForEach(KeyTable.names, id: \.self) { Text($0.uppercased()).tag($0) }
                }.frame(width: 110)
                ForEach(["control", "option", "shift", "command"], id: \.self) { mod in
                    Toggle(Self.symbol(mod), isOn: Binding(
                        get: { zone.modifiers.contains(mod) },
                        set: { on in
                            zone.modifiers.removeAll { $0 == mod }
                            if on { zone.modifiers.append(mod) }
                        })).toggleStyle(.checkbox)
                }
            }
            HStack {
                field("X", $zone.x); field("Y", $zone.y); field("W", $zone.w); field("H", $zone.h)
                Picker("Drag edge", selection: Binding(get: { zone.dragEdge ?? "" }, set: { zone.dragEdge = $0.isEmpty ? nil : $0 })) {
                    ForEach(edges, id: \.self) { Text($0.isEmpty ? "None" : $0).tag($0) }
                }.frame(width: 190)
            }
        }
        .padding(.vertical, 4)
    }

    private func field(_ label: String, _ value: Binding<Double>) -> some View {
        HStack(spacing: 4) {
            Text(label).foregroundColor(.secondary)
            TextField("", value: value, format: .number.precision(.fractionLength(0...3))).frame(width: 56)
        }
    }

    private static func symbol(_ mod: String) -> String {
        ["control": "⌃", "option": "⌥", "shift": "⇧", "command": "⌘"][mod] ?? mod
    }
}
