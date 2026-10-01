import SwiftUI

struct StreakLogView: View {
    @EnvironmentObject private var store: BoardStore
    @State private var editorHabit: HabitPin?
    @State private var showEditor = false
    @State private var deleteTarget: HabitPin?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PinBanner(imageName: "BannerHabits")

                Button {
                    editorHabit = nil
                    showEditor = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add cadence")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Spacer()
                        SignalMark(size: 12)
                    }
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(DepthFill(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                if store.habits.isEmpty {
                    emptyHabits
                } else {
                    ForEach(Array(store.habits.enumerated()), id: \.element.id) { index, habit in
                        habitCard(habit, index: index)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showEditor) {
            HabitEditorSheet(existing: editorHabit)
                .environmentObject(store)
        }
        .confirmationDialog("Remove this cadence?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let deleteTarget {
                    store.deleteHabit(deleteTarget)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        }
    }

    private var emptyHabits: some View {
        StickyNote {
            VStack(spacing: 10) {
                Image(systemName: "metronome.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("No cadence yet")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Color.white)
                Text("Lock repeating rhythms that protect focus between sealed days.")
                    .font(.subheadline)
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.top, 8)
    }

    private func habitCard(_ habit: HabitPin, index: Int) -> some View {
        let today = DayStamp.string()
        let doneToday = habit.lastCompletedDay == today
        let marks = store.markedDays(for: habit)

        return StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color.white)
                        HStack(spacing: 6) {
                            Text("\(habit.streak)")
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundColor(Palette.accent)
                            Text(habit.streak == 1 ? "day" : "days")
                                .font(.caption)
                                .foregroundColor(Palette.inkMuted)
                        }
                        if let reminder = habit.reminderTime {
                            Text(timeLabel(reminder))
                                .font(.system(.caption, design: .monospaced).weight(.semibold))
                                .foregroundColor(Palette.inkSoft)
                        }
                    }
                    Spacer()
                    Button {
                        store.toggleHabitToday(habit)
                    } label: {
                        Image(systemName: doneToday ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(doneToday ? Palette.accent : Palette.inkMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(doneToday ? "Undo today" : "Complete today")
                }

                weekStrip(marks: marks, skipped: habit.skippedDay)

                if store.canSkipMiss(habit) {
                    Button("Skip yesterday") {
                        store.skipMiss(for: habit)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Palette.accent)
                }

                HStack {
                    Button("Edit") {
                        editorHabit = habit
                        showEditor = true
                    }
                    Button("Remove", role: .destructive) {
                        deleteTarget = habit
                    }
                    Spacer()
                    if index > 0 {
                        Button {
                            store.moveHabit(from: index, by: -1)
                        } label: {
                            Image(systemName: "chevron.up")
                        }
                        .accessibilityLabel("Move up")
                    }
                    if index < store.habits.count - 1 {
                        Button {
                            store.moveHabit(from: index, by: 1)
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                        .accessibilityLabel("Move down")
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(Palette.accent)
            }
        }
    }

    private func weekStrip(marks: Set<String>, skipped: String?) -> some View {
        let days = lastSevenDays()
        return HStack(spacing: 6) {
            ForEach(days, id: \.stamp) { day in
                VStack(spacing: 5) {
                    Text(day.letter)
                        .font(.system(.caption2, design: .monospaced).weight(.bold))
                        .foregroundColor(Palette.inkMuted)
                    ZStack {
                        if skipped == day.stamp {
                            Circle()
                                .stroke(Palette.accent, lineWidth: 2)
                                .frame(width: 22, height: 22)
                        } else {
                            Circle()
                                .fill(marks.contains(day.stamp) ? Palette.primary : Palette.background.opacity(0.35))
                                .frame(width: 22, height: 22)
                            if marks.contains(day.stamp) {
                                SignalMark(size: 8)
                            }
                        }
                    }
                    .frame(width: 22, height: 22)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func lastSevenDays() -> [(stamp: String, letter: String)] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            let letter = symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "?"
            return (DayStamp.string(from: date), letter)
        }
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
