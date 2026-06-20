import KeyboardShortcuts

/// The bindable global hotkeys, as `KeyboardShortcuts.Name`s.
///
/// Each name owns its default combo and its persistence: KeyboardShortcuts stores any user
/// change in `UserDefaults` under a `KeyboardShortcuts_<name>` key automatically, so there's
/// no separate `DefaultsKey` for shortcuts. The defaults below preserve the app's original
/// hardcoded bindings (`⌘⇧P`, `⌘⇧K`); `togglePopover` is new.
///
/// Handlers are wired where the action lives: `PasteboardMonitor` owns `toggleCleanup` /
/// `cleanNow`; `MenuBarStatusItemController` owns `togglePopover` (it owns the popover).
extension KeyboardShortcuts.Name {
    /// Toggle automatic cleanup on/off. Default `⌘⇧P`.
    static let toggleCleanup = Self("toggleCleanup", default: .init(.p, modifiers: [.command, .shift]))

    /// Clean the clipboard right now. Default `⌘⇧K`.
    static let cleanNow = Self("cleanNow", default: .init(.k, modifiers: [.command, .shift]))

    /// Open/toggle the menu-bar dashboard popover. Default `⌘⇧S` (S = Sugarfree).
    static let togglePopover = Self("togglePopover", default: .init(.s, modifiers: [.command, .shift]))
}
