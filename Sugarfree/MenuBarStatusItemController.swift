import AppKit
import Combine
import KeyboardShortcuts
import SwiftUI

/// Owns Sugarfree's menu-bar presence as a real `NSStatusItem` instead of SwiftUI's
/// `MenuBarExtra`.
///
/// Why we don't use `MenuBarExtra`: it snapshots its label into a *template* image
/// (`isTemplate = true`), so macOS strips every color to a single monochrome tint. That makes
/// the state dot (cotton = active, amber = idle) and the crush shards render flat — active and
/// idle become indistinguishable. Drawing the icon ourselves and setting `isTemplate = false`
/// keeps the indicator color. The lollipop glyph still adapts to light/dark because we render
/// it in the menu bar's current appearance (`Color.primary` resolves against that scheme).
@MainActor
final class MenuBarStatusItemController: NSObject {
    private let monitor: PasteboardMonitor
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let crush = CrushAnimator()

    private var cancellables = Set<AnyCancellable>()
    private var appearanceObservation: NSKeyValueObservation?
    private var lastRender: (state: MonitorInterfaceState, progress: Double, dark: Bool)?

    init(monitor: PasteboardMonitor) {
        self.monitor = monitor
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureButton()
        configurePopover()
        registerPopoverHotkey()
        observe()
        renderIcon()
    }

    /// Bind the user-configurable "open dashboard" global hotkey (default ⌘⇧S) to the same
    /// toggle the menu-bar button uses. Lives here because this controller owns the popover.
    private func registerPopoverHotkey() {
        KeyboardShortcuts.onKeyUp(for: .togglePopover) { [weak self] in
            self?.togglePopover(nil)
        }
    }

    // MARK: - Setup

    private func configureButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover(_:))
        // The glyph is drawn in the menu bar's color scheme, so re-render when that flips
        // (e.g. the user toggles light/dark while the state is otherwise unchanged).
        appearanceObservation = button.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            Task { @MainActor in self?.renderIcon() }
        }
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarDashboard(monitor: monitor))
    }

    private func observe() {
        // Any monitor change can shift `interfaceState`; re-render on the next runloop pass,
        // once the published value has settled. Cheap — deduped against the last render inputs.
        monitor.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.renderIcon() }
            .store(in: &cancellables)

        // Kick the crush keyframe on each clean (skip the initial published value at launch).
        monitor.$cleanupPulse
            .dropFirst()
            .sink { [weak self] _ in self?.crush.start() }
            .store(in: &cancellables)

        // Each animation frame advances `progress`; redraw the status image to match. This is
        // the "snapshot" we own — no reliance on MenuBarExtra's implicit re-snapshot heuristics.
        crush.$progress
            .sink { [weak self] _ in self?.renderIcon() }
            .store(in: &cancellables)
    }

    // MARK: - Rendering

    private func renderIcon() {
        guard let button = statusItem.button else { return }
        let isDark = button.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let state = monitor.interfaceState
        let progress = crush.progress

        if let last = lastRender, last.state == state, last.progress == progress, last.dark == isDark {
            return
        }
        lastRender = (state, progress, isDark)

        let renderer = ImageRenderer(
            content: MenuBarIcon(state: state, progress: progress)
                .environment(\.colorScheme, isDark ? .dark : .light)
        )
        renderer.scale = 2
        guard let image = renderer.nsImage else { return }
        image.isTemplate = false   // keep our colors — do not let macOS monochrome the icon
        button.image = image
        button.setAccessibilityLabel(accessibilityLabel(for: state))
    }

    private func accessibilityLabel(for state: MonitorInterfaceState) -> String {
        switch state {
        case .active: return "Sugarfree active"
        case .paused: return "Sugarfree paused"
        case .idle:   return "Sugarfree needs a format enabled"
        }
    }

    // MARK: - Popover

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

/// Timer-driven keyframe for the menu-bar crush cue. `progress` rests at `1` (plain glyph) and
/// runs `0 → 1` over `duration` whenever `start()` is called. The controller observes
/// `$progress` and re-renders the status image each tick.
@MainActor
final class CrushAnimator: ObservableObject {
    @Published private(set) var progress: Double = 1

    private var timer: Timer?
    private var startedAt: Date?
    private let duration: Double = 0.62
    private let frameInterval: Double = 1.0 / 30.0

    func start() {
        stop()
        startedAt = Date()
        progress = 0

        let timer = Timer(timeInterval: frameInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let startedAt = self.startedAt else { return }
                let elapsed = Date().timeIntervalSince(startedAt)
                self.progress = min(1, elapsed / self.duration)
                if self.progress >= 1 {
                    self.stop()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        startedAt = nil
    }
}
