import AppKit
import Carbon.HIToolbox

/// Registers system-wide hotkeys via Carbon's `RegisterEventHotKey`.
///
/// SwiftUI `.keyboardShortcut` commands only fire while the app is frontmost. Sugarfree is
/// an `LSUIElement` menu-bar accessory that is essentially never the active app, so those
/// command shortcuts never reached it — the cleanup hotkeys looked dead. Carbon hotkeys are
/// global: they fire regardless of which app is in front, which is what a menu-bar utility
/// needs. One process-wide event handler fans out to per-hotkey closures keyed by id.
@MainActor
final class GlobalHotkeyCenter {
    static let shared = GlobalHotkeyCenter()

    private struct Registration {
        let ref: EventHotKeyRef
        let handler: () -> Void
    }

    private var registrations: [UInt32: Registration] = [:]
    private var eventHandler: EventHandlerRef?
    private var nextID: UInt32 = 1

    /// Four-char code 'SGRF' identifying this app's hotkeys.
    private static let signature: OSType = 0x5347_5246

    private init() {}

    /// Register a global hotkey. `keyCode` is a Carbon virtual key code (e.g. `kVK_ANSI_K`);
    /// `modifiers` is a Carbon modifier mask (e.g. `cmdKey | shiftKey`). Returns whether the
    /// registration succeeded (it can fail if another app already owns the combination).
    @discardableResult
    func register(keyCode: Int, modifiers: Int, handler: @escaping () -> Void) -> Bool {
        installEventHandlerIfNeeded()

        let id = nextID
        nextID += 1

        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        guard status == noErr, let ref else { return false }
        registrations[id] = Registration(ref: ref, handler: handler)
        return true
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        // A `@convention(c)` callback captures nothing — it reads the fired hotkey's id and
        // hops to the main actor to run the matching handler on the shared center.
        let callback: EventHandlerUPP = { _, eventRef, _ in
            guard let eventRef else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr else { return status }

            let id = hotKeyID.id
            Task { @MainActor in
                GlobalHotkeyCenter.shared.fire(id)
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            &eventType,
            nil,
            &eventHandler
        )
    }

    private func fire(_ id: UInt32) {
        registrations[id]?.handler()
    }
}
