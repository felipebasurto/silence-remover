import SwiftUI

struct StatusBar: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 10) {
            if appState.isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .fixedSize()
            } else {
                SkeuoLED(
                    color: appState.errorMessage == nil ? SkeuoColor.cyanCore : Color(red: 1, green: 0.4, blue: 0.4),
                    glow: appState.errorMessage == nil ? SkeuoColor.cyanGlow : Color.red,
                    size: 9
                )
            }

            Text(appState.errorMessage ?? appState.statusMessage)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(appState.errorMessage == nil ? SkeuoColor.textSecondary : Color(red: 1, green: 0.55, blue: 0.55))
                .lineLimit(appState.errorMessage == nil ? 1 : 2)
                .truncationMode(.tail)

            if appState.errorMessage != nil {
                Button {
                    appState.copyDiagnosticsToPasteboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(SkeuoColor.textSecondary)
                }
                .buttonStyle(.plain)
                .help(AppLocale.text("status.copy_diagnostics_help"))
                .accessibilityLabel(AppLocale.text("status.copy_diagnostics"))
            }

            Spacer()

            if let resultSummary = appState.resultSummary {
                Text(resultSummary)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(SkeuoColor.textMuted)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .frame(height: 28)
        .background(statusBackground)
    }

    private var statusBackground: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                let lineCount = Int(size.height / 1.5)
                for index in 0..<lineCount {
                    let y = CGFloat(index) * 1.5
                    let alpha = Double.random(in: 0.01...0.04)
                    let color = (index % 2 == 0)
                        ? Color.white.opacity(alpha)
                        : Color.black.opacity(alpha * 1.5)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
            }
            .opacity(0.6)
            .blendMode(.overlay)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.85), Color.black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1.5)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).offset(y: 1.5)
        }
    }
}
