import AVFoundation
import Foundation

public struct LoadedAudio {
    public let samples: [[Float]]
    public let sampleRate: Double
    public let channelCount: Int
    public let format: AVAudioFormat

    public var frameCount: Int {
        samples.first?.count ?? 0
    }
}

public struct AudioFileService {
    public init() {}

    public func loadPCM(from url: URL) throws -> LoadedAudio {
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw SoundRemoverError.audioUnreadable
        }

        try file.read(into: buffer)

        guard let floatChannelData = buffer.floatChannelData else {
            throw SoundRemoverError.audioFormatUnsupported
        }

        let channels = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        var samples = Array(repeating: Array(repeating: Float.zero, count: frames), count: channels)

        for channel in 0..<channels {
            let source = floatChannelData[channel]
            for frame in 0..<frames {
                samples[channel][frame] = source[frame]
            }
        }

        return LoadedAudio(
            samples: samples,
            sampleRate: format.sampleRate,
            channelCount: channels,
            format: format
        )
    }

    public func writeWAV(samples: [[Float]], sampleRate: Double, to url: URL) throws {
        guard let firstChannel = samples.first else {
            throw SoundRemoverError.audioUnreadable
        }

        let channelCount = AVAudioChannelCount(samples.count)
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        ) else {
            throw SoundRemoverError.audioFormatUnsupported
        }

        let frameCount = firstChannel.count
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(frameCount)
        ) else {
            throw SoundRemoverError.audioUnreadable
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        guard let floatChannelData = buffer.floatChannelData else {
            throw SoundRemoverError.audioFormatUnsupported
        }

        for channel in 0..<Int(channelCount) {
            let destination = floatChannelData[channel]
            let source = samples[channel]
            for frame in 0..<frameCount {
                destination[frame] = source[frame]
            }
        }

        let output = try AVAudioFile(forWriting: url, settings: format.settings)
        try output.write(from: buffer)
    }
}
