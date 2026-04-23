import Foundation

public struct AudioTrimmer {
    public init() {}

    public func trim(
        audio: LoadedAudio,
        silences: [SilenceRange],
        settings: ProcessingSettings
    ) -> [[Float]] {
        guard audio.frameCount > 0, audio.channelCount > 0 else {
            return audio.samples
        }

        var output = Array(repeating: [Float](), count: audio.channelCount)
        var cursor = 0
        var joinFrames: [Int] = []
        let targetSilenceFrames = max(0, Int(audio.sampleRate * settings.targetSilenceDurationMs / 1_000))

        for silence in silences {
            let start = clamp(silence.startFrame, lower: 0, upper: audio.frameCount)
            let end = clamp(silence.endFrame, lower: start, upper: audio.frameCount)

            appendRange(cursor..<start, from: audio.samples, to: &output)

            if end > start {
                joinFrames.append(output[0].count)
            }

            if settings.mode == .compress, targetSilenceFrames > 0 {
                let compressedEnd = min(start + targetSilenceFrames, end)
                appendRange(start..<compressedEnd, from: audio.samples, to: &output)
            }

            cursor = end
        }

        appendRange(cursor..<audio.frameCount, from: audio.samples, to: &output)
        applyFades(to: &output, joinFrames: joinFrames, sampleRate: audio.sampleRate, fadeDurationMs: settings.fadeDurationMs)

        return output
    }

    private func appendRange(_ range: Range<Int>, from input: [[Float]], to output: inout [[Float]]) {
        guard !range.isEmpty else {
            return
        }

        for channel in input.indices {
            output[channel].append(contentsOf: input[channel][range])
        }
    }

    private func applyFades(
        to samples: inout [[Float]],
        joinFrames: [Int],
        sampleRate: Double,
        fadeDurationMs: Double
    ) {
        guard let frameCount = samples.first?.count, frameCount > 0 else {
            return
        }

        let fadeFrames = max(1, Int(sampleRate * fadeDurationMs / 1_000))

        for joinFrame in joinFrames {
            let fadeOutStart = max(0, joinFrame - fadeFrames)
            let fadeInEnd = min(frameCount, joinFrame + fadeFrames)

            for channel in samples.indices {
                if fadeOutStart < joinFrame {
                    for frame in fadeOutStart..<joinFrame {
                        let progress = Float(joinFrame - frame) / Float(max(1, joinFrame - fadeOutStart))
                        samples[channel][frame] *= progress
                    }
                }

                if joinFrame < fadeInEnd {
                    for frame in joinFrame..<fadeInEnd {
                        let progress = Float(frame - joinFrame) / Float(max(1, fadeInEnd - joinFrame))
                        samples[channel][frame] *= progress
                    }
                }
            }
        }
    }

    private func clamp(_ value: Int, lower: Int, upper: Int) -> Int {
        min(max(value, lower), upper)
    }
}
