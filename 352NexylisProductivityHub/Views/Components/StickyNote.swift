import SwiftUI

struct SignalMark: View {
    var size: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(Palette.actionGradient)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .overlay(
                Image(systemName: "waveform.path")
                    .font(.system(size: size * 0.48, weight: .bold))
                    .foregroundColor(Color.white)
                    .shadow(color: Color.black.opacity(0.35), radius: 1, y: 1)
            )
            .shadow(color: Palette.primary.opacity(0.55), radius: 4, y: 2)
            .shadow(color: Color.black.opacity(0.35), radius: 2, y: 1)
    }
}

/// Legacy alias kept for call sites still using PushPin.
struct PushPin: View {
    var size: CGFloat = 16

    var body: some View {
        SignalMark(size: size)
    }
}

struct DepthFill: View {
    var cornerRadius: CGFloat = 14
    var emphasized: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(emphasized ? Palette.actionGradient : Palette.chipGradient)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(emphasized ? 0.4 : 0.28),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: 6, y: 3)
            .shadow(
                color: emphasized ? Palette.primary.opacity(0.45) : Color.black.opacity(0.15),
                radius: emphasized ? 8 : 3,
                y: 2
            )
    }
}

struct StickyNote<Content: View>: View {
    var tilt: Double = 0
    var showsPin: Bool = false
    var compact: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(compact ? 14 : 18)
            .padding(.leading, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .offset(y: 5)
                        .blur(radius: 1)

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Palette.panelGradient)

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.42),
                                    Color.white.opacity(0.08),
                                    Palette.primary.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.4
                        )

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.14),
                                    Color.clear,
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Palette.accent, Palette.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 5)
                    .padding(.vertical, compact ? 12 : 16)
                    .padding(.leading, 3)
                    .shadow(color: Palette.primary.opacity(0.65), radius: 5, x: 1)
            }
            .shadow(color: Color.black.opacity(0.45), radius: 14, y: 8)
            .shadow(color: Palette.primary.opacity(0.22), radius: 8, y: 3)
            .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
    }
}
