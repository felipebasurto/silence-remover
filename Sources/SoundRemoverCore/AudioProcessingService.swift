import Foundation

public struct AudioProcessingService {
    private let audioFileService: AudioFileService
    private let silenceDetector: SilenceDetector
    private let audioTrimmer: AudioTrimmer

    public init(
        audioFileService: AudioFileService = AudioFileService(),
        silenceDetector: SilenceDetector = SilenceDetector(),
        audioTrimmer: AudioTrimmer = AudioTrimmer()
    ) {
        self.audioFileService = audioFileService
        self.silenceDetector = silenceDetector
        self.audioTrimmer = audioTrimmer
    }

    public func processWAV(
        originalURL: URL,
        inputWAVURL: URL,
        outputWAVURL: URL,
        settings: ProcessingSettings
    ) throws -> AudioProcessingResult {
        let audio = try audioFileService.loadPCM(from: inputWAVURL)
        let silences = silenceDetector.detectSilences(
            samples: audio.samples,
            sampleRate: audio.sampleRate,
            settings: settings
        )
        let processedSamples = audioTrimmer.trim(audio: audio, silences: silences, settings: settings)

        try audioFileService.writeWAV(samples: processedSamples, sampleRate: audio.sampleRate, to: outputWAVURL)

        let originalDuration = Double(audio.frameCount) / audio.sampleRate
        let finalFrameCount = processedSamples.first?.count ?? 0
        let finalDuration = Double(finalFrameCount) / audio.sampleRate

        return AudioProcessingResult(
            originalURL: originalURL,
            processedPreviewURL: outputWAVURL,
            detectedSilenceCount: silences.count,
            removedDuration: max(0, originalDuration - finalDuration),
            finalDuration: finalDuration,
            modeUsed: settings.mode
        )
    }
}
