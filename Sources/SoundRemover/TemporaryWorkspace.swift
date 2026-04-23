import Foundation
import SoundRemoverCore

final class TemporaryWorkspace {
    private(set) var directoryURL: URL

    init() throws {
        directoryURL = try Self.makeDirectory()
    }

    func reset() throws {
        cleanup()
        directoryURL = try Self.makeDirectory()
    }

    func url(_ name: String) -> URL {
        directoryURL.appendingPathComponent(name)
    }

    func cleanup() {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    deinit {
        cleanup()
    }

    private static func makeDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("SoundRemover-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
