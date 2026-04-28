import SwiftUI

struct ProcessingSpinner: View {
    let size: CGFloat
    let tint: Color

    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0.16, to: 0.86)
            .stroke(
                tint,
                style: StrokeStyle(lineWidth: max(1.5, size / 7), lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
            .onDisappear { isAnimating = false }
            .accessibilityLabel(AppLocale.text("status.processing"))
    }
}
