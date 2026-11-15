import AppKit
import Carbon.HIToolbox
import Combine

/// Global shortcuts through Carbon, which needs no extra permission.
final class HotkeyCenter {
    static let shared = HotkeyCenter()
    private var refs: [EventHotKeyRef] = []
    private var groups: [UInt32: [UUID]] = [:]
    private var handlerInstalled = false
    private var cancellable: AnyCancellable?

    func start() {
        installHandler()
        register()
        cancellable = ZoneStore.shared.$zones.dropFirst().receive(on: DispatchQueue.main).sink { [weak self] _ in self?.register() }
    }

    private func installHandler() {
        guard !handlerInstalled else { return }
        handlerInstalled = true
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ in
            var hk = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                              nil, MemoryLayout<EventHotKeyID>.size, nil, &hk)
            HotkeyCenter.shared.fire(hk.id)
            return noErr
        }, 1, &spec, nil, nil)
    }

    private func register() {
        for ref in refs { UnregisterEventHotKey(ref) }
        refs.removeAll()
        groups.removeAll()
        var byChord: [String: (code: Int, mods: UInt32, ids: [UUID])] = [:]
        for zone in ZoneStore.shared.zones where zone.enabled {
            guard let key = zone.key, let code = KeyTable.codes[key] else { continue }
            let mods = KeyTable.carbonModifiers(zone.modifiers)
            let chord = "\(code)-\(mods)"
            var entry = byChord[chord] ?? (code, mods, [])
            entry.ids.append(zone.id)
            byChord[chord] = entry
        }
        var next: UInt32 = 1
        for (_, entry) in byChord {
            var ref: EventHotKeyRef?
            let id = EventHotKeyID(signature: OSType(0x5A4E5350), id: next)
            if RegisterEventHotKey(UInt32(entry.code), entry.mods, id, GetApplicationEventTarget(), 0, &ref) == noErr, let ref = ref {
                refs.append(ref)
                groups[next] = entry.ids
            }
            next += 1
        }
    }

    fileprivate func fire(_ id: UInt32) {
        guard let ids = groups[id] else { return }
        let zones = ZoneStore.shared.zones
        let group = ids.compactMap { zid in zones.first { $0.id == zid } }
        DispatchQueue.main.async { Snapper.trigger(group: group) }
    }
}
