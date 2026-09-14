import SwiftUI

struct PushPin: View {
    var size: CGFloat = 16

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Palette.accent, Palette.primary],
                    center: UnitPoint(x: 0.32, y: 0.28),
                    startRadius: 1,
                    endRadius: size * 0.7
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Palette.primary.opacity(0.55), lineWidth: 1)
            )
            .shadow(color: Palette.primary.opacity(0.45), radius: 2, x: 0, y: 1)
    }
}

struct StickyNote<Content: View>: View {
    var tilt: Double = 0
    var showsPin: Bool = true
    var compact: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(compact ? 12 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Palette.surface,
                        Palette.surface.opacity(0.84)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .top) {
                if showsPin {
                    PushPin()
                        .offset(y: -7)
                }
            }
            .shadow(color: Palette.background.opacity(0.4), radius: 5, x: 0, y: 3)
            .rotationEffect(.degrees(tilt))
    }
}
