import Foundation
import os

struct FFmpegService {
    /// Must match `AppTrace.subsystem` (bundle id) so Console.app filtering matches `AppTrace` lines.
    private static let log: Logger = {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "AudioSilenceRemover", category: "FFmpeg")
    }()

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
            "-nostdin",
            "-hide_banner",
            "-loglevel", "warning",
            "-i", mp3URL.path,
            "-acodec", "pcm_f32le",
            wavURL.path
        ])
    }

    func exportWAVToMP3(wavURL: URL, mp3URL: URL) async throws {
        Self.log.debug("ffmpeg exportWAVToMP3 in=\(wavURL.path, privacy: .public) out=\(mp3URL.path, privacy: .public)")
        try await run(arguments: [
            "-y",
            "-nostdin",
            "-hide_banner",
            "-loglevel", "warning",
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
            process.currentDirectoryURL = exe.deletingLastPathComponent()
            process.environment = Self.sanitizedEnvironment()

            let errorPipe = Pipe()
            let outputPipe = Pipe()
            process.standardError = errorPipe
            process.standardOutput = outputPipe

            let argLine = arguments.joined(separator: " ")
            log.debug("ffmpeg spawn: \(exe.path, privacy: .public) args=\(argLine, privacy: .public)")
            AppTrace.record("FFmpeg", "spawn \(exe.path) \(argLine)")

            do {
                try process.run()
            } catch {
                log.error("ffmpeg run failed to start: \(error.localizedDescription, privacy: .public)")
                AppTrace.record("FFmpeg", "failed to start: \(error.localizedDescription)")
                throw SoundRemoverError.ffmpegFailed(error.localizedDescription)
            }

            let stderrTask = Task { errorPipe.fileHandleForReading.readDataToEndOfFile() }
            let stdoutTask = Task { outputPipe.fileHandleForReading.readDataToEndOfFile() }
            process.waitUntilExit()

            let errData = await stderrTask.value
            let outData = await stdoutTask.value
            let errText = Self.stringFromPipeData(errData)
            let outText = Self.stringFromPipeData(outData)
            let terminationReason = process.terminationReason

            guard process.terminationStatus == 0 else {
                let code = process.terminationStatus
                let reasonLabel = Self.terminationReasonLabel(terminationReason)
                log.error(
                    "ffmpeg exit=\(code, privacy: .public) reason=\(reasonLabel, privacy: .public) stderrBytes=\(errData.count, privacy: .public) stdoutBytes=\(outData.count, privacy: .public) stderr=\(errText.isEmpty ? "(empty)" : errText, privacy: .public)"
                )
                AppTrace.record(
                    "FFmpeg",
                    "exit=\(code) terminationReason=\(reasonLabel) stderrBytes=\(errData.count) stdoutBytes=\(outData.count) stderr=\(errText.isEmpty ? "(empty)" : errText)"
                )
                if !outText.isEmpty {
                    AppTrace.record("FFmpeg", "exit=\(code) stdout=\(outText)")
                }
                let uiMessage = Self.failureSummary(
                    exitCode: code,
                    stderr: errText,
                    stdout: outText,
                    terminationReason: terminationReason
                )
                throw SoundRemoverError.ffmpegFailed(uiMessage)
            }

            if !errText.isEmpty {
                log.debug("ffmpeg stderr (non-fatal): \(errText, privacy: .public)")
            }
            log.debug("ffmpeg finished OK")
        }.value
    }

    nonisolated private static func stringFromPipeData(_ data: Data) -> String {
        guard !data.isEmpty else { return "" }
        let trim: (String) -> String = { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if let utf8 = String(data: data, encoding: .utf8), !trim(utf8).isEmpty {
            return trim(utf8)
        }
        // Lossy decode so mis-encoded ffmpeg output is not dropped entirely.
        return trim(String(decoding: data, as: UTF8.self))
    }

    nonisolated private static func terminationReasonLabel(_ reason: Process.TerminationReason) -> String {
        switch reason {
        case .exit:
            "exit"
        case .uncaughtSignal:
            "uncaughtSignal"
        @unknown default:
            "unknown(\(reason.rawValue))"
        }
    }

    nonisolated private static func sanitizedEnvironment() -> [String: String] {
        ProcessInfo.processInfo.environment.filter { entry in
            !entry.key.hasPrefix("DYLD_") && !entry.key.hasPrefix("__XPC_DYLD_")
        }
    }

    /// Short, single-line friendly message for the status bar; full text goes to `AppTrace` / Logger.
    nonisolated private static func failureSummary(
        exitCode: Int32,
        stderr: String,
        stdout: String,
        terminationReason: Process.TerminationReason
    ) -> String {
        let maxLen = 480
        if !stderr.isEmpty {
            return truncate(stderr.replacingOccurrences(of: "\n", with: " "), max: maxLen)
        }
        if !stdout.isEmpty {
            let snippet = truncate(stdout.replacingOccurrences(of: "\n", with: " "), max: maxLen)
            return AppLocale.text("error.ffmpeg_exit_with_output", "\(exitCode)", snippet)
        }
        if terminationReason == .uncaughtSignal {
            return AppLocale.text("error.ffmpeg_uncaught_signal", "\(exitCode)")
        }
        return AppLocale.text("error.ffmpeg_no_output", "\(exitCode)")
    }

    nonisolated private static func truncate(_ s: String, max: Int) -> String {
        guard s.count > max else { return s }
        return String(s.prefix(max)) + "…"
    }
}
