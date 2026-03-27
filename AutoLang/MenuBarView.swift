import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var settings: SettingsManager
    @EnvironmentObject var appMonitor: AppMonitor

    var body: some View {
        Toggle("Enabled", isOn: $settings.isEnabled)

        Divider()

        if let info = appMonitor.lastSwitchInfo {
            Text(info)
        }

        Text("Switches today: \(appMonitor.switchCount)")

        if let sourceName = InputSourceManager.currentSourceName() {
            Text("Current: \(sourceName)")
        }

        Divider()

        Button("Settings...") {
            NotificationCenter.default.post(name: .openSettings, object: nil)
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit AutoLang") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}
