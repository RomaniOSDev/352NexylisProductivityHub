import SwiftUI

struct CorkHeader: View {
    @Binding var page: Int
    var onSettings: () -> Void

    private let titles = ["Dayline", "Focus", "Cadence", "Radar"]

    var body: some View {
        HStack(spacing: 10) {
            Text(titles[safe: page] ?? "Dayline")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(Palette.ink)
                .shadow(color: Color.black.opacity(0.45), radius: 2, y: 1)
                .lineLimit(1)

            Spacer(minLength: 6)

            SignalTabRow(count: titles.count, current: page) { index in
                page = index
            }

            Button(action: onSettings) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.white)
                    .frame(width: 30, height: 30)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(Palette.actionGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: Palette.primary.opacity(0.4), radius: 4, y: 2)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }
}

struct SignalTabRow: View {
    let count: Int
    let current: Int
    var onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    onSelect(index)
                } label: {
                    Capsule()
                        .fill(
                            index == current
                            ? Palette.actionGradient
                            : LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.black.opacity(0.25)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: index == current ? 18 : 7, height: 6)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(index == current ? 0.35 : 0.15), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dotLabel(index))
            }
        }
    }

    private func dotLabel(_ index: Int) -> String {
        switch index {
        case 0: return "Dayline"
        case 1: return "Focus"
        case 2: return "Cadence"
        case 3: return "Radar"
        default: return "Page \(index + 1)"
        }
    }
}

/// Legacy name used by older call sites.
typealias CorkDotRow = SignalTabRow

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
