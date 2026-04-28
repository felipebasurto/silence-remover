import SwiftUI

struct WaveformScreen: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    SkeuoLED(
                        color: appState.selectedWaveformSource == .processed
                            ? Color(red: 0.55, green: 1.0, blue: 0.55)
                            : SkeuoColor.cyanCore,
                        glow: appState.selectedWaveformSource == .processed
                            ? Color(red: 0.55, green: 1.0, blue: 0.55)
                            : SkeuoColor.cyanGlow,
                        size: 9,
                        isOn: currentWaveform != nil
                    )
                    Text(currentLabel)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SkeuoColor.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.6)
                }

                Spacer()

                if appState.hasLoadedFile {
                    Text(appState.displayFilename)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SkeuoColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .padding(.horizontal, 4)

            ZStack {
                if let waveform = currentWaveform {
                    WaveformView(
                        model: waveform,
                        playbackState: appState.playbackState,
                        source: appState.selectedWaveformSource
                    ) { ratio in
                        appState.seekPlayback(to: ratio, source: appState.selectedWaveformSource)
                    }
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .skeuoScreen()

            HStack(spacing: 0) {
                Text(formatSeconds(currentPlaybackTime))
                    .monospacedDigit()
                Spacer()
                Text(AppLocale.text("waveform.elapsed_total"))
                    .foregroundStyle(SkeuoColor.textMuted)
                Spacer()
                Text(formatSeconds(currentWaveform?.duration ?? 0))
                    .monospacedDigit()
            }
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(SkeuoColor.textSecondary)
            .padding(.horizontal, 4)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 26))
                .foregroundStyle(SkeuoColor.cyanGlow.opacity(0.45))
            Text(AppLocale.text("waveform.empty"))
                .font(.system(size: 12))
                .foregroundStyle(SkeuoColor.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var currentLabel: String {
        switch appState.selectedWaveformSource {
        case .original:
            AppLocale.text("waveform.source.original")
        case .processed:
            AppLocale.text("waveform.source.processed")
        }
    }

    private var currentWaveform: WaveformModel? {
        switch appState.selectedWaveformSource {
        case .original: appState.originalWaveform
        case .processed: appState.processedWaveform
        }
    }

    private var currentPlaybackTime: TimeInterval {
        guard appState.playbackState.source == appState.selectedWaveformSource else {
            return appState.playbackState.source == nil ? appState.playbackState.currentTime : 0
        }
        return appState.playbackState.currentTime
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        let minutes = total / 60
        let remainder = total % 60
        let centis = Int((seconds - floor(seconds)) * 100)
        return String(format: "%d:%02d.%02d", minutes, remainder, centis)
    }
}
