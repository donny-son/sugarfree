import AppKit
import SwiftUI

@main
struct SugarfreeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The menu bar is driven entirely by an AppKit `NSStatusItem` (see
        // `MenuBarStatusItemController`) so the icon can render in color. This empty Settings
        // scene just gives the `App` a valid (window-less) body for the `LSUIElement` agent.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let monitor = PasteboardMonitor()
    private var statusController: MenuBarStatusItemController?
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = MenuBarStatusItemController(monitor: monitor)

        guard !UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey) else {
            // Returning user (including the first launch after an update): make sure
            // the bundled CLI is linked onto PATH. Runs at most once per machine.
            CLIInstaller.installIfNeeded()
            return
        }
        // Delay so the app finishes launching and can properly activate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showOnboarding()
        }
    }

    private func showOnboarding() {
        let onboardingView = OnboardingView { [weak self] in
            self?.dismissOnboarding()
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to Sugarfree"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.setContentSize(NSSize(width: 400, height: 480))
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.delegate = self

        self.onboardingWindow = window

        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // Ensure the window is on top after activation settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            window.orderFrontRegardless()
        }
    }

    private func dismissOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        onboardingWindow?.close()
        onboardingWindow = nil
        NSApp.setActivationPolicy(.accessory)
        // First run done — now link the bundled CLI onto PATH (may prompt for admin).
        CLIInstaller.installIfNeeded()
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        onboardingWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
