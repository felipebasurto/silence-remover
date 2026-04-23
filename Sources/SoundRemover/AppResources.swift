import AppKit
import Foundation

enum AppResources {
    static func localizedString(_ key: String) -> String {
        let main = Bundle.main.localizedString(forKey: key, value: nil, table: nil)
        if main != key {
            return main
        }

        let bundle = developmentResourceBundle()
        return bundle?.localizedString(forKey: key, value: key, table: nil) ?? key
    }

    static func image(named name: String, extension ext: String) -> NSImage? {
        if let mainURL = Bundle.main.resourceURL?.appendingPathComponent("\(name).\(ext)"),
           FileManager.default.fileExists(atPath: mainURL.path) {
            return NSImage(contentsOf: mainURL)
        }

        guard let bundle = developmentResourceBundle(),
              let url = bundle.url(forResource: name, withExtension: ext) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

    private static func developmentResourceBundle() -> Bundle? {
        guard let executableURL = Bundle.main.executableURL else {
            return nil
        }

        let bundleURL = executableURL
            .deletingLastPathComponent()
            .appendingPathComponent("SoundRemover_SoundRemover.bundle")

        return Bundle(url: bundleURL)
    }
}
