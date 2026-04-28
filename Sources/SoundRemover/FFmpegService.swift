import Foundation
import os
import SoundRemoverCore

struct FFmpegService {
    private static let log = Logger(subsystem: "SoundRemoverUI", category: "FFmpeg")

    private let executableURL: URL

    init() throws {
        let moduleURL = Bundle.module.url(forResource: "ffmpeg", withExtension: nil)
        let mainResourcesURL = Bundle.main.resourceURL?.appendingPathComponent("ffmpeg")

        Self.log.debug("ffmpeg resolve: moduleURL=\(moduleURL?.path ?? "nil", privacy: .public) exists=\(moduleURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false, privacy: .public)")
        Self.log.debug("ffmpeg resolve: mainResourcesURL=\(mainResourcesURL?.path ?? "nil", privacy: .public) exists=\(mainResourcesURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false, privacy: .public)")

        // Prefer the copy vendored with SoundRemoverUI; host app Resources is a fallback (e.g. custom packaging).
        guard
            let executableURL = [moduleURL, mainResourcesURL]
                .compactMap({ $0 })
                .first(where: { FileManager.default.fileExists(atPath: $0.path) })
        else {
            Self.log.error("ffmpeg resolve: no candidate path had a file on disk")
            throw SoundRemoverError.ffmpegUnavailable
        }

        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            Self.log.error("ffmpeg resolve: path is not executable: \(executableURL.path, privacy: .public)")
            throw SoundRemoverError.ffmpegUnavailable
        }

        Self.log.info("ffmpeg using binary at \(executableURL.path, privacy: .public)")

        self.executableURL = executableURL
    }

    func convertMP3ToWAV(mp3URL: URL, wavURL: URL) async throws {
        Self.log.debug("ffmpeg convertMP3ToWAV in=\(mp3URL.path, privacy: .public) out=\(wavURL.path, privacy: .public)")
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
        Self.log.debug("ffmpeg exportWAVToMP3 in=\(wavURL.path, privacy: .public) out=\(mp3URL.path, privacy: .public)")
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
        let exe = executableURL
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = exe
            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardError = errorPipe

            Self.log.debug("ffmpeg spawn: \(exe.path, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public)")

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                Self.log.error("ffmpeg run failed to start: \(error.localizedDescription, privacy: .public)")
                throw SoundRemoverError.ffmpegFailed(error.localizedDescription)
            }

            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard process.terminationStatus == 0 else {
                Self.log.error("ffmpeg exit=\(process.terminationStatus, privacy: .public) stderr=\(errText.isEmpty ? "(empty)" : errText, privacy: .public)")
                throw SoundRemoverError.ffmpegFailed(errText.isEmpty ? "exit \(process.terminationStatus)" : errText)
            }

            if !errText.isEmpty {
                Self.log.debug("ffmpeg stderr (non-fatal): \(errText, privacy: .public)")
            }
            Self.log.debug("ffmpeg finished OK")
        }.value
    }
}
