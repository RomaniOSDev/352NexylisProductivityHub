import SwiftUI

struct ShutdownSheet: View {
    @EnvironmentObject private var store: BoardStore
    @Environment(\.dismiss) private var dismiss

    @State private var selected: Set<UUID> = []
    @State private var interruptNote = ""
    @State private var residueKind: InterruptKind = .fatigue

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
                    if store.isDaySealed {
                        StickyNote(compact: true) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DAY ALREADY SEALED")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Palette.accent)
                                Text("You can reseal to update tomorrow’s carried three.")
                                    .font(.subheadline)
                                    .foregroundColor(Palette.inkSoft)
                            }
                        }
                    }

                    StickyNote {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CARRY THREE")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Palette.accent)
                            Text("Park up to three signals for tomorrow’s Morning Brief.")
                                .font(.footnote)
                                .foregroundColor(Palette.inkMuted)
                            if pending.isEmpty {
                                Text("No open signals to carry.")
                                    .font(.subheadline)
                                    .foregroundColor(Palette.inkSoft)
                            } else {
                                ForEach(pending) { pin in
                                    Button {
                                        toggle(pin.id)
                                    } label: {
                                        HStack {
                                            Image(systemName: selected.contains(pin.id) ? "checkmark.square.fill" : "square")
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
                        StickyNote(compact: true) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("OPEN CADENCE")
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(Palette.accent)
                                ForEach(openHabits) { habit in
                                    Button {
                                        store.toggleHabitToday(habit)
                                    } label: {
                                        HStack {
                                            Image(systemName: "circle")
                                                .foregroundColor(Palette.inkMuted)
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

                    StickyNote(compact: true) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("RESIDUE SIGNAL")
                                .font(.caption.weight(.bold))
                                .foregroundColor(Palette.accent)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(InterruptKind.allCases) { kind in
                                        Button {
                                            residueKind = kind
                                        } label: {
                                            Text(kind.label)
                                                .font(.caption2.weight(.bold))
                                                .foregroundColor(Palette.ink)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 7)
                                                .background(DepthFill(cornerRadius: 8, emphasized: residueKind == kind))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            TextField("What still pulled focus today?", text: $interruptNote)
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
            .navigationTitle("Seal the day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Seal") {
                        store.finishShutdown(
                            pinIDs: Array(selected),
                            interruptionNote: interruptNote,
                            kind: residueKind
                        )
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Palette.accent)
                }
            }
            .onAppear {
                if let carried = store.lastShutdown?.carriedPinIDs {
                    selected = Set(carried.filter { id in
                        store.tasks.contains(where: { $0.id == id && $0.completedAt == nil })
                    })
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
