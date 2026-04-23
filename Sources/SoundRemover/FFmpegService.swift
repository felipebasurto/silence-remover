import Foundation
import SoundRemoverCore

struct FFmpegService {
    private let executableURL: URL

    init() throws {
        let bundledAppURL = Bundle.main.resourceURL?.appendingPathComponent("ffmpeg")
        let swiftPackageURL = Bundle.module.url(forResource: "ffmpeg", withExtension: nil)

        guard
            let executableURL = [bundledAppURL, swiftPackageURL]
                .compactMap({ $0 })
                .first(where: { FileManager.default.fileExists(atPath: $0.path) })
        else {
            throw SoundRemoverError.ffmpegUnavailable
        }

        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw SoundRemoverError.ffmpegUnavailable
        }

        self.executableURL = executableURL
    }

    func convertMP3ToWAV(mp3URL: URL, wavURL: URL) async throws {
        try await run(arguments: [
            "-y",
            "-hide_banner",
            "-loglevel", "error",
            "-i", mp3URL.path,
            "-acodec", "pcm_f32le",
            wavURL.path
        ])
    }

    func exportWAVToMP3(wavURL: URL, mp3URL: URL) async throws {
        try await run(arguments: [
            "-y",
            "-hide_banner",
            "-loglevel", "error",
            "-i", wavURL.path,
            "-codec:a", "libmp3lame",
            "-b:a", "192k",
            mp3URL.path
        ])
    }

    private func run(arguments: [String]) async throws {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = executableURL
            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                throw SoundRemoverError.ffmpegFailed(error.localizedDescription)
            }

            guard process.terminationStatus == 0 else {
                let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let message = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                throw SoundRemoverError.ffmpegFailed(message ?? "Código \(process.terminationStatus)")
            }
        }.value
    }
}
