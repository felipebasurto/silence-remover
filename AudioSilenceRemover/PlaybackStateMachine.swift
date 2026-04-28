import Foundation

enum PlaybackAction: Equatable {
    case stop
    case start(source: WaveformSource, duration: TimeInterval, currentTime: TimeInterval)
    case pause
    case update(currentTime: TimeInterval, duration: TimeInterval)
    case finished
}

struct PlaybackStateMachine {
    static func reduce(_ state: PlaybackState, action: PlaybackAction) -> PlaybackState {
        var next = state

        switch action {
        case .stop, .finished:
            next = .idle
        case .pause:
            next.isPlaying = false
        case .start(let source, let duration, let currentTime):
            next.source = source
            next.duration = duration
            next.currentTime = currentTime
            next.isPlaying = true
        case .update(let currentTime, let duration):
            next.currentTime = currentTime
            next.duration = duration
        }

        return next
    }
}
