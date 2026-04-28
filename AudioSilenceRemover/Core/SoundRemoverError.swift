import Foundation

public enum SoundRemoverError: LocalizedError {
    case invalidMP3(URL)
    case ffmpegUnavailable
    case ffmpegFailed(String)
    case audioUnreadable
    case audioFormatUnsupported
    case temporaryFileFailed(String)
    case exportFailed

    /// Mirrors `AppState.localizedMessage` so `localizedDescription` matches the UI language.
    public var errorDescription: String? {
        switch self {
        case .invalidMP3:
            AppLocale.text("error.invalid_mp3")
        case .ffmpegUnavailable:
            AppLocale.text("error.ffmpeg_unavailable")
        case .ffmpegFailed(let message):
            AppLocale.text("error.ffmpeg_failed", message)
        case .audioUnreadable:
            AppLocale.text("error.audio_unreadable")
        case .audioFormatUnsupported:
            AppLocale.text("error.audio_unsupported")
        case .temporaryFileFailed(let reason):
            AppLocale.text("error.temporary_failed", reason)
        case .exportFailed:
            AppLocale.text("error.export_failed")
        }
    }
}
