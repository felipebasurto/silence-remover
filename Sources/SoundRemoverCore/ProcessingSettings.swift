import Foundation

public enum SilenceMode: String, CaseIterable, Identifiable, Sendable {
    case remove
    case compress

    public var id: String { rawValue }
}

public struct ProcessingSettings: Equatable, Sendable {
    public var silenceThresholdDb: Double
    public var minimumSilenceDurationMs: Double
    public var targetSilenceDurationMs: Double
    public var mode: SilenceMode
    public var fadeDurationMs: Double

    public init(
        silenceThresholdDb: Double = -40,
        minimumSilenceDurationMs: Double = 250,
        targetSilenceDurationMs: Double = 80,
        mode: SilenceMode = .compress,
        fadeDurationMs: Double = 5
    ) {
        self.silenceThresholdDb = silenceThresholdDb
        self.minimumSilenceDurationMs = minimumSilenceDurationMs
        self.targetSilenceDurationMs = targetSilenceDurationMs
        self.mode = mode
        self.fadeDurationMs = fadeDurationMs
    }
}

public struct AudioProcessingResult: Equatable, Sendable {
    public let originalURL: URL
    public let processedPreviewURL: URL
    public let detectedSilenceCount: Int
    public let removedDuration: TimeInterval
    public let finalDuration: TimeInterval
    public let modeUsed: SilenceMode

    public init(
        originalURL: URL,
        processedPreviewURL: URL,
        detectedSilenceCount: Int,
        removedDuration: TimeInterval,
        finalDuration: TimeInterval,
        modeUsed: SilenceMode
    ) {
        self.originalURL = originalURL
        self.processedPreviewURL = processedPreviewURL
        self.detectedSilenceCount = detectedSilenceCount
        self.removedDuration = removedDuration
        self.finalDuration = finalDuration
        self.modeUsed = modeUsed
    }
}

public struct SilenceRange: Equatable, Sendable {
    public let startFrame: Int
    public let endFrame: Int

    public init(startFrame: Int, endFrame: Int) {
        self.startFrame = startFrame
        self.endFrame = endFrame
    }

    public var frameCount: Int {
        max(0, endFrame - startFrame)
    }

    public func duration(sampleRate: Double) -> TimeInterval {
        TimeInterval(Double(frameCount) / sampleRate)
    }
}
