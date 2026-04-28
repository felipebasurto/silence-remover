import SwiftUI

struct ControlDeck: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            modeRow
            slidersGrid
            modeDetail
        }
        .padding(18)
        .background(BeveledPanelBackground(cornerRadius: 10))
        .overlay(alignment: .topLeading) { ScrewHead(size: 8).padding(9) }
        .overlay(alignment: .topTrailing) { ScrewHead(size: 8).padding(9) }
        .overlay(alignment: .bottomLeading) { ScrewHead(size: 8).padding(9) }
        .overlay(alignment: .bottomTrailing) { ScrewHead(size: 8).padding(9) }
        .opacity(appState.hasLoadedFile ? 1 : 0.78)
    }

    private var modeRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(AppLocale.text("mode.label"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(SkeuoColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .frame(width: 50, alignment: .leading)

            SkeuoSegmented(
                selection: $appState.settings.mode,
                options: SilenceMode.allCases.map { mode in
                    (mode, AppLocale.text("mode.\(mode.rawValue).title"))
                },
                isEnabled: appState.hasLoadedFile && !appState.isProcessing
            )
            .frame(maxWidth: 280)

            Spacer(minLength: 0)
        }
        .frame(height: 32)
    }

    private var slidersGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
            GridRow {
                BeveledSlider(
                    title: AppLocale.text("slider.threshold"),
                    value: $appState.settings.silenceThresholdDb,
                    range: -70...(-20),
                    step: 1,
                    formattedValue: "\(Int(appState.settings.silenceThresholdDb)) dB",
                    isEnabled: appState.hasLoadedFile && !appState.isProcessing
                )
                BeveledSlider(
                    title: AppLocale.text("slider.minimum_pause"),
                    value: $appState.settings.minimumSilenceDurationMs,
                    range: 80...900,
                    step: 10,
                    formattedValue: "\(Int(appState.settings.minimumSilenceDurationMs)) ms",
                    isEnabled: appState.hasLoadedFile && !appState.isProcessing
                )
            }
            GridRow {
                BeveledSlider(
                    title: AppLocale.text("slider.final_pause"),
                    value: $appState.settings.targetSilenceDurationMs,
                    range: 0...300,
                    step: 10,
                    formattedValue: "\(Int(appState.settings.targetSilenceDurationMs)) ms",
                    isEnabled: appState.hasLoadedFile
                        && !appState.isProcessing
                        && appState.settings.mode == .compress
                )

                fadePlaceholder
            }
        }
    }

    private var fadePlaceholder: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(AppLocale.text("slider.summary"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(SkeuoColor.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
            Text(appState.modeSummary)
                .font(.system(size: 11))
                .foregroundStyle(SkeuoColor.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var modeDetail: some View {
        Text(appState.modeDetail)
            .font(.system(size: 10.5))
            .foregroundStyle(SkeuoColor.textMuted)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
