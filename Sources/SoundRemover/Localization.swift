import Foundation

enum AppLocale {
    static func text(_ key: String, _ arguments: CVarArg...) -> String {
        let value = localizedFormat(key)
        guard !arguments.isEmpty else {
            return value
        }

        return String(format: value, locale: Locale.current, arguments: arguments)
    }

    static func localizedFormat(_ key: String) -> String {
        AppResources.localizedString(key)
    }
}
