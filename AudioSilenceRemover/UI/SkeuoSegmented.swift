import SwiftUI

struct SkeuoSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]
    var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options.indices, id: \.self) { index in
                let option = options[index]
                let isSelected = option.value == selection
                Button {
                    guard isEnabled else { return }
                    selection = option.value
                } label: {
                    HStack(spacing: 6) {
                        if isSelected {
                            Circle()
                                .fill(SkeuoColor.cyanCore)
                                .frame(width: 5, height: 5)
                                .shadow(color: SkeuoColor.cyanGlow.opacity(0.8), radius: 3)
                        }
                        Text(option.label)
                            .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: .rounded))
                    }
                    .foregroundStyle(isSelected ? Color.white : SkeuoColor.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 24)
                    .padding(.horizontal, 10)
                    .background {
                        if isSelected {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.20, green: 0.22, blue: 0.25),
                                        Color(red: 0.10, green: 0.11, blue: 0.13)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                LinearGradient(
                                    colors: [Color.white.opacity(0.10), .clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [SkeuoColor.cyanCore.opacity(0.7), SkeuoColor.cyanGlow.opacity(0.25)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1
                                    )
                            }
                            .shadow(color: SkeuoColor.cyanGlow.opacity(0.45), radius: 6)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
        }
        .padding(3)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.55), Color.black.opacity(0.35)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.white.opacity(0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .opacity(isEnabled ? 1 : 0.5)
    }
}
