import Foundation
import ServiceManagement
import os

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: "dev.jenix.AutoLang", category: "Settings")

    struct AppInfo: Codable, Identifiable, Hashable {
        var id: String { bundleID }
        let bundleID: String
        let name: String
    }

    // MARK: - Published Settings

    @Published var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLoginItem()
        }
    }

    @Published var restoreOnLeave: Bool {
        didSet { defaults.set(restoreOnLeave, forKey: Keys.restoreOnLeave) }
    }

    @Published var preferredEnglishSourceID: String? {
        didSet { defaults.set(preferredEnglishSourceID, forKey: Keys.preferredSourceID) }
    }

    @Published var browserPollInterval: Double {
        didSet { defaults.set(browserPollInterval, forKey: Keys.pollInterval) }
    }

    @Published var terminalApps: [AppInfo] {
        didSet { saveJSON(terminalApps, forKey: Keys.terminalApps) }
    }

    @Published var browserApps: [AppInfo] {
        didSet { saveJSON(browserApps, forKey: Keys.browserApps) }
    }

    @Published var devURLPatterns: [String] {
        didSet { defaults.set(devURLPatterns, forKey: Keys.devPatterns) }
    }

    // MARK: - Keys

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let launchAtLogin = "launchAtLogin"
        static let restoreOnLeave = "restoreOnLeave"
        static let preferredSourceID = "preferredEnglishSourceID"
        static let pollInterval = "browserPollInterval"
        static let terminalApps = "terminalApps"
        static let browserApps = "browserApps"
        static let devPatterns = "devURLPatterns"
    }

    // MARK: - Defaults

    static let defaultTerminalApps: [AppInfo] = [
        AppInfo(bundleID: "com.apple.Terminal", name: "Terminal"),
        AppInfo(bundleID: "com.mitchellh.ghostty", name: "Ghostty"),
    ]

    static let defaultBrowserApps: [AppInfo] = [
        AppInfo(bundleID: "com.apple.Safari", name: "Safari"),
        AppInfo(bundleID: "com.google.Chrome", name: "Google Chrome"),
        AppInfo(bundleID: "company.thebrowser.Browser", name: "Arc"),
    ]

    static let defaultDevPatterns: [String] = [
        "github.com",
        "graphite.dev",
        "gitlab.com",
        "stackoverflow.com",
    ]

    // MARK: - Init

    private init() {
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        self.restoreOnLeave = defaults.object(forKey: Keys.restoreOnLeave) as? Bool ?? false
        self.preferredEnglishSourceID = defaults.string(forKey: Keys.preferredSourceID)
        self.browserPollInterval = defaults.object(forKey: Keys.pollInterval) as? Double ?? 2.0
        self.terminalApps = Self.loadJSON(forKey: Keys.terminalApps) ?? Self.defaultTerminalApps
        self.browserApps = Self.loadJSON(forKey: Keys.browserApps) ?? Self.defaultBrowserApps
        self.devURLPatterns = defaults.stringArray(forKey: Keys.devPatterns) ?? Self.defaultDevPatterns

        logger.info("Settings loaded")
    }

    // MARK: - Persistence

    private func saveJSON<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func loadJSON<T: Decodable>(forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Login Item

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
                logger.info("Registered login item")
            } else {
                try SMAppService.mainApp.unregister()
                logger.info("Unregistered login item")
            }
        } catch {
            logger.error("Login item update failed: \(error.localizedDescription)")
        }
    }
}
