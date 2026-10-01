import SwiftUI

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Color("AppBackground")

                    Image("BgDesk")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.22)
                        .blur(radius: 0.4)

                    LinearGradient(
                        colors: [
                            Palette.background.opacity(0.35),
                            Palette.background.opacity(0.55),
                            Color.black.opacity(0.42)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.28)
                        ],
                        center: .center,
                        startRadius: 80,
                        endRadius: 520
                    )
                }
                .clipped()
                .ignoresSafeArea()
            }
    }
}

extension View {
    func studioBackdrop() -> some View {
        modifier(ScreenBackground())
    }
}
