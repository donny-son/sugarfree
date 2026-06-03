import SwiftUI

@main
struct SugarfreeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = PasteboardMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarDashboard(monitor: monitor)
        } label: {
            MenuBarStatusIcon(state: monitor.interfaceState)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandMenu("Sugarfree") {
                Button(monitor.isEnabled ? "Pause Automatic Cleanup" : "Resume Automatic Cleanup") {
                    monitor.isEnabled.toggle()
                }
                .keyboardShortcut("P", modifiers: [.command, .shift])

                Button("Clean Clipboard Now") {
                    monitor.cleanClipboardManually()
                }
                .keyboardShortcut("k", modifiers: [.command, .shift])
                .disabled(!monitor.hasEnabledFormats)
            }
        }

        Settings {
            SettingsView(monitor: monitor)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !UserDefaults.standard.bool(forKey: Self.hasCompletedOnboardingKey) else {
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
    }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        UserDefaults.standard.set(true, forKey: Self.hasCompletedOnboardingKey)
        onboardingWindow = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
