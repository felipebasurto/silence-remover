import Foundation

public struct WaveformEnvelope: Equatable, Sendable {
    public let amplitudes: [Float]
    public let duration: TimeInterval

    public init(amplitudes: [Float], duration: TimeInterval) {
        self.amplitudes = amplitudes
        self.duration = duration
    }
}

public struct WaveformEnvelopeBuilder {
    public init() {}

    public func build(samples: [[Float]], sampleRate: Double, targetSampleCount: Int = 240) -> WaveformEnvelope {
        guard
            sampleRate > 0,
            let firstChannel = samples.first,
            !firstChannel.isEmpty,
            targetSampleCount > 0
        else {
            return WaveformEnvelope(amplitudes: [], duration: 0)
        }

        let frameCount = firstChannel.count
        let bucketSize = max(1, frameCount / targetSampleCount)
        var amplitudes: [Float] = []
        amplitudes.reserveCapacity(targetSampleCount)

        var cursor = 0
        while cursor < frameCount {
            let end = min(cursor + bucketSize, frameCount)
            var peak: Float = 0

            for channel in samples {
                for index in cursor..<min(end, channel.count) {
                    peak = max(peak, abs(channel[index]))
                }
            }

            amplitudes.append(min(max(peak, 0), 1))
            cursor = end
        }

        return WaveformEnvelope(
            amplitudes: amplitudes,
            duration: TimeInterval(Double(frameCount) / sampleRate)
        )
    }
}
