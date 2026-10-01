import SwiftUI

enum Palette {
    static let background = Color("AppBackground")
    static let surface = Color("AppSurface")
    static let primary = Color("AppPrimary")
    static let accent = Color("AppAccent")

    static let ink = Color.white
    static let inkSoft = Color.white.opacity(0.92)
    static let inkMuted = Color.white.opacity(0.82)

    static var panelGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.16),
                surface.opacity(0.55),
                background.opacity(0.96),
                Color.black.opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var chipGradient: LinearGradient {
        LinearGradient(
            colors: [
                surface.opacity(0.95),
                background.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var actionGradient: LinearGradient {
        LinearGradient(
            colors: [accent, primary, primary.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
