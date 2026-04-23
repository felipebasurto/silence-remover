import SwiftUI

struct ActionBar: View {
    @ObservedObject var appState: AppState
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            if appState.hasProcessedResult {
                processAgainButton
                exportButton
            } else {
                processButton
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(actionBarBackground)
        .onAppear { pulse = true }
    }

    private var processButton: some View {
        PrimaryActionButton(
            title: appState.isProcessing
                ? AppLocale.text("action.processing")
                : AppLocale.text("action.process"),
            systemImage: "scissors",
            isEnabled: appState.canProcess,
            isLoading: appState.isProcessing,
            isHighlighted: appState.canProcess && !appState.isProcessing,
            pulse: pulse
        ) {
            Task { await appState.process() }
        }
        .keyboardShortcut(.return, modifiers: .command)
    }

    private var processAgainButton: some View {
        SecondaryActionButton(
            title: AppLocale.text("action.process_again"),
            systemImage: "arrow.triangle.2.circlepath",
            isEnabled: appState.canProcess && !appState.isProcessing
        ) {
            Task { await appState.process() }
        }
        .keyboardShortcut(.return, modifiers: .command)
    }

    private var exportButton: some View {
        PrimaryActionButton(
            title: appState.isProcessing
                ? AppLocale.text("action.exporting")
                : AppLocale.text("action.export"),
            systemImage: "square.and.arrow.down.fill",
            isEnabled: appState.canExport,
            isLoading: appState.isProcessing,
            isHighlighted: appState.canExport && !appState.isProcessing,
            pulse: pulse
        ) {
            Task { await appState.exportMP3() }
        }
        .keyboardShortcut("e", modifiers: .command)
    }

    private var actionBarBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.11, blue: 0.13),
                    Color(red: 0.05, green: 0.06, blue: 0.07)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [Color.white.opacity(0.05), .clear],
                startPoint: .top,
                endPoint: .center
            )
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.black.opacity(0.6)).frame(height: 0.5)
        }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let isLoading: Bool
    let isHighlighted: Bool
    let pulse: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .progressViewStyle(.circular)
                            .tint(isHighlighted ? SkeuoColor.cyanCore : .white)
                    } else {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(isHighlighted ? SkeuoColor.cyanCore : SkeuoColor.textPrimary)
                            .shadow(color: isHighlighted ? SkeuoColor.cyanGlow.opacity(0.7) : .clear, radius: 4)
                    }
                }
                .frame(width: 22)

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isHighlighted ? .white : SkeuoColor.textPrimary)
                    .shadow(color: isHighlighted ? SkeuoColor.cyanGlow.opacity(0.45) : .clear, radius: 3)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(buttonBackground)
            .overlay(buttonHighlights)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(
                color: isHighlighted ? SkeuoColor.cyanGlow.opacity(0.5) : .black.opacity(0.45),
                radius: isHighlighted ? 12 : 5,
                y: 3
            )
            .shadow(
                color: isHighlighted ? SkeuoColor.cyanGlow.opacity(0.35) : .clear,
                radius: 22
            )
            .scaleEffect(isHighlighted && pulse ? pulseScale : 1.0)
            .animation(
                isHighlighted
                    ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
                    : .default,
                value: pulseScale
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .onChange(of: isHighlighted) { _, newValue in
            pulseScale = newValue ? 1.008 : 1.0
        }
        .onAppear {
            if isHighlighted { pulseScale = 1.008 }
        }
    }

    private var buttonBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.17, blue: 0.20),
                    Color(red: 0.07, green: 0.08, blue: 0.10),
                    Color(red: 0.04, green: 0.05, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            LinearGradient(
                colors: [Color.white.opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .center
            )

            if isHighlighted {
                RadialGradient(
                    colors: [SkeuoColor.cyanGlow.opacity(0.18), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
                .blendMode(.screen)
            }
        }
    }

    private var buttonHighlights: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isHighlighted
                            ? [SkeuoColor.cyanCore.opacity(0.9), SkeuoColor.cyanGlow.opacity(0.35)]
                            : [Color.white.opacity(0.20), Color.black.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.2
                )

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .inset(by: 1.4)
                .strokeBorder(Color.black.opacity(0.55), lineWidth: 0.6)
        }
    }
}

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(SkeuoColor.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.23, blue: 0.26),
                        Color(red: 0.12, green: 0.13, blue: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.black.opacity(0.45)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }
}
