import Foundation

public struct MP3ImportService {
    public init() {}

    public func prepareInput(from sourceURL: URL, in workingDirectory: URL) throws -> URL {
        guard sourceURL.pathExtension.lowercased() == "mp3" else {
            throw SoundRemoverError.invalidMP3(sourceURL)
        }

        let destinationURL = workingDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp3")

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw SoundRemoverError.temporaryFileFailed(error.localizedDescription)
        }
    }
}
