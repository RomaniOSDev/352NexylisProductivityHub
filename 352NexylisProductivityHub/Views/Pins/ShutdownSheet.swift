import SwiftUI

struct ShutdownSheet: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<UUID> = []
    @State private var interruptNote = ""

    private var pending: [WorkPin] {
        store.tasks.filter { $0.completedAt == nil }.sorted { $0.dueDate < $1.dueDate }
    }

    private var openHabits: [HabitPin] {
        let today = DayStamp.string()
        return store.habits.filter { $0.lastCompletedDay != today }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StickyNote(tilt: -1.4) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("TOMORROW · PICK 3")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Palette.accent)
                            if pending.isEmpty {
                                Text("No pending pins to carry.")
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.8))
                            } else {
                                ForEach(pending) { pin in
                                    Button {
                                        toggle(pin.id)
                                    } label: {
                                        HStack {
                                            Image(systemName: selected.contains(pin.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(Palette.accent)
                                            Text(pin.title)
                                                .foregroundColor(Color.white)
                                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!selected.contains(pin.id) && selected.count >= 3)
                                    .opacity(!selected.contains(pin.id) && selected.count >= 3 ? 0.45 : 1)
                                }
                            }
                        }
                    }

                    if !openHabits.isEmpty {
                        StickyNote(tilt: 1.2, compact: true) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("OPEN HABITS")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Palette.accent)
                                ForEach(openHabits) { habit in
                                    Button {
                                        store.toggleHabitToday(habit)
                                    } label: {
                                        HStack {
                                            Image(systemName: "circle")
                                                .foregroundColor(Color.white.opacity(0.7))
                                            Text(habit.title)
                                                .foregroundColor(Color.white)
                                                .font(.subheadline)
                                            Spacer()
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    StickyNote(tilt: 0, compact: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ONE INTERRUPTION PATTERN")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Palette.accent)
                            TextField("What pulled you off today?", text: $interruptNote)
                                .foregroundColor(Color.white)
                                .submitLabel(.done)
                                .onSubmit { BoardKeyboard.dismiss() }
                        }
                    }
                }
                .padding(18)
            }
            .studioBackdrop()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("End the day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Park") {
                        store.finishShutdown(
                            pinIDs: Array(selected),
                            interruptionNote: interruptNote
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if selected.contains(id) {
            selected.remove(id)
        } else if selected.count < 3 {
            selected.insert(id)
        }
    }
}
