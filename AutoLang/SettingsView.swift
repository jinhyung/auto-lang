import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsManager

    var body: some View {
        TabView {
            GeneralTab()
                .environmentObject(settings)
                .tabItem { Label("General", systemImage: "gear") }

            AppsTab()
                .environmentObject(settings)
                .tabItem { Label("Apps", systemImage: "app.badge") }

            WebsitesTab()
                .environmentObject(settings)
                .tabItem { Label("Websites", systemImage: "globe") }
        }
        .frame(width: 520, height: 420)
    }
}

// MARK: - General

struct GeneralTab: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var englishSources: [(id: String, name: String)] = []

    var body: some View {
        Form {
            Section {
                Toggle("Enable AutoLang", isOn: $settings.isEnabled)
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Restore previous input when leaving app", isOn: $settings.restoreOnLeave)
            }

            Section("English Input Source") {
                Picker("Preferred source:", selection: preferredBinding) {
                    Text("Auto (first available)").tag("")
                    ForEach(englishSources, id: \.id) { source in
                        Text(source.name).tag(source.id)
                    }
                }
            }

            Section("Browser Monitoring") {
                HStack {
                    Text("Check URL every")
                    TextField("", value: $settings.browserPollInterval, format: .number)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                    Text("seconds")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            englishSources = InputSourceManager.englishSources()
        }
    }

    private var preferredBinding: Binding<String> {
        Binding(
            get: { settings.preferredEnglishSourceID ?? "" },
            set: { settings.preferredEnglishSourceID = $0.isEmpty ? nil : $0 }
        )
    }
}

// MARK: - Apps

struct AppsTab: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var selectedTerminal: String?
    @State private var selectedBrowser: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            appSection(
                title: "Always switch to English:",
                apps: $settings.terminalApps,
                selection: $selectedTerminal
            )

            appSection(
                title: "Monitor URLs in these browsers:",
                apps: $settings.browserApps,
                selection: $selectedBrowser
            )
        }
        .padding()
    }

    @ViewBuilder
    private func appSection(
        title: String,
        apps: Binding<[SettingsManager.AppInfo]>,
        selection: Binding<String?>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)

            List(selection: selection) {
                ForEach(apps.wrappedValue) { app in
                    HStack {
                        Text(app.name)
                        Spacer()
                        Text(app.bundleID)
                            .foregroundStyle(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                    .tag(app.bundleID)
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))
            .frame(minHeight: 80)

            HStack(spacing: 4) {
                Button(action: { pickApp(into: apps) }) {
                    Image(systemName: "plus")
                }
                Button(action: { removeApp(id: selection.wrappedValue, from: apps); selection.wrappedValue = nil }) {
                    Image(systemName: "minus")
                }
                .disabled(selection.wrappedValue == nil)
            }
        }
    }

    private func pickApp(into list: Binding<[SettingsManager.AppInfo]>) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundle = Bundle(url: url)
        let bundleID = bundle?.bundleIdentifier
            ?? url.deletingPathExtension().lastPathComponent
        let name = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent

        guard !list.wrappedValue.contains(where: { $0.bundleID == bundleID }) else { return }
        list.wrappedValue.append(SettingsManager.AppInfo(bundleID: bundleID, name: name))
    }

    private func removeApp(id: String?, from list: Binding<[SettingsManager.AppInfo]>) {
        guard let id else { return }
        list.wrappedValue.removeAll(where: { $0.bundleID == id })
    }
}

// MARK: - Websites

struct WebsitesTab: View {
    @EnvironmentObject var settings: SettingsManager
    @State private var newPattern = ""
    @State private var selectedPattern: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Switch to English when browser URL contains:")
                .font(.headline)

            List(selection: $selectedPattern) {
                ForEach(settings.devURLPatterns, id: \.self) { pattern in
                    Text(pattern)
                        .font(.system(.body, design: .monospaced))
                        .tag(pattern)
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            HStack(spacing: 8) {
                TextField("e.g. github.com", text: $newPattern)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addPattern)

                Button(action: addPattern) {
                    Image(systemName: "plus")
                }
                .disabled(newPattern.trimmingCharacters(in: .whitespaces).isEmpty)

                Button(action: removeSelected) {
                    Image(systemName: "minus")
                }
                .disabled(selectedPattern == nil)
            }

            Text("Patterns are matched anywhere in the URL. For example, \"github.com\" matches any GitHub page.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func addPattern() {
        let pattern = newPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pattern.isEmpty, !settings.devURLPatterns.contains(pattern) else { return }
        settings.devURLPatterns.append(pattern)
        newPattern = ""
    }

    private func removeSelected() {
        guard let sel = selectedPattern else { return }
        settings.devURLPatterns.removeAll(where: { $0 == sel })
        selectedPattern = nil
    }
}
