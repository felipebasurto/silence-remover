import Foundation

public enum SoundRemoverError: LocalizedError {
    case invalidMP3(URL)
    case ffmpegUnavailable
    case ffmpegFailed(String)
    case audioUnreadable
    case audioFormatUnsupported
    case temporaryFileFailed(String)
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .invalidMP3:
            "The selected file is not an MP3."
        case .ffmpegUnavailable:
            "FFmpeg is not available inside the app."
        case .ffmpegFailed(let message):
            "FFmpeg failed: \(message)"
        case .audioUnreadable:
            "The audio file could not be read."
        case .audioFormatUnsupported:
            "The PCM format is not supported."
        case .temporaryFileFailed(let reason):
            "A temporary file could not be created: \(reason)"
        case .exportFailed:
            "The MP3 could not be exported."
        }
    }
}
