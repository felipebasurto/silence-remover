import Foundation
import os

struct FFmpegService {
    private static let log = Logger(subsystem: "AudioSilenceRemover", category: "FFmpeg")

    private let executableURL: URL

    init() throws {
        let mainResourcesURL = Bundle.main.resourceURL?.appendingPathComponent("ffmpeg")

        Self.log.debug("ffmpeg resolve: mainResourcesURL=\(mainResourcesURL?.path ?? "nil", privacy: .public) exists=\(mainResourcesURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false, privacy: .public)")

        guard
            let executableURL = mainResourcesURL,
            FileManager.default.fileExists(atPath: executableURL.path)
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
        let log = Self.log
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = exe
            process.arguments = arguments

            let errorPipe = Pipe()
            process.standardError = errorPipe

            log.debug("ffmpeg spawn: \(exe.path, privacy: .public) args=\(arguments.joined(separator: " "), privacy: .public)")

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                log.error("ffmpeg run failed to start: \(error.localizedDescription, privacy: .public)")
                throw SoundRemoverError.ffmpegFailed(error.localizedDescription)
            }

            let errData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errText = String(data: errData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard process.terminationStatus == 0 else {
                log.error("ffmpeg exit=\(process.terminationStatus, privacy: .public) stderr=\(errText.isEmpty ? "(empty)" : errText, privacy: .public)")
                throw SoundRemoverError.ffmpegFailed(errText.isEmpty ? "exit \(process.terminationStatus)" : errText)
            }

            if !errText.isEmpty {
                log.debug("ffmpeg stderr (non-fatal): \(errText, privacy: .public)")
            }
            log.debug("ffmpeg finished OK")
        }.value
    }
}
