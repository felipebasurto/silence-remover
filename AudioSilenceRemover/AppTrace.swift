import Foundation
import os

/// On-disk trace file for sandboxed builds where Console is easy to miss.
enum AppTrace {
    nonisolated private static let ioQueue = DispatchQueue(label: "com.felipebasurto.audiosilenceremover.trace")

    nonisolated static var subsystem: String {
        Bundle.main.bundleIdentifier ?? "AudioSilenceRemover"
    }

    nonisolated static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }

    /// Plain path for pasteboards and support mail.
    nonisolated static var traceLogPath: String {
        traceLogURL().path
    }

    private nonisolated static func traceLogURL() -> URL {
        guard
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        else {
            return URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("AudioSilenceRemover-trace.log", isDirectory: false)
        }
        return base.appendingPathComponent("AudioSilenceRemover/trace.log", isDirectory: false)
    }

    /// Appends one UTF-8 line to the trace file (async I/O).
    nonisolated static func record(_ category: String, _ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(stamp) [\(category)] \(message)\n"
        ioQueue.async {
            appendLineSync(line)
        }
    }

    nonisolated private static func appendLineSync(_ line: String) {
        let url = traceLogURL()
        let dir = url.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.seekToEnd()
            if let data = line.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
        } catch {
            // Avoid throwing from logging path.
        }
    }
}
