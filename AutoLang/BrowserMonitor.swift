import Foundation
import os

final class BrowserMonitor {
    static let shared = BrowserMonitor()

    private let logger = Logger(subsystem: "dev.jenix.AutoLang", category: "Browser")
    private var timer: Timer?
    private var activeBrowserID: String?
    private var activeBrowserName: String?
    private var lastCheckedURL: String?
    private var compiledScripts: [String: NSAppleScript] = [:]

    private init() {}

    func startPolling(browserBundleID: String, appName: String) {
        if activeBrowserID == browserBundleID, timer != nil { return }

        stopPolling()
        activeBrowserID = browserBundleID
        activeBrowserName = appName

        checkCurrentURL()

        let interval = SettingsManager.shared.browserPollInterval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkCurrentURL()
        }

        logger.info("Started polling \(appName) every \(interval)s")
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        activeBrowserID = nil
        activeBrowserName = nil
        lastCheckedURL = nil
    }

    var isPolling: Bool { timer != nil }

    // MARK: - Private

    private func checkCurrentURL() {
        guard let browserID = activeBrowserID else { return }
        guard let url = executeURLScript(for: browserID) else { return }
        guard url != lastCheckedURL else { return }

        lastCheckedURL = url

        let patterns = SettingsManager.shared.devURLPatterns
        if let matched = patterns.first(where: { url.contains($0) }) {
            let reason = "\(activeBrowserName ?? "Browser") \u{2014} \(matched)"
            AppMonitor.shared.switchToEnglish(reason: reason)
        }
    }

    private func executeURLScript(for bundleID: String) -> String? {
        guard let script = getOrCompileScript(for: bundleID) else { return nil }

        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }

    private func getOrCompileScript(for bundleID: String) -> NSAppleScript? {
        if let cached = compiledScripts[bundleID] { return cached }

        guard let source = scriptSource(for: bundleID),
              let script = NSAppleScript(source: source) else { return nil }

        var error: NSDictionary?
        script.compileAndReturnError(&error)
        if error != nil {
            logger.warning("Script compile error for \(bundleID)")
            return nil
        }

        compiledScripts[bundleID] = script
        return script
    }

    private func scriptSource(for bundleID: String) -> String? {
        let scripts: [String: String] = [
            "com.google.Chrome": """
                tell application "Google Chrome"
                    if (count of windows) > 0 then return URL of active tab of first window
                end tell
                """,
            "com.apple.Safari": """
                tell application "Safari"
                    if (count of windows) > 0 then return URL of current tab of first window
                end tell
                """,
            "company.thebrowser.Browser": """
                tell application "Arc"
                    if (count of windows) > 0 then return URL of active tab of first window
                end tell
                """,
            "com.brave.Browser": """
                tell application "Brave Browser"
                    if (count of windows) > 0 then return URL of active tab of first window
                end tell
                """,
            "com.microsoft.edgemac": """
                tell application "Microsoft Edge"
                    if (count of windows) > 0 then return URL of active tab of first window
                end tell
                """,
        ]
        return scripts[bundleID]
    }
}
