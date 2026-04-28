import SwiftUI

enum SkeuoColor {
    static let steelLight = Color(red: 0.42, green: 0.43, blue: 0.46)
    static let steelMid = Color(red: 0.26, green: 0.27, blue: 0.30)
    static let steelDark = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let steelShadow = Color(red: 0.04, green: 0.05, blue: 0.06)

    static let darkPanel = Color(red: 0.07, green: 0.08, blue: 0.09)
    static let panelEdge = Color(red: 0.55, green: 0.57, blue: 0.60)

    static let glassTop = Color(red: 0.18, green: 0.22, blue: 0.27)
    static let glassBottom = Color(red: 0.04, green: 0.05, blue: 0.07)

    static let cyanGlow = Color(red: 0.36, green: 0.82, blue: 1.0)
    static let cyanCore = Color(red: 0.62, green: 0.92, blue: 1.0)

    static let brass = Color(red: 0.78, green: 0.56, blue: 0.22)
    static let brassDark = Color(red: 0.42, green: 0.28, blue: 0.08)

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.62)
    static let textMuted = Color.white.opacity(0.42)
}

struct BrushedMetalBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [SkeuoColor.steelLight, SkeuoColor.steelMid, SkeuoColor.steelDark],
                startPoint: .top,
                endPoint: .bottom
            )

            Canvas { context, size in
                let lineCount = Int(size.height / 1.5)
                for index in 0..<lineCount {
                    let y = CGFloat(index) * 1.5
                    let alpha = Double.random(in: 0.02...0.06)
                    let color = (index % 2 == 0)
                        ? Color.white.opacity(alpha)
                        : Color.black.opacity(alpha * 1.4)
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 0.6)
                }
            }
            .opacity(0.55)
            .blendMode(.overlay)

            LinearGradient(
                colors: [Color.white.opacity(0.05), .clear, Color.black.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

struct BeveledPanelBackground: View {
    var cornerRadius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.21, blue: 0.23),
                        Color(red: 0.12, green: 0.13, blue: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.22), Color.black.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: SkeuoColor.steelShadow.opacity(0.55), radius: 6, y: 4)
    }
}

struct GlossyScreenBackground: View {
    var cornerRadius: CGFloat = 6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [SkeuoColor.glassTop, SkeuoColor.glassBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.plusLighter)
                .opacity(0.35)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 0.5)
                .stroke(Color.black.opacity(0.85), lineWidth: 1)
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .inset(by: 1.5)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 8, x: 0, y: 4)
    }
}

struct ScrewHead: View {
    var size: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [SkeuoColor.brass, SkeuoColor.brassDark],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .overlay {
                    Circle().strokeBorder(Color.black.opacity(0.55), lineWidth: 0.6)
                }
                .shadow(color: .black.opacity(0.55), radius: 1, y: 1)

            Capsule()
                .fill(Color.black.opacity(0.55))
                .frame(width: size * 0.62, height: 1.2)
                .rotationEffect(.degrees(28))
        }
        .frame(width: size, height: size)
    }
}

struct ScreenInsetBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(GlossyScreenBackground())
    }
}

extension View {
    func skeuoScreen() -> some View {
        modifier(ScreenInsetBackground())
    }
}

struct SkeuoLED: View {
    var color: Color = SkeuoColor.cyanCore
    var glow: Color = SkeuoColor.cyanGlow
    var size: CGFloat = 10
    var isOn: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.18), Color.black],
                        center: .center,
                        startRadius: 0,
                        endRadius: size
                    )
                )
                .overlay {
                    Circle().strokeBorder(Color.black.opacity(0.85), lineWidth: 0.6)
                }
                .frame(width: size, height: size)

            Circle()
                .fill(
                    RadialGradient(
                        colors: isOn
                            ? [Color.white.opacity(0.95), color, color.opacity(0.5)]
                            : [Color(white: 0.16), Color(white: 0.06)],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size * 0.65, height: size * 0.65)
                .shadow(color: isOn ? glow.opacity(0.85) : .clear, radius: 4)
                .shadow(color: isOn ? glow.opacity(0.5) : .clear, radius: 9)
        }
    }
}

struct SkeuoButtonStyle: ButtonStyle {
    var tint: Color = SkeuoColor.cyanCore
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(prominent ? Color.white : SkeuoColor.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0.18, green: 0.19, blue: 0.21),
                        Color(red: 0.08, green: 0.09, blue: 0.11)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                LinearGradient(
                    colors: [Color.white.opacity(0.10), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: prominent
                                ? [tint.opacity(0.85), tint.opacity(0.35)]
                                : [Color.white.opacity(0.18), Color.black.opacity(0.55)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(
                color: prominent ? SkeuoColor.cyanGlow.opacity(0.55) : .black.opacity(0.45),
                radius: prominent ? 9 : 3,
                y: 2
            )
            .shadow(
                color: prominent ? tint.opacity(0.35) : .clear,
                radius: prominent ? 14 : 0
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ScrewedPanel<Content: View>: View {
    var screwSize: CGFloat = 9
    var screwInset: CGFloat = 6
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .overlay(alignment: .topLeading) { ScrewHead(size: screwSize).padding(screwInset) }
            .overlay(alignment: .topTrailing) { ScrewHead(size: screwSize).padding(screwInset) }
            .overlay(alignment: .bottomLeading) { ScrewHead(size: screwSize).padding(screwInset) }
            .overlay(alignment: .bottomTrailing) { ScrewHead(size: screwSize).padding(screwInset) }
    }
}
