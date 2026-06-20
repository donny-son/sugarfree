import KeyboardShortcuts

/// The bindable global hotkeys, as `KeyboardShortcuts.Name`s.
///
/// Each name owns its default combo and its persistence: KeyboardShortcuts stores any user
/// change in `UserDefaults` under a `KeyboardShortcuts_<name>` key automatically, so there's
/// no separate `DefaultsKey` for shortcuts.
///
/// Defaults use control+option (`⌃⌥`) rather than `⌘⇧`: the `⌘⇧P`/`⌘⇧K`/`⌘⇧S` combos collide
/// with common editor shortcuts (command palette, delete-line, Save As), whereas `⌃⌥` is
/// rarely claimed. Users can rebind any of them from the dashboard's Shortcuts section.
///
/// Handlers are wired where the action lives: `PasteboardMonitor` owns `toggleCleanup` /
/// `cleanNow`; `MenuBarStatusItemController` owns `togglePopover` (it owns the popover).
extension KeyboardShortcuts.Name {
    /// Toggle automatic cleanup on/off. Default `⌃⌥P`.
    static let toggleCleanup = Self("toggleCleanup", default: .init(.p, modifiers: [.control, .option]))

    /// Clean the clipboard right now. Default `⌃⌥K`.
    static let cleanNow = Self("cleanNow", default: .init(.k, modifiers: [.control, .option]))

    /// Open/toggle the menu-bar dashboard popover. Default `⌃⌥S` (S = Sugarfree).
    static let togglePopover = Self("togglePopover", default: .init(.s, modifiers: [.control, .option]))
}
