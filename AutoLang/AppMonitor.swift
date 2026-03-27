import AppKit
import Combine
import os

final class AppMonitor: ObservableObject {
    static let shared = AppMonitor()

    @Published var lastSwitchInfo: String?
    @Published var switchCount: Int = 0
    @Published var currentAppName: String = ""

    private let logger = Logger(subsystem: "dev.jenix.AutoLang", category: "AppMonitor")
    private var activationSub: AnyCancellable?
    private var settingsSub: AnyCancellable?
    private var previousSourceID: String?

    private init() {
        loadDailyCount()
    }

    func startMonitoring() {
        guard activationSub == nil else { return }

        activationSub = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleNotification(notification)
            }

        // React to enable/disable toggle
        settingsSub = SettingsManager.shared.$isEnabled
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if enabled {
                    self?.checkFrontmostApp()
                } else {
                    BrowserMonitor.shared.stopPolling()
                }
            }

        checkFrontmostApp()
        logger.info("Monitoring started")
    }

    func stopMonitoring() {
        activationSub?.cancel()
        activationSub = nil
        settingsSub?.cancel()
        settingsSub = nil
        BrowserMonitor.shared.stopPolling()
        logger.info("Monitoring stopped")
    }

    func switchToEnglish(reason: String) {
        if InputSourceManager.isCurrentSourceEnglish() {
            logger.debug("Already English, skipping")
            return
        }

        previousSourceID = InputSourceManager.currentSourceID()

        let settings = SettingsManager.shared
        if InputSourceManager.switchToEnglish(preferredID: settings.preferredEnglishSourceID) {
            incrementCount()
            lastSwitchInfo = "\u{2192} English (\(reason))"
            logger.info("Switched to English: \(reason)")
        }
    }

    // MARK: - Private

    private func checkFrontmostApp() {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleID = app.bundleIdentifier else { return }
        let name = app.localizedName ?? bundleID
        currentAppName = name
        handleAppActivation(bundleID: bundleID, appName: name)
    }

    private func handleNotification(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        let appName = app.localizedName ?? bundleID
        currentAppName = appName
        handleAppActivation(bundleID: bundleID, appName: appName)
    }

    private func handleAppActivation(bundleID: String, appName: String) {
        let settings = SettingsManager.shared
        guard settings.isEnabled else { return }

        let terminalIDs = Set(settings.terminalApps.map(\.bundleID))
        let browserIDs = Set(settings.browserApps.map(\.bundleID))

        if terminalIDs.contains(bundleID) {
            BrowserMonitor.shared.stopPolling()
            switchToEnglish(reason: appName)
        } else if browserIDs.contains(bundleID) {
            BrowserMonitor.shared.startPolling(browserBundleID: bundleID, appName: appName)
        } else {
            BrowserMonitor.shared.stopPolling()
            restoreIfNeeded()
        }
    }

    private func restoreIfNeeded() {
        let settings = SettingsManager.shared
        guard settings.restoreOnLeave, let prevID = previousSourceID else { return }
        previousSourceID = nil
        if InputSourceManager.switchTo(sourceID: prevID) {
            logger.info("Restored previous input source")
        }
    }

    // MARK: - Daily Counter

    private func loadDailyCount() {
        let today = todayString()
        let saved = UserDefaults.standard.string(forKey: "switchCountDate") ?? ""
        if saved == today {
            switchCount = UserDefaults.standard.integer(forKey: "switchCount")
        } else {
            switchCount = 0
            UserDefaults.standard.set(today, forKey: "switchCountDate")
            UserDefaults.standard.set(0, forKey: "switchCount")
        }
    }

    private func incrementCount() {
        switchCount += 1
        UserDefaults.standard.set(switchCount, forKey: "switchCount")
        UserDefaults.standard.set(todayString(), forKey: "switchCountDate")
    }

    private func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
