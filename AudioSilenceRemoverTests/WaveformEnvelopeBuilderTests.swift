import Testing
@testable import AudioSilenceRemover

struct WaveformEnvelopeBuilderTests {
    @Test
    func decimatesIntoTargetSampleCount() {
        let samples = [Array(repeating: Float(0.5), count: 1_000)]
        let envelope = WaveformEnvelopeBuilder().build(samples: samples, sampleRate: 1_000, targetSampleCount: 100)

        #expect(envelope.amplitudes.count == 100)
        #expect(envelope.duration == 1.0)
    }

    @Test
    func keepsPeaksFromInput() {
        var channel = Array(repeating: Float(0.0), count: 200)
        channel[50] = 0.9
        channel[180] = 0.7

        let envelope = WaveformEnvelopeBuilder().build(samples: [channel], sampleRate: 100, targetSampleCount: 20)

        #expect(envelope.amplitudes.max() == 0.9)
    }
}
