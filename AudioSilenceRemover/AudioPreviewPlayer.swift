import AVFoundation
import Foundation

@MainActor
final class AudioPreviewPlayer: NSObject, @preconcurrency AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private(set) var currentSource: WaveformSource?

    var onProgress: ((TimeInterval, TimeInterval) -> Void)?
    var onStateChange: ((PlaybackAction) -> Void)?

    func play(url: URL, source: WaveformSource, from time: TimeInterval? = nil) throws {
        if currentSource != source || player == nil {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            currentSource = source
        }

        if let time {
            player?.currentTime = min(max(0, time), player?.duration ?? time)
        }

        player?.prepareToPlay()
        player?.play()
        startTimer()
        onStateChange?(.start(source: source, duration: player?.duration ?? 0, currentTime: player?.currentTime ?? 0))
    }

    func pause() {
        guard let player else {
            return
        }

        player.pause()
        stopTimer()
        onStateChange?(.pause)
        onProgress?(player.currentTime, player.duration)
    }

    func stop() {
        player?.stop()
        player = nil
        currentSource = nil
        stopTimer()
        onStateChange?(.stop)
    }

    func seek(to time: TimeInterval) {
        guard let player else {
            return
        }

        player.currentTime = min(max(0, time), player.duration)
        onStateChange?(.update(currentTime: player.currentTime, duration: player.duration))
        onProgress?(player.currentTime, player.duration)
    }

    var isPlaying: Bool {
        player?.isPlaying == true
    }

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopTimer()
        self.player = nil
        currentSource = nil
        onStateChange?(.finished)
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else {
                    return
                }

                self.onStateChange?(.update(currentTime: player.currentTime, duration: player.duration))
                self.onProgress?(player.currentTime, player.duration)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
