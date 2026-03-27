import Carbon
import os

final class InputSourceManager {
    private static let logger = Logger(subsystem: "dev.jenix.AutoLang", category: "InputSource")

    static func currentSourceID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return sourceID(of: source)
    }

    static func currentSourceName() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return sourceName(of: source)
    }

    @discardableResult
    static func switchToEnglish(preferredID: String? = nil) -> Bool {
        if let preferredID, switchTo(sourceID: preferredID) {
            logger.info("Switched to preferred English source")
            return true
        }

        guard let sources = enabledKeyboardSources() else {
            logger.warning("Could not get keyboard sources")
            return false
        }

        for source in sources {
            let langs = sourceLanguages(of: source)
            guard langs.first == "en" else { continue }

            let status = TISSelectInputSource(source)
            if status == noErr {
                let name = sourceName(of: source) ?? "unknown"
                logger.info("Switched to English: \(name)")
                return true
            }
        }

        logger.warning("No English input source found")
        return false
    }

    @discardableResult
    static func switchTo(sourceID: String) -> Bool {
        guard let sources = enabledKeyboardSources() else { return false }

        for source in sources {
            guard self.sourceID(of: source) == sourceID else { continue }
            return TISSelectInputSource(source) == noErr
        }
        return false
    }

    static func englishSources() -> [(id: String, name: String)] {
        guard let sources = enabledKeyboardSources() else { return [] }

        return sources.compactMap { source in
            let langs = sourceLanguages(of: source)
            guard langs.contains("en"),
                  let id = sourceID(of: source),
                  let name = sourceName(of: source) else { return nil }
            return (id: id, name: name)
        }
    }

    static func isCurrentSourceEnglish() -> Bool {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return false }
        return sourceLanguages(of: source).first == "en"
    }

    // MARK: - Private

    private static func enabledKeyboardSources() -> [TISInputSource]? {
        let conditions: [CFString: Any] = [
            kTISPropertyInputSourceCategory!: kTISCategoryKeyboardInputSource!,
            kTISPropertyInputSourceIsEnabled!: true,
            kTISPropertyInputSourceIsSelectCapable!: true,
        ]
        guard let list = TISCreateInputSourceList(conditions as CFDictionary, false)?
            .takeRetainedValue() as? [TISInputSource] else {
            return nil
        }
        return list
    }

    private static func sourceID(of source: TISInputSource) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private static func sourceName(of source: TISInputSource) -> String? {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }

    private static func sourceLanguages(of source: TISInputSource) -> [String] {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return [] }
        return Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as? [String] ?? []
    }
}
