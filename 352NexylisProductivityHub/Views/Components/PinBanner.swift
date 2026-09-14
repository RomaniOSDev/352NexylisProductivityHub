import SwiftUI

struct PinBanner: View {
    let imageName: String

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .background {
                Palette.surface
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipped()
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [Color.clear, Palette.background.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .topTrailing) {
                PushPin(size: 18)
                    .padding(.top, 8)
                    .padding(.trailing, 14)
            }
    }
}
