import Foundation

public struct SilenceDetector {
    private let windowDuration: TimeInterval

    public init(windowDuration: TimeInterval = 0.01) {
        self.windowDuration = windowDuration
    }

    public func detectSilences(
        samples: [[Float]],
        sampleRate: Double,
        settings: ProcessingSettings
    ) -> [SilenceRange] {
        guard let firstChannel = samples.first, !firstChannel.isEmpty, sampleRate > 0 else {
            return []
        }

        let frameCount = firstChannel.count
        let windowSize = max(1, Int(sampleRate * windowDuration))
        let minimumSilentFrames = max(1, Int(sampleRate * settings.minimumSilenceDurationMs / 1_000))

        var ranges: [SilenceRange] = []
        var currentSilenceStart: Int?
        var frame = 0

        while frame < frameCount {
            let end = min(frame + windowSize, frameCount)
            let db = rmsDb(samples: samples, range: frame..<end)
            let isSilent = db < settings.silenceThresholdDb

            if isSilent {
                if currentSilenceStart == nil {
                    currentSilenceStart = frame
                }
            } else if let start = currentSilenceStart {
                appendRangeIfLongEnough(start: start, end: frame, minimumFrames: minimumSilentFrames, to: &ranges)
                currentSilenceStart = nil
            }

            frame = end
        }

        if let start = currentSilenceStart {
            appendRangeIfLongEnough(start: start, end: frameCount, minimumFrames: minimumSilentFrames, to: &ranges)
        }

        return ranges
    }

    private func appendRangeIfLongEnough(
        start: Int,
        end: Int,
        minimumFrames: Int,
        to ranges: inout [SilenceRange]
    ) {
        guard end - start >= minimumFrames else {
            return
        }
        ranges.append(SilenceRange(startFrame: start, endFrame: end))
    }

    private func rmsDb(samples: [[Float]], range: Range<Int>) -> Double {
        var sumSquares: Double = 0
        var count = 0

        for channel in samples {
            let channelEnd = min(range.upperBound, channel.count)
            guard range.lowerBound < channelEnd else {
                continue
            }

            for index in range.lowerBound..<channelEnd {
                let sample = Double(channel[index])
                sumSquares += sample * sample
                count += 1
            }
        }

        guard count > 0 else {
            return -120
        }

        let rms = sqrt(sumSquares / Double(count))
        return 20 * log10(max(rms, 0.000_001))
    }
}
