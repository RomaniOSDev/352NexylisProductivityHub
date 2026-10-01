import SwiftUI

struct PinBoardView: View {
    @EnvironmentObject private var store: BoardStore
    @State private var showCompleted = false
    @State private var editorPin: WorkPin?
    @State private var showEditor = false
    @State private var pendingOffer: CompleteOffer = .none
    @State private var offerPin: WorkPin?
    @State private var showOffer = false
    @State private var showInterruptSheet = false
    @State private var interruptNote = ""
    @State private var interruptKind: InterruptKind = .other
    @State private var deleteTarget: WorkPin?
    @State private var showShutdown = false
    @State private var showBrief = false

    private var visibleTasks: [WorkPin] {
        store.tasks.filter { pin in
            showCompleted ? pin.completedAt != nil : pin.completedAt == nil
        }
    }

    var body: some View {
        List {
            PinBanner(imageName: "BannerKanban")
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if store.shouldShowMorningBrief || showBrief {
                morningBriefCard
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 10, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            filterRow
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if !showCompleted && todayHasItems {
                todayStrip
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            addRow
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if store.tasks.isEmpty {
                emptyBoard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 28, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else if visibleTasks.isEmpty {
                filterEmpty
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 28, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                prioritySections
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .onAppear {
            if store.shouldShowMorningBrief {
                showBrief = true
            }
        }
        .sheet(isPresented: $showEditor) {
            PinEditorSheet(existing: editorPin)
                .environmentObject(store)
        }
        .sheet(isPresented: $showInterruptSheet) {
            interruptionSheet
        }
        .sheet(isPresented: $showShutdown) {
            ShutdownSheet()
                .environmentObject(store)
        }
        .alert("Signal captured", isPresented: $showOffer, presenting: offerPin) { pin in
            Button("Tag interruption") {
                interruptNote = ""
                interruptKind = .other
                showInterruptSheet = true
            }
            if let title = habitTitle(from: pendingOffer) {
                Button("Add cadence: \(title)") {
                    store.pinSuggestedHabit(title)
                }
            }
            Button("Keep going", role: .cancel) {}
        } message: { pin in
            Text(offerMessage(for: pin))
        }
        .confirmationDialog("Remove this signal?", isPresented: Binding(
            get: { deleteTarget != nil },
            set: { if !$0 { deleteTarget = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let deleteTarget {
                    store.deleteTask(deleteTarget)
                }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) {
                deleteTarget = nil
            }
        }
    }

    private var morningBriefCard: some View {
        StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MORNING BRIEF")
                        .font(.caption.weight(.bold))
                        .foregroundColor(Palette.accent)
                    Spacer()
                    Text("Quiet \(store.quietWindow.label)")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Palette.inkMuted)
                }

                Text("Yesterday’s seal carried these into today.")
                    .font(.subheadline)
                    .foregroundColor(Palette.inkSoft)

                ForEach(store.carriedBriefPins.prefix(3)) { pin in
                    HStack(spacing: 10) {
                        SignalMark(size: 12)
                        Text(pin.title)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.white)
                            .lineLimit(1)
                        Spacer()
                        Button("Focus") {
                            store.focusPin(pin.id)
                            store.dismissMorningBrief()
                            showBrief = false
                            NotificationCenter.default.post(name: BoardNote.openPulse, object: nil)
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(Palette.accent)
                    }
                }

                if let residue = store.lastShutdown?.residueNote, !residue.isEmpty {
                    Text("Residue: \(residue)")
                        .font(.caption)
                        .foregroundColor(Palette.inkMuted)
                }

                Button("Start day") {
                    store.dismissMorningBrief()
                    showBrief = false
                }
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
            }
        }
    }

    private var filterRow: some View {
        HStack(spacing: 8) {
            chip("Open", active: !showCompleted) { showCompleted = false }
            chip("Done", active: showCompleted) { showCompleted = true }
            Spacer()
            Text("\(store.completedTaskCount)")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundColor(Palette.accent)
            Text("cleared")
                .font(.caption)
                .foregroundColor(Palette.inkMuted)
        }
    }

    private var addRow: some View {
        HStack(spacing: 8) {
            Button {
                editorPin = nil
                showEditor = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.headline)
                    Text("Add signal")
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

            Button {
                showShutdown = true
            } label: {
                Text(store.isDaySealed ? "Sealed" : "Seal day")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(DepthFill(cornerRadius: 14, emphasized: !store.isDaySealed))
            }
            .buttonStyle(.plain)
        }
    }

    private var todayHasItems: Bool {
        !store.overduePins.isEmpty || !store.dueTodayPins.isEmpty || !store.openHabits.isEmpty
    }

    @ViewBuilder
    private var todayStrip: some View {
        let overdue = store.overduePins
        let dueToday = store.dueTodayPins
        let habits = store.openHabits
        StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 10) {
                Text("LIVE RAIL")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                if !overdue.isEmpty {
                    todayGroup(title: "Overdue", pins: Array(overdue.prefix(3)))
                }
                if !dueToday.isEmpty {
                    todayGroup(title: "Due later", pins: Array(dueToday.prefix(3)))
                }
                if !habits.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cadence open")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(Palette.inkMuted)
                        ForEach(habits.prefix(3)) { habit in
                            Button {
                                store.toggleHabitToday(habit)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "circle")
                                        .font(.caption)
                                        .foregroundColor(Palette.accent)
                                    Text(habit.title)
                                        .font(.subheadline)
                                        .foregroundColor(Color.white)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func todayGroup(title: String, pins: [WorkPin]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundColor(Palette.inkMuted)
            ForEach(pins) { pin in
                HStack(spacing: 8) {
                    SignalMark(size: 8)
                    Text(pin.title)
                        .font(.subheadline)
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                    Spacer()
                    Button {
                        finish(pin)
                    } label: {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Palette.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Complete")
                }
            }
        }
    }

    private var emptyBoard: some View {
        StickyNote {
            VStack(spacing: 10) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("Dayline is clear")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Color.white)
                Text("Add the work signals you want to protect today, then seal the day when you shut down.")
                    .font(.subheadline)
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var filterEmpty: some View {
        StickyNote {
            Text(showCompleted ? "No cleared signals yet." : "No open signals.")
                .font(.system(.body, design: .rounded))
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder
    private var prioritySections: some View {
        ForEach(PinPriority.allCases) { priority in
            priorityGroup(priority)
        }
    }

    @ViewBuilder
    private func priorityGroup(_ priority: PinPriority) -> some View {
        let group = visibleTasks
            .filter { $0.priority == priority }
            .sorted { $0.dueDate < $1.dueDate }
        if !group.isEmpty {
            priorityHeader(priority)
            ForEach(group) { pin in
                pinRow(pin)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if pin.completedAt == nil {
                            Button("+1h") { store.snooze(pin, seconds: 3600) }
                                .tint(Palette.surface)
                            Button("+1d") { store.snooze(pin, seconds: 86400) }
                                .tint(Palette.primary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if pin.completedAt == nil {
                            Button("Done") { finish(pin) }
                                .tint(Palette.primary)
                        } else {
                            Button("Undo") { store.uncomplete(pin) }
                                .tint(Palette.surface)
                        }
                        Button("Delete", role: .destructive) {
                            deleteTarget = pin
                        }
                    }
            }
        }
    }

    private func priorityHeader(_ priority: PinPriority) -> some View {
        HStack(spacing: 8) {
            SignalMark(size: 10)
            Text(priority.label.uppercased())
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
        }
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 2, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func pinRow(_ pin: WorkPin) -> some View {
        StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pin.title)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color.white)
                        Text(pin.category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Palette.accent)
                    }
                    Spacer()
                    if pin.completedAt == nil {
                        Button {
                            finish(pin)
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(Palette.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Complete")
                    }
                }

                Text(dueLabel(pin.dueDate))
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                    .foregroundColor(pin.isOverdue ? Palette.accent : Palette.inkSoft)

                HStack {
                    Button("Edit") {
                        editorPin = pin
                        showEditor = true
                    }
                    if pin.completedAt == nil {
                        Button("Focus") {
                            store.focusPin(pin.id)
                            NotificationCenter.default.post(name: BoardNote.openPulse, object: nil)
                        }
                    }
                    Spacer()
                    Button("Remove", role: .destructive) {
                        deleteTarget = pin
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(Palette.accent)
            }
        }
    }

    private func chip(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(DepthFill(cornerRadius: 10, emphasized: active))
        }
        .buttonStyle(.plain)
    }

    private func finish(_ pin: WorkPin) {
        let offer = store.complete(pin)
        offerPin = pin
        pendingOffer = offer
        if offer != .none {
            showOffer = true
        }
    }

    private func habitTitle(from offer: CompleteOffer) -> String? {
        switch offer {
        case .habit(let title), .both(let title):
            return title
        default:
            return nil
        }
    }

    private func offerMessage(for pin: WorkPin) -> String {
        if let title = habitTitle(from: pendingOffer) {
            return "\(pin.category.rawValue) keeps looping. Tag the interruption, or lock a cadence: \(title)."
        }
        return "Tag what pulled focus off this signal?"
    }

    private func dueLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM  HH:mm"
        return formatter.string(from: date)
    }

    private var interruptionSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                StickyNote {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What pulled the signal?")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(InterruptKind.allCases) { kind in
                                    Button {
                                        interruptKind = kind
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: kind.symbol)
                                            Text(kind.label)
                                        }
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(Palette.ink)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(DepthFill(cornerRadius: 10, emphasized: interruptKind == kind))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        TextField("Optional note", text: $interruptNote)
                            .foregroundColor(Color.white)
                            .submitLabel(.done)
                            .onSubmit { BoardKeyboard.dismiss() }

                        Button("Log and queue follow-up") {
                            store.pinFromInterruption(
                                note: interruptNote,
                                relatedTaskID: offerPin?.id,
                                kind: interruptKind
                            )
                            showInterruptSheet = false
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(Palette.accent)
                    }
                }
                Spacer()
            }
            .padding(18)
            .studioBackdrop()
            .navigationTitle("Interruption tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showInterruptSheet = false }
                        .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        store.logInterruption(
                            note: interruptNote,
                            relatedTaskID: offerPin?.id,
                            kind: interruptKind
                        )
                        showInterruptSheet = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }
}
