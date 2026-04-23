import SwiftUI

struct EditorToolbar: ToolbarContent {
    @ObservedObject var appState: AppState

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                appState.togglePlayback(for: appState.activeWaveformSource)
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            }
            .help(isPlaying ? AppLocale.text("button.waveform_pause") : AppLocale.text("button.waveform_play"))
            .disabled(!canPlay || appState.isProcessing)

            Button {
                appState.stopPlayback()
            } label: {
                Image(systemName: "stop.fill")
            }
            .help(AppLocale.text("button.stop"))
            .disabled(appState.playbackState.source == nil || appState.isProcessing)
        }

        ToolbarItem(placement: .primaryAction) {
            Picker("", selection: $appState.selectedWaveformSource) {
                Text(AppLocale.text("waveform.source.original")).tag(WaveformSource.original)
                Text(AppLocale.text("waveform.source.processed")).tag(WaveformSource.processed)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)
            .disabled(!appState.hasLoadedFile)
        }
    }

    private var isPlaying: Bool {
        appState.playbackState.source == appState.selectedWaveformSource && appState.playbackState.isPlaying
    }

    private var canPlay: Bool {
        switch appState.selectedWaveformSource {
        case .original: appState.hasLoadedFile
        case .processed: appState.hasProcessedResult
        }
    }
}
