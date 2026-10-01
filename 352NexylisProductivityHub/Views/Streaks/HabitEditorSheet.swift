import SwiftUI

struct HabitEditorSheet: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    var existing: HabitPin?

    @State private var title: String = ""
    @State private var usesReminder = false
    @State private var reminderTime: Date = Date()
    @State private var errorText: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StickyNote {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TITLE")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Palette.accent)
                            TextField("Cadence rhythm", text: $title)
                                .foregroundColor(Color.white)
                                .submitLabel(.done)
                                .onSubmit { BoardKeyboard.dismiss() }

                            Toggle(isOn: $usesReminder) {
                                Text("Daily reminder")
                                    .foregroundColor(Color.white)
                            }
                            .tint(Palette.primary)

                            if usesReminder {
                                DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(Color.white)
                                    .colorScheme(.dark)
                            }

                            Text("A local alert is scheduled at this time if you allow notifications.")
                                .font(.footnote)
                                .foregroundColor(Palette.inkMuted)

                            if !errorText.isEmpty {
                                Text(errorText)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundColor(Palette.accent)
                            }
                        }
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(existing == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pin") { save() }
                        .fontWeight(.bold)
                        .foregroundColor(Palette.accent)
                }
            }
            .onAppear(perform: hydrate)
        }
    }

    private func hydrate() {
        guard let existing else { return }
        title = existing.title
        if let reminder = existing.reminderTime {
            usesReminder = true
            reminderTime = reminder
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            errorText = "A title is required."
            return
        }
        errorText = ""
        let habit = HabitPin(
            id: existing?.id ?? UUID(),
            title: trimmed,
            reminderTime: usesReminder ? reminderTime : nil,
            lastCompletedDay: existing?.lastCompletedDay ?? "",
            streak: existing?.streak ?? 0,
            skippedDay: existing?.skippedDay
        )
        store.upsertHabit(habit)
        dismiss()
    }
}
