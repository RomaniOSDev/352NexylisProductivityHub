import SwiftUI

struct PulseTimerView: View {
    @EnvironmentObject private var store: BoardStore
    @State private var resumeNote = ""
    @State private var showResumeSheet = false

    private var progress: CGFloat {
        let total = CGFloat(store.isOnBreak ? store.breakDurationSec : store.focusDurationSec)
        guard total > 0 else { return 0 }
        return 1 - (CGFloat(store.remainingSec) / total)
    }

    private var showEmpty: Bool {
        !store.hasStartedPulse && store.completedSessions == 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PinBanner(imageName: "BannerFocus")
                sliders
                focusPicker
                autoContinueRow
                if showEmpty {
                    emptyPulse
                    startRow
                } else {
                    sessionBadge
                    ringBlock
                    controls
                }
                if !store.interruptions.isEmpty {
                    interruptionStrip
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .onChange(of: store.pendingResumePrompt) { pending in
            if pending {
                resumeNote = ""
                showResumeSheet = true
            }
        }
        .sheet(isPresented: $showResumeSheet, onDismiss: {
            store.dismissResumePrompt()
        }) {
            resumeSheet
        }
    }

    private var sliders: some View {
        StickyNote {
            VStack(alignment: .leading, spacing: 12) {
                labeledSlider(
                    title: "Focus",
                    seconds: store.focusDurationSec,
                    range: 300...3600
                ) { store.setFocusDuration($0) }

                labeledSlider(
                    title: "Break",
                    seconds: store.breakDurationSec,
                    range: 60...1200
                ) { store.setBreakDuration($0) }
            }
        }
        .disabled(store.isTimerRunning)
        .opacity(store.isTimerRunning ? 0.7 : 1)
    }

    private var focusPicker: some View {
        StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 10) {
                Text("LOCKED SIGNAL")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                if store.pendingPins.isEmpty {
                    Text("No open dayline signals to lock.")
                        .font(.subheadline)
                        .foregroundColor(Palette.inkSoft)
                } else {
                    if let focused = store.focusedPin {
                        Text(focused.title)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.white)
                    }
                    FlexiblePinChips(pins: Array(store.pendingPins.prefix(8)), selected: store.focusedPinID) { pin in
                        store.setFocusedPin(pin.id)
                    }
                }
            }
        }
        .disabled(store.isTimerRunning)
        .opacity(store.isTimerRunning ? 0.7 : 1)
    }

    private var autoContinueRow: some View {
        Toggle(isOn: Binding(
            get: { store.autoContinuePulse },
            set: { store.setAutoContinuePulse($0) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Auto-continue cycles")
                    .foregroundColor(Color.white)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Text("Start the next focus or break when a cycle ends.")
                    .font(.caption)
                    .foregroundColor(Palette.inkMuted)
            }
        }
        .tint(Palette.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(DepthFill(cornerRadius: 14))
    }

    private func labeledSlider(title: String, seconds: Int, range: ClosedRange<Double>, onChange: @escaping (Int) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                Spacer()
                Text(clockLabel(seconds))
                    .font(.system(.body, design: .monospaced).weight(.bold))
                    .foregroundColor(Color.white)
            }
            Slider(
                value: Binding(
                    get: { Double(seconds) },
                    set: { onChange(Int($0.rounded())) }
                ),
                in: range,
                step: 60
            )
            .tint(Palette.primary)
        }
    }

    private var emptyPulse: some View {
        StickyNote {
            VStack(spacing: 10) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("Set focus length, lock one dayline signal, then run a protected cycle.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Color.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }

    private var startRow: some View {
        Button(action: store.startTimer) {
            HStack {
                Image(systemName: "play.fill")
                Text("Start focus")
                    .font(.system(.headline, design: .rounded))
            }
            .foregroundColor(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DepthFill(cornerRadius: 14, emphasized: true))
            .shadow(color: Palette.primary.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var sessionBadge: some View {
        HStack {
            Text(store.isOnBreak ? "BREAK" : "FOCUS")
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
            Spacer()
            Text("\(store.completedSessions)")
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundColor(Color.white)
            Text("sessions")
                .font(.caption)
                .foregroundColor(Palette.inkMuted)
        }
        .padding(.horizontal, 4)
    }

    private var ringBlock: some View {
        ZStack {
            Circle()
                .stroke(Palette.surface.opacity(0.55), lineWidth: 12)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    LinearGradient(
                        colors: [Palette.accent, Palette.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            VStack(spacing: 6) {
                Text(clockLabel(store.remainingSec))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(Palette.ink)
                    .shadow(color: Color.black.opacity(0.55), radius: 4, y: 2)
                    .shadow(color: Palette.primary.opacity(0.35), radius: 8, y: 1)
                SignalMark(size: 14)
            }
        }
        .frame(width: 210, height: 210)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var controls: some View {
        Button {
            if store.isTimerRunning {
                store.pauseTimer()
            } else {
                store.startTimer()
            }
        } label: {
            HStack {
                Image(systemName: store.isTimerRunning ? "pause.fill" : "play.fill")
                Text(store.isTimerRunning ? "Pause" : (store.remainingSec == (store.isOnBreak ? store.breakDurationSec : store.focusDurationSec) ? "Start" : "Resume"))
                    .font(.system(.headline, design: .rounded))
            }
            .foregroundColor(Palette.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(DepthFill(cornerRadius: 14, emphasized: true))
            .shadow(color: Palette.primary.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var interruptionStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INTERRUPT TAGS")
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
            ForEach(store.interruptions.prefix(4)) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: item.kind.symbol)
                        .font(.caption)
                        .foregroundColor(Palette.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.note)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                        Text("\(item.kind.label) · \(monoTime(item.at))")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Palette.inkMuted)
                    }
                }
            }
        }
        .padding(12)
        .background(DepthFill(cornerRadius: 14))
    }

    private var resumeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                StickyNote {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Cycle ended. Capture a resume note?")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color.white)
                        TextField("What shifted attention?", text: $resumeNote)
                            .foregroundColor(Color.white)
                            .submitLabel(.done)
                            .onSubmit { BoardKeyboard.dismiss() }
                        Button("Queue as follow-up signal") {
                            store.pinFromInterruption(
                                note: resumeNote,
                                relatedTaskID: store.focusedPinID,
                                kind: .contextSwitch
                            )
                            showResumeSheet = false
                        }
                        .font(.caption.weight(.bold))
                        .foregroundColor(Palette.accent)
                    }
                }
                Spacer()
            }
            .padding(18)
            .studioBackdrop()
            .navigationTitle("Resume note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        showResumeSheet = false
                    }
                    .foregroundColor(Palette.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.appendResumeNote(resumeNote)
                        showResumeSheet = false
                    }
                    .fontWeight(.bold)
                    .foregroundColor(Palette.accent)
                }
            }
        }
    }

    private func clockLabel(_ seconds: Int) -> String {
        let safe = max(0, seconds)
        let minutes = safe / 60
        let remain = safe % 60
        return String(format: "%02d:%02d", minutes, remain)
    }

    private func monoTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE HH:mm"
        return formatter.string(from: date)
    }
}

private struct FlexiblePinChips: View {
    let pins: [WorkPin]
    let selected: UUID?
    var onSelect: (WorkPin) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(pins) { pin in
                Button {
                    onSelect(pin)
                } label: {
                    Text(pin.title)
                        .font(.caption.weight(.bold))
                        .foregroundColor(Color.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            DepthFill(cornerRadius: 10, emphasized: selected == pin.id)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
