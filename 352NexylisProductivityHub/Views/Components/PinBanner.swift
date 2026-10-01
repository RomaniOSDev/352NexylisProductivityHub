import SwiftUI

struct PinBanner: View {
    let imageName: String

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                        .offset(y: 6)
                        .blur(radius: 2)

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Palette.surface)
                        .overlay {
                            Image(imageName)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.22), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.08), Palette.primary.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.4
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 14, y: 8)
            .shadow(color: Palette.primary.opacity(0.2), radius: 8, y: 3)
    }
}
