import SwiftUI

struct WaveformView: View {
    let model: WaveformModel
    let playbackState: PlaybackState
    let source: WaveformSource
    let onSeek: (Double) -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                gridOverlay(size: proxy.size)

                waveformPath(size: proxy.size)
                    .fill(
                        LinearGradient(
                            colors: [SkeuoColor.cyanCore, SkeuoColor.cyanGlow.opacity(0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: SkeuoColor.cyanGlow.opacity(0.7), radius: 4)
                    .shadow(color: SkeuoColor.cyanGlow.opacity(0.4), radius: 10)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 10)

                if playbackState.source == source, playbackState.duration > 0 {
                    let progress = CGFloat(playbackState.currentTime / max(playbackState.duration, 0.001))
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1.5)
                        .offset(x: max(0, min(proxy.size.width - 2, proxy.size.width * progress)))
                        .shadow(color: .white.opacity(0.85), radius: 4)
                        .shadow(color: SkeuoColor.cyanGlow.opacity(0.7), radius: 6)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = value.location.x / max(proxy.size.width, 1)
                        onSeek(ratio)
                    }
            )
        }
    }

    private func gridOverlay(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            let columns = 8
            for index in 1..<columns {
                let x = canvasSize.width * CGFloat(index) / CGFloat(columns)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: canvasSize.height))
                context.stroke(path, with: .color(Color.white.opacity(0.04)), lineWidth: 0.5)
            }
            var midline = Path()
            midline.move(to: CGPoint(x: 0, y: canvasSize.height / 2))
            midline.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height / 2))
            context.stroke(midline, with: .color(SkeuoColor.cyanGlow.opacity(0.18)), lineWidth: 0.5)
        }
        .frame(width: size.width, height: size.height)
    }

    private func waveformPath(size: CGSize) -> Path {
        var path = Path()
        guard !model.amplitudes.isEmpty else { return path }

        let midY = size.height / 2
        let columnWidth = size.width / CGFloat(model.amplitudes.count)

        for (index, amplitude) in model.amplitudes.enumerated() {
            let x = CGFloat(index) * columnWidth
            let height = max(2, CGFloat(amplitude) * (size.height * 0.78))
            let rect = CGRect(x: x, y: midY - height / 2, width: max(1, columnWidth * 0.62), height: height)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: 0.8, height: 0.8))
        }

        return path
    }
}
