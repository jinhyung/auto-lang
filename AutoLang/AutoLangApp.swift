import SwiftUI

@main
struct AutoLangApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("AutoLang", systemImage: "globe") {
            MenuBarView()
                .environmentObject(SettingsManager.shared)
                .environmentObject(AppMonitor.shared)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppMonitor.shared.startMonitoring()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettings),
            name: .openSettings,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppMonitor.shared.stopMonitoring()
    }

    @objc private func openSettings() {
        // Defer to next run loop so the menu fully dismisses first
        DispatchQueue.main.async { [weak self] in
            self?.showSettingsWindow()
        }
    }

    private func showSettingsWindow() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(SettingsManager.shared)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "AutoLang Settings"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        self.settingsWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
