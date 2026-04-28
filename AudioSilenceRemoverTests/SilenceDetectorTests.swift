import Testing
@testable import AudioSilenceRemover

struct SilenceDetectorTests {
    @Test
    func detectsSilenceLongerThanMinimumDuration() {
        let sampleRate = 1_000.0
        let loud = Array(repeating: Float(0.5), count: 300)
        let silence = Array(repeating: Float(0.0), count: 300)
        let samples = [loud + silence + loud]
        let settings = ProcessingSettings(
            silenceThresholdDb: -40,
            minimumSilenceDurationMs: 250,
            targetSilenceDurationMs: 80,
            mode: .compress
        )

        let ranges = SilenceDetector().detectSilences(
            samples: samples,
            sampleRate: sampleRate,
            settings: settings
        )

        #expect(ranges == [SilenceRange(startFrame: 300, endFrame: 600)])
    }

    @Test
    func ignoresSilenceShorterThanMinimumDuration() {
        let sampleRate = 1_000.0
        let loud = Array(repeating: Float(0.5), count: 300)
        let shortSilence = Array(repeating: Float(0.0), count: 120)
        let samples = [loud + shortSilence + loud]
        let settings = ProcessingSettings(
            silenceThresholdDb: -40,
            minimumSilenceDurationMs: 250,
            targetSilenceDurationMs: 80,
            mode: .compress
        )

        let ranges = SilenceDetector().detectSilences(
            samples: samples,
            sampleRate: sampleRate,
            settings: settings
        )

        #expect(ranges.isEmpty)
    }
}
