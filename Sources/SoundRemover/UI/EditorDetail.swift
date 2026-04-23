import SwiftUI

struct EditorDetail: View {
    @ObservedObject var appState: AppState
    let isDropTargeted: Bool
    var onPickFile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                BrushedMetalBackground()

                VStack(spacing: 12) {
                    if appState.hasLoadedFile {
                        WaveformScreen(appState: appState)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        EmptyDropArea(isDropTargeted: isDropTargeted, onPickFile: onPickFile)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    ControlDeck(appState: appState)
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            ActionBar(appState: appState)
            StatusBar(appState: appState)
        }
    }
}

struct EmptyDropArea: View {
    let isDropTargeted: Bool
    var onPickFile: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [SkeuoColor.cyanCore, SkeuoColor.cyanGlow.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: SkeuoColor.cyanGlow.opacity(isDropTargeted ? 0.9 : 0.4), radius: 10)

            Text(AppLocale.text("dropzone.empty"))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(SkeuoColor.textPrimary)

            Text(AppLocale.text("dropzone.hint"))
                .font(.caption)
                .foregroundStyle(SkeuoColor.textMuted)

            Button(action: onPickFile) {
                Label(AppLocale.text("button.select_mp3"), systemImage: "folder")
            }
            .controlSize(.regular)
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .skeuoScreen()
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    isDropTargeted ? SkeuoColor.cyanGlow : Color.white.opacity(0.06),
                    style: StrokeStyle(lineWidth: 1.5, dash: isDropTargeted ? [] : [6])
                )
                .padding(10)
        }
    }
}
