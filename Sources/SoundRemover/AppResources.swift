import AppKit
import Foundation

enum AppResources {
    /// Localized UI strings live in the `SoundRemoverUI` SPM resource bundle (`Localizable.strings`).
    /// `Bundle.main` alone is wrong when this module is linked into another app (e.g. Mac App Store host).
    static func localizedString(_ key: String) -> String {
        let fromModule = Bundle.module.localizedString(forKey: key, value: key, table: nil)
        if fromModule != key {
            return fromModule
        }

        let fromMain = Bundle.main.localizedString(forKey: key, value: key, table: nil)
        if fromMain != key {
            return fromMain
        }

        if let sibling = developmentResourceBundle() {
            let fromSibling = sibling.localizedString(forKey: key, value: key, table: nil)
            if fromSibling != key {
                return fromSibling
            }
        }

        return key
    }

    static func image(named name: String, extension ext: String) -> NSImage? {
        if let url = Bundle.module.url(forResource: name, withExtension: ext),
           FileManager.default.fileExists(atPath: url.path) {
            return NSImage(contentsOf: url)
        }

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

    /// `swift run` layout: resource bundle next to the executable. Xcode embeds the same bundle name under `Resources` or `Frameworks`.
    private static func developmentResourceBundle() -> Bundle? {
        let name = "SoundRemover_SoundRemoverUI"

        if let url = Bundle.main.url(forResource: name, withExtension: "bundle") {
            return Bundle(url: url)
        }

        if let executableURL = Bundle.main.executableURL {
            let sibling = executableURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(name).bundle", isDirectory: true)
            if let b = Bundle(url: sibling) {
                return b
            }
        }

        return nil
    }
}
