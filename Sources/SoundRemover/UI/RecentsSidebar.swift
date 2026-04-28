import SwiftUI

struct RecentsSidebar: View {
    @ObservedObject var appState: AppState
    var onPickFile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().background(Color.white.opacity(0.08))
            recentsList
            Spacer(minLength: 0)
            footer
        }
        .background(sidebarBackground)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                SkeuoLED(color: SkeuoColor.cyanCore, size: 8)
                Text(AppLocale.text("sidebar.title"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SkeuoColor.textPrimary)
                Spacer()
            }

            Button {
                onPickFile()
            } label: {
                Label(AppLocale.text("sidebar.import"), systemImage: "tray.and.arrow.down.fill")
            }
            .buttonStyle(SkeuoButtonStyle(prominent: true))
            .disabled(appState.isProcessing)
        }
        .padding(.horizontal, 14)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var recentsList: some View {
        Group {
            if appState.recents.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 22))
                        .foregroundStyle(SkeuoColor.textMuted)
                    Text(AppLocale.text("sidebar.empty"))
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(SkeuoColor.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 18)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocale.text("sidebar.recents"))
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(SkeuoColor.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.top, 6)

                    ScrollView {
                        LazyVStack(spacing: 3) {
                            ForEach(appState.recents) { recent in
                                RecentRow(
                                    recent: recent,
                                    isSelected: appState.selectedFileCanonicalPath == recent.canonicalPath
                                ) {
                                    Task { await appState.openRecent(recent) }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.black.opacity(0.7), Color.white.opacity(0.06)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .padding(.horizontal, 10)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if !appState.recents.isEmpty {
                Button {
                    appState.clearRecents()
                } label: {
                    Text(AppLocale.text("sidebar.clear"))
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(SkeuoColor.textSecondary)
            }
            Spacer()
            ScrewHead(size: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.2), Color.black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var sidebarBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.21, blue: 0.23),
                    Color(red: 0.10, green: 0.11, blue: 0.13),
                    Color(red: 0.05, green: 0.06, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                let lineCount = Int(size.height / 1.6)
                for index in 0..<lineCount {
                    let y = CGFloat(index) * 1.6
                    let alpha = Double.random(in: 0.015...0.05)
                    let color = (index % 2 == 0)
                        ? Color.white.opacity(alpha)
                        : Color.black.opacity(alpha * 1.3)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.5)
                }
            }
            .opacity(0.5)
            .blendMode(.overlay)

            LinearGradient(
                colors: [Color.white.opacity(0.04), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .overlay(alignment: .trailing) {
            LinearGradient(
                colors: [Color.black.opacity(0.55), .clear],
                startPoint: .trailing,
                endPoint: .leading
            )
            .frame(width: 6)
        }
        .ignoresSafeArea()
    }
}

private struct RecentRow: View {
    let recent: RecentFile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? SkeuoColor.cyanCore : SkeuoColor.textSecondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(recent.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(SkeuoColor.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    if let duration = recent.formattedDuration {
                        Text(duration)
                            .font(.system(size: 10))
                            .monospacedDigit()
                            .foregroundStyle(SkeuoColor.textMuted)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? SkeuoColor.cyanGlow.opacity(0.18) : Color.clear)
            )
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(SkeuoColor.cyanGlow.opacity(0.45), lineWidth: 0.6)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
