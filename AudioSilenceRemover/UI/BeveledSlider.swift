import SwiftUI

struct BeveledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let formattedValue: String
    var isEnabled: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(SkeuoColor.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                Text(formattedValue)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(isEnabled ? SkeuoColor.cyanCore : SkeuoColor.textMuted)
                    .shadow(color: isEnabled ? SkeuoColor.cyanGlow.opacity(0.6) : .clear, radius: 3)
            }

            Slider(value: $value, in: range, step: step)
                .controlSize(.small)
                .tint(SkeuoColor.cyanGlow)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.black.opacity(0.45))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.black.opacity(0.7), Color.white.opacity(0.08)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .opacity(isEnabled ? 1 : 0.4)
                .disabled(!isEnabled)
        }
    }
}
