import Foundation
import SoundRemoverCore

@MainActor
final class AppState: ObservableObject {
    @Published var settings = ProcessingSettings()
    @Published private(set) var selectedOriginalURL: URL?
    @Published private(set) var result: AudioProcessingResult?
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?
    @Published var statusMessage = AppLocale.text("status.ready")
    @Published private(set) var originalWaveform: WaveformModel?
    @Published private(set) var processedWaveform: WaveformModel?
    @Published var selectedWaveformSource: WaveformSource = .original
    @Published private(set) var playbackState: PlaybackState = .idle
    @Published private(set) var recents: [RecentFile] = []

    private static let recentsDefaultsKey = "SoundRemover.recents.v2"
    private static let maxRecents = 12

    private let mp3ImportService = MP3ImportService()
    private let audioProcessingService = AudioProcessingService()
    private let audioFileService = AudioFileService()
    private let waveformBuilder = WaveformEnvelopeBuilder()
    private let exportService = ExportService()
    private let previewPlayer = AudioPreviewPlayer()
    private let workspace: TemporaryWorkspace

    private var workingMP3URL: URL?
    private var ffmpegService: FFmpegService?

    init() {
        do {
            workspace = try TemporaryWorkspace()
            ffmpegService = try? FFmpegService()
            if ffmpegService == nil {
                errorMessage = localizedMessage(for: SoundRemoverError.ffmpegUnavailable)
            }
            configurePlayerCallbacks()
            loadRecents()
        } catch {
            fatalError("No se pudo crear el workspace temporal: \(error)")
        }
    }

    var hasLoadedFile: Bool {
        selectedOriginalURL != nil
    }

    var hasProcessedResult: Bool {
        result != nil
    }

    var activeWaveformSource: WaveformSource {
        selectedWaveformSource
    }

    var canProcess: Bool {
        hasLoadedFile && !isProcessing
    }

    var canExport: Bool {
        hasProcessedResult && !isProcessing
    }

    var displayFilename: String {
        selectedOriginalURL?.lastPathComponent ?? AppLocale.text("dropzone.empty")
    }

    var displayDuration: String? {
        originalWaveform.map { formatTimestamp($0.duration) }
    }

    var modeSummary: String {
        AppLocale.text("mode.\(settings.mode.rawValue).summary")
    }

    var modeDetail: String {
        AppLocale.text("mode.\(settings.mode.rawValue).detail")
    }

    var resultSummary: String? {
        guard let result else { return nil }
        return AppLocale.text(
            "result.summary",
            result.detectedSilenceCount,
            formatSeconds(result.removedDuration),
            AppLocale.text("mode.\(result.modeUsed.rawValue).title"),
            formatSeconds(result.finalDuration)
        )
    }

    func selectFile(_ url: URL) async {
        do {
            stopPlayback()
            result = nil
            processedWaveform = nil
            selectedWaveformSource = .original
            errorMessage = nil
            try workspace.reset()

            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let preparedURL = try mp3ImportService.prepareInput(from: url, in: workspace.directoryURL)
            selectedOriginalURL = url
            workingMP3URL = preparedURL
            originalWaveform = try loadWaveform(from: preparedURL)
            statusMessage = AppLocale.text("status.loaded", url.lastPathComponent)
            if let bookmark = try? url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            ) {
                appendRecent(
                    bookmarkData: bookmark,
                    canonicalPath: url.standardizedFileURL.path,
                    displayName: url.lastPathComponent,
                    duration: originalWaveform?.duration
                )
            }
        } catch {
            setError(error)
        }
    }

    func openRecent(_ recent: RecentFile) async {
        do {
            let url = try recent.resolveURL()
            await selectFile(url)
        } catch {
            removeRecent(id: recent.id)
            setError(error)
        }
    }

    var selectedFileCanonicalPath: String? {
        selectedOriginalURL?.standardizedFileURL.path
    }

    func removeRecent(id: UUID) {
        let updated = recents.filter { $0.id != id }
        recents = updated
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: Self.recentsDefaultsKey)
        }
    }

    func clearRecents() {
        recents = []
        UserDefaults.standard.removeObject(forKey: Self.recentsDefaultsKey)
    }

    func process() async {
        guard let ffmpegService else {
            setError(SoundRemoverError.ffmpegUnavailable)
            return
        }

        guard let selectedOriginalURL, let workingMP3URL else {
            return
        }

        isProcessing = true
        errorMessage = nil
        result = nil
        processedWaveform = nil
        stopPlayback()
        statusMessage = AppLocale.text("status.processing")

        do {
            let inputWAVURL = workspace.url("input.wav")
            let outputWAVURL = workspace.url("processed.wav")

            try await ffmpegService.convertMP3ToWAV(mp3URL: workingMP3URL, wavURL: inputWAVURL)

            let processedResult = try audioProcessingService.processWAV(
                originalURL: selectedOriginalURL,
                inputWAVURL: inputWAVURL,
                outputWAVURL: outputWAVURL,
                settings: settings
            )

            result = processedResult
            processedWaveform = try loadWaveform(from: outputWAVURL)
            selectedWaveformSource = .processed
            statusMessage = AppLocale.text(
                "status.processed",
                processedResult.detectedSilenceCount,
                formatSeconds(processedResult.removedDuration),
                AppLocale.text("mode.\(processedResult.modeUsed.rawValue).title")
            )
        } catch {
            setError(error)
        }

        isProcessing = false
    }

    func togglePlayback(for source: WaveformSource) {
        guard let url = url(for: source) else {
            return
        }

        do {
            if playbackState.source == source {
                if playbackState.isPlaying {
                    previewPlayer.pause()
                } else {
                    try previewPlayer.play(url: url, source: source, from: playbackState.currentTime)
                }
            } else {
                stopPlayback()
                try previewPlayer.play(url: url, source: source, from: 0)
                selectedWaveformSource = source
            }
        } catch {
            setError(error)
        }
    }

    func stopPlayback() {
        previewPlayer.stop()
    }

    func seekPlayback(to ratio: Double, source: WaveformSource) {
        guard playbackState.source == source || playbackState.source == nil else {
            return
        }

        let duration = duration(for: source)
        guard duration > 0 else { return }
        let clamped = min(max(ratio, 0), 1)
        let time = duration * clamped

        if playbackState.source == nil {
            playbackState.source = source
            playbackState.currentTime = time
            playbackState.duration = duration
            selectedWaveformSource = source
        } else {
            previewPlayer.seek(to: time)
        }
    }

    func exportMP3() async {
        guard let ffmpegService else {
            setError(SoundRemoverError.ffmpegUnavailable)
            return
        }

        guard let selectedOriginalURL, let result else {
            return
        }

        let defaultName = selectedOriginalURL
            .deletingPathExtension()
            .lastPathComponent + "_no_silence.mp3"

        guard let destinationURL = exportService.destinationURL(defaultName: defaultName) else {
            return
        }

        isProcessing = true
        errorMessage = nil
        statusMessage = AppLocale.text("status.exporting")

        do {
            try await ffmpegService.exportWAVToMP3(wavURL: result.processedPreviewURL, mp3URL: destinationURL)
            statusMessage = AppLocale.text("status.exported", destinationURL.lastPathComponent)
        } catch {
            setError(error)
        }

        isProcessing = false
    }

    private func setError(_ error: Error) {
        errorMessage = localizedMessage(for: error)
        statusMessage = AppLocale.text("status.generic_error")
        isProcessing = false
    }

    private func configurePlayerCallbacks() {
        previewPlayer.onStateChange = { [weak self] action in
            guard let self else { return }
            playbackState = PlaybackStateMachine.reduce(playbackState, action: action)
        }
    }

    private func loadWaveform(from url: URL) throws -> WaveformModel {
        let audio = try audioFileService.loadPCM(from: url)
        return WaveformModel(envelope: waveformBuilder.build(samples: audio.samples, sampleRate: audio.sampleRate))
    }

    private func duration(for source: WaveformSource) -> TimeInterval {
        switch source {
        case .original:
            originalWaveform?.duration ?? 0
        case .processed:
            processedWaveform?.duration ?? 0
        }
    }

    private func url(for source: WaveformSource) -> URL? {
        switch source {
        case .original:
            workingMP3URL
        case .processed:
            result?.processedPreviewURL
        }
    }

    private func localizedMessage(for error: Error) -> String {
        switch error {
        case SoundRemoverError.invalidMP3:
            AppLocale.text("error.invalid_mp3")
        case SoundRemoverError.ffmpegUnavailable:
            AppLocale.text("error.ffmpeg_unavailable")
        case SoundRemoverError.ffmpegFailed(let message):
            AppLocale.text("error.ffmpeg_failed", message)
        case SoundRemoverError.audioUnreadable:
            AppLocale.text("error.audio_unreadable")
        case SoundRemoverError.audioFormatUnsupported:
            AppLocale.text("error.audio_unsupported")
        case SoundRemoverError.temporaryFileFailed(let reason):
            AppLocale.text("error.temporary_failed", reason)
        case SoundRemoverError.exportFailed:
            AppLocale.text("error.export_failed")
        default:
            error.localizedDescription
        }
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        String(format: "%.2fs", seconds)
    }

    private func formatTimestamp(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds.rounded(.down))
        let minutes = totalSeconds / 60
        let remainder = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainder)
    }

    private func loadRecents() {
        guard let data = UserDefaults.standard.data(forKey: Self.recentsDefaultsKey) else {
            return
        }
        guard let decoded = try? JSONDecoder().decode([RecentFile].self, from: data) else {
            UserDefaults.standard.removeObject(forKey: Self.recentsDefaultsKey)
            return
        }
        recents = decoded.filter { recent in
            guard let url = try? recent.resolveURL() else { return false }
            let scoped = url.startAccessingSecurityScopedResource()
            defer {
                if scoped {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            return FileManager.default.fileExists(atPath: url.path)
        }
    }

    private func appendRecent(
        bookmarkData: Data,
        canonicalPath: String,
        displayName: String,
        duration: TimeInterval?
    ) {
        var updated = recents.filter { $0.canonicalPath != canonicalPath }
        let entry = RecentFile(
            id: UUID(),
            bookmarkData: bookmarkData,
            canonicalPath: canonicalPath,
            displayName: displayName,
            duration: duration,
            addedAt: Date()
        )
        updated.insert(entry, at: 0)
        if updated.count > Self.maxRecents {
            updated = Array(updated.prefix(Self.maxRecents))
        }
        recents = updated
        if let data = try? JSONEncoder().encode(updated) {
            UserDefaults.standard.set(data, forKey: Self.recentsDefaultsKey)
        }
    }
}

struct RecentFile: Identifiable, Hashable, Codable {
    let id: UUID
    /// Security-scoped bookmark so reopening from recents works under App Sandbox.
    let bookmarkData: Data
    let canonicalPath: String
    let displayName: String
    let duration: TimeInterval?
    let addedAt: Date

    var formattedDuration: String? {
        guard let duration, duration > 0 else { return nil }
        let total = Int(duration.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    func resolveURL() throws -> URL {
        var stale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope, .withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        )
        if stale {
            // Caller may refresh bookmark later; still try the resolved URL.
        }
        return url
    }
}
