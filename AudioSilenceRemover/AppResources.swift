import AppKit
import Foundation

enum AppResources {
    nonisolated static func localizedString(_ key: String) -> String {
        let fromMain = Bundle.main.localizedString(forKey: key, value: key, table: nil)
        if fromMain != key {
            return fromMain
        }

        return key
    }

    static func image(named name: String, extension ext: String) -> NSImage? {
        if let mainURL = Bundle.main.resourceURL?.appendingPathComponent("\(name).\(ext)"),
           FileManager.default.fileExists(atPath: mainURL.path) {
            return NSImage(contentsOf: mainURL)
        }

        return nil
    }
}
