import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
struct ExportService {
    func destinationURL(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.mp3]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultName
        panel.title = AppLocale.text("export.panel.title")
        panel.prompt = AppLocale.text("export.panel.prompt")

        return panel.runModal() == .OK ? panel.url : nil
    }
}
