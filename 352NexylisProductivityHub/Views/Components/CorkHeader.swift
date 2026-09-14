import SwiftUI

struct CorkHeader: View {
    @Binding var page: Int
    var onSettings: () -> Void

    private let titles = ["Pins", "Pulse", "Streaks", "Stats"]

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(titles[safe: page] ?? "Pins")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(Color.white)

                CorkDotRow(count: titles.count, current: page) { index in
                    page = index
                }
            }

            Spacer(minLength: 8)

            Button(action: onSettings) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Palette.accent, Palette.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Palette.primary.opacity(0.45), radius: 4, y: 2)
                    Image(systemName: "pin.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color.white)
                        .rotationEffect(.degrees(38))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
}

struct CorkDotRow: View {
    let count: Int
    let current: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    onSelect(index)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Palette.surface.opacity(index == current ? 0.35 : 0.55))
                            .frame(width: index == current ? 18 : 10, height: index == current ? 18 : 10)
                        if index == current {
                            PushPin(size: 12)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dotLabel(index))
            }
        }
    }

    private func dotLabel(_ index: Int) -> String {
        switch index {
        case 0: return "Pins"
        case 1: return "Pulse"
        case 2: return "Streaks"
        case 3: return "Stats"
        default: return "Page \(index + 1)"
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
