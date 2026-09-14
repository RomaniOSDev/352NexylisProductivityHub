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
        StickyNote(tilt: -1.5) {
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
        StickyNote(tilt: 1.1, compact: true) {
            VStack(alignment: .leading, spacing: 10) {
                Text("FOCUS PIN")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                if store.pendingPins.isEmpty {
                    Text("No pending pins to lock onto.")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))
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
                    .foregroundColor(Color.white.opacity(0.7))
            }
        }
        .tint(Palette.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Palette.surface.opacity(0.72))
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
        StickyNote(tilt: 2) {
            VStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("Set your focus intervals using the slider above to get started")
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
                Text("Start pulse")
                    .font(.system(.headline, design: .rounded))
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Palette.accent, Palette.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
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
                .foregroundColor(Color.white.opacity(0.75))
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
                    .foregroundColor(Color.white)
                PushPin(size: 14)
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
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Palette.accent, Palette.primary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .buttonStyle(.plain)
    }

    private var interruptionStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INTERRUPTIONS")
                .font(.caption.weight(.bold))
                .foregroundColor(Palette.accent)
            ForEach(store.interruptions.prefix(4)) { item in
                HStack(alignment: .top, spacing: 8) {
                    PushPin(size: 9)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.note)
                            .font(.subheadline)
                            .foregroundColor(Color.white)
                        Text(monoTime(item.at))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(12)
        .background(Palette.surface.opacity(0.55))
    }

    private var resumeSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                StickyNote(tilt: -1.2) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Session complete. Add a resume note?")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(Color.white)
                        TextField("Resumed after interruption", text: $resumeNote)
                            .foregroundColor(Color.white)
                            .submitLabel(.done)
                            .onSubmit { BoardKeyboard.dismiss() }
                        Button("Pin this as a task") {
                            store.pinFromInterruption(note: resumeNote, relatedTaskID: store.focusedPinID)
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
                    Button("Pin note") {
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
                            Capsule()
                                .fill(selected == pin.id ? Palette.primary : Palette.background.opacity(0.4))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
