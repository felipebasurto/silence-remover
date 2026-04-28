import Foundation

enum WaveformSource: String, CaseIterable, Identifiable {
    case original
    case processed

    var id: String { rawValue }
}

struct WaveformModel: Equatable {
    let amplitudes: [Float]
    let duration: TimeInterval

    init(envelope: WaveformEnvelope) {
        amplitudes = envelope.amplitudes
        duration = envelope.duration
    }
}

struct PlaybackState: Equatable {
    var source: WaveformSource?
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    static let idle = PlaybackState()
}
