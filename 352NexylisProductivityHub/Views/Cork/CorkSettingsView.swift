import SwiftUI
import UIKit

struct CorkSettingsView: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    settingsToggle(
                        title: "Sound",
                        detail: "Play a cue when a pulse cycle ends.",
                        isOn: Binding(get: { store.soundEnabled }, set: { store.setSoundEnabled($0) }),
                        tilt: -1.4
                    )
                    settingsToggle(
                        title: "Haptic",
                        detail: "Vibrate on cycle end and habit checks.",
                        isOn: Binding(get: { store.hapticEnabled }, set: { store.setHapticEnabled($0) }),
                        tilt: 1.2
                    )
                    settingsToggle(
                        title: "Auto-continue Pulse",
                        detail: "Start the next focus or break automatically.",
                        isOn: Binding(get: { store.autoContinuePulse }, set: { store.setAutoContinuePulse($0) }),
                        tilt: 0
                    )
                    settingsCard(title: "Rate Us", detail: "Leave a mark if the board helps.", tilt: -1.8) {
                        AppLinks.rateApp()
                    }
                    settingsCard(title: "Privacy", detail: "Read how board data stays local.", tilt: 0) {
                        open(AppLinks.privacy.rawValue)
                    }
                    settingsCard(title: "Terms", detail: "The ground rules for this board.", tilt: 1.6) {
                        open(AppLinks.terms.rawValue)
                    }
                    settingsCard(title: "Reset All Data", detail: "Clears pins, habits, and pulse history.", tilt: 0, destructive: true) {
                        confirmReset = true
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .navigationTitle("Board")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
            }
            .confirmationDialog(
                "Reset all board data?",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset All Data", role: .destructive) {
                    store.resetAllData()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears pins, habits, interruptions, and focus history.")
            }
        }
    }

    private func settingsCard(title: String, detail: String, tilt: Double, destructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            StickyNote(tilt: tilt, compact: true) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(destructive ? Palette.accent : Color.white)
                        Text(detail)
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.75))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Palette.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func settingsToggle(title: String, detail: String, isOn: Binding<Bool>, tilt: Double) -> some View {
        StickyNote(tilt: tilt, compact: true) {
            Toggle(isOn: isOn) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(Color.white)
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(Color.white.opacity(0.75))
                }
            }
            .tint(Palette.primary)
        }
    }

    private func open(_ value: String) {
        guard let url = URL(string: value) else { return }
        UIApplication.shared.open(url)
    }
}
