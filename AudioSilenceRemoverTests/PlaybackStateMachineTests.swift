import Testing
@testable import AudioSilenceRemover

struct PlaybackStateMachineTests {
    @Test
    func startSetsSourceAndPlaybackFlags() {
        let state = PlaybackStateMachine.reduce(
            .idle,
            action: .start(source: .original, duration: 12, currentTime: 3)
        )

        #expect(state.source == .original)
        #expect(state.duration == 12)
        #expect(state.currentTime == 3)
        #expect(state.isPlaying)
    }

    @Test
    func pausePreservesPositionButStopsPlayback() {
        let playing = PlaybackState(source: .processed, isPlaying: true, currentTime: 4, duration: 8)
        let paused = PlaybackStateMachine.reduce(playing, action: .pause)

        #expect(paused.source == .processed)
        #expect(paused.currentTime == 4)
        #expect(paused.duration == 8)
        #expect(!paused.isPlaying)
    }

    @Test
    func stopResetsToIdle() {
        let playing = PlaybackState(source: .processed, isPlaying: true, currentTime: 4, duration: 8)
        let stopped = PlaybackStateMachine.reduce(playing, action: .stop)

        #expect(stopped == .idle)
    }
}
