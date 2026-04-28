import AVFoundation
import Testing
@testable import AudioSilenceRemover

struct AudioTrimmerTests {
    @Test
    func removeModeDeletesDetectedSilence() {
        let audio = LoadedAudio.testAudio(frameCount: 1_000)
        let silence = SilenceRange(startFrame: 300, endFrame: 600)
        let settings = ProcessingSettings(mode: .remove, fadeDurationMs: 0)

        let output = AudioTrimmer().trim(audio: audio, silences: [silence], settings: settings)

        #expect(output[0].count == 700)
    }

    @Test
    func compressModeKeepsTargetSilenceDuration() {
        let audio = LoadedAudio.testAudio(frameCount: 1_000, sampleRate: 1_000)
        let silence = SilenceRange(startFrame: 300, endFrame: 600)
        let settings = ProcessingSettings(
            targetSilenceDurationMs: 80,
            mode: .compress,
            fadeDurationMs: 0
        )

        let output = AudioTrimmer().trim(audio: audio, silences: [silence], settings: settings)

        #expect(output[0].count == 780)
    }
}

private extension LoadedAudio {
    static func testAudio(frameCount: Int, sampleRate: Double = 1_000) -> LoadedAudio {
        LoadedAudio(
            samples: [Array(repeating: Float(0.5), count: frameCount)],
            sampleRate: sampleRate,
            channelCount: 1,
            format: .init(
                commonFormat: .pcmFormatFloat32,
                sampleRate: sampleRate,
                channels: 1,
                interleaved: false
            )!
        )
    }
}
