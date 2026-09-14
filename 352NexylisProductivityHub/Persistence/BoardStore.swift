import Combine
import Foundation

@MainActor
final class BoardStore: ObservableObject {
    @Published var tasks: [WorkPin] = []
    @Published var habits: [HabitPin] = []
    @Published var interruptions: [InterruptionLog] = []
    @Published var completedTaskCount: Int = 0
    @Published var focusDurationSec: Int = 1500
    @Published var breakDurationSec: Int = 300
    @Published var completedSessions: Int = 0
    @Published var sessionDays: [String] = []
    @Published var lastInterruptionTime: Date?

    @Published var isTimerRunning: Bool = false
    @Published var isOnBreak: Bool = false
    @Published var timerEndDate: Date?
    @Published var remainingSec: Int = 1500
    @Published var hasStartedPulse: Bool = false
    @Published var pendingResumePrompt: Bool = false
    @Published var focusedPinID: UUID?
    @Published var autoContinuePulse: Bool = false
    @Published var soundEnabled: Bool = true
    @Published var hapticEnabled: Bool = true

    private var cancellables = Set<AnyCancellable>()
    private var applyingExternalReset = false

    private enum Key {
        static let tasks = "board.tasks"
        static let habits = "board.habits"
        static let interruptions = "board.interruptions"
        static let completedTaskCount = "board.completedTaskCount"
        static let focusDurationSec = "board.focusDurationSec"
        static let breakDurationSec = "board.breakDurationSec"
        static let completedSessions = "board.completedSessions"
        static let sessionDays = "board.sessionDays"
        static let lastInterruptionTime = "board.lastInterruptionTime"
        static let isTimerRunning = "board.isTimerRunning"
        static let isOnBreak = "board.isOnBreak"
        static let timerEndDate = "board.timerEndDate"
        static let remainingSec = "board.remainingSec"
        static let hasStartedPulse = "board.hasStartedPulse"
        static let focusedPinID = "board.focusedPinID"
        static let autoContinuePulse = "board.autoContinuePulse"
        static let soundEnabled = "board.soundEnabled"
        static let hapticEnabled = "board.hapticEnabled"
    }

    private static let allKeys: [String] = [
        Key.tasks, Key.habits, Key.interruptions, Key.completedTaskCount,
        Key.focusDurationSec, Key.breakDurationSec, Key.completedSessions, Key.sessionDays,
        Key.lastInterruptionTime, Key.isTimerRunning, Key.isOnBreak,
        Key.timerEndDate, Key.remainingSec, Key.hasStartedPulse,
        Key.focusedPinID, Key.autoContinuePulse, Key.soundEnabled, Key.hapticEnabled
    ]

    init() {
        load()
        reconcileTimerOnLaunch()
        HabitReminders.refresh(habits)
        NotificationCenter.default.publisher(for: Notification.Name("dataReset"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleExternalReset()
            }
            .store(in: &cancellables)
    }

    // MARK: - Tasks

    func upsertTask(_ pin: WorkPin) {
        if let index = tasks.firstIndex(where: { $0.id == pin.id }) {
            tasks[index] = pin
        } else {
            tasks.insert(pin, at: 0)
        }
        persist()
    }

    func deleteTask(_ pin: WorkPin) {
        tasks.removeAll { $0.id == pin.id }
        if focusedPinID == pin.id {
            focusedPinID = nil
        }
        persist()
    }

    func complete(_ pin: WorkPin) -> CompleteOffer {
        guard let index = tasks.firstIndex(where: { $0.id == pin.id }) else { return .none }
        guard tasks[index].completedAt == nil else { return .none }
        tasks[index].completedAt = Date()
        completedTaskCount += 1
        if focusedPinID == pin.id {
            focusedPinID = nil
        }
        persist()

        let suggestion = suggestedHabitTitle(for: tasks[index].category)
        if let suggestion {
            return .both(suggestion)
        }
        return .interruption
    }

    func uncomplete(_ pin: WorkPin) {
        guard let index = tasks.firstIndex(where: { $0.id == pin.id }) else { return }
        guard tasks[index].completedAt != nil else { return }
        tasks[index].completedAt = nil
        completedTaskCount = max(0, completedTaskCount - 1)
        persist()
    }

    func suggestedHabitTitle(for category: PinCategory) -> String? {
        let finished = tasks.filter { $0.category == category && $0.completedAt != nil }.count
        guard finished >= 2 else { return nil }
        let title: String
        switch category {
        case .work: title = "Daily Work sweep"
        case .client: title = "Client follow-up rhythm"
        case .home: title = "Home reset"
        case .admin: title = "Admin inbox clear"
        }
        if habits.contains(where: { $0.title.caseInsensitiveCompare(title) == .orderedSame }) {
            return nil
        }
        return title
    }

    func pinSuggestedHabit(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if habits.contains(where: { $0.title.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return
        }
        let habit = HabitPin(
            id: UUID(),
            title: trimmed,
            reminderTime: nil,
            lastCompletedDay: "",
            streak: 0,
            skippedDay: nil
        )
        habits.insert(habit, at: 0)
        persist()
        HabitReminders.refresh(habits)
    }

    func logInterruption(note: String, relatedTaskID: UUID?) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = trimmed.isEmpty ? "Interruption pattern" : trimmed
        let entry = InterruptionLog(
            id: UUID(),
            at: Date(),
            note: resolved,
            relatedTaskID: relatedTaskID
        )
        interruptions.insert(entry, at: 0)
        lastInterruptionTime = entry.at
        persist()
    }

    func pinFromInterruption(note: String, relatedTaskID: UUID?) {
        let related = relatedTaskID ?? focusedPinID
        logInterruption(note: note, relatedTaskID: related)
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = trimmed.isEmpty ? "Follow up interruption" : trimmed
        var category: PinCategory = .admin
        var priority: PinPriority = .normal
        if let related, let source = tasks.first(where: { $0.id == related }) {
            category = source.category
            priority = source.priority
        }
        let pin = WorkPin(
            id: UUID(),
            title: title,
            dueDate: Date().addingTimeInterval(3600),
            category: category,
            priority: priority,
            completedAt: nil
        )
        upsertTask(pin)
    }

    func snooze(_ pin: WorkPin, seconds: TimeInterval) {
        guard let index = tasks.firstIndex(where: { $0.id == pin.id }) else { return }
        guard tasks[index].completedAt == nil else { return }
        let base = max(tasks[index].dueDate, Date())
        tasks[index].dueDate = base.addingTimeInterval(seconds)
        persist()
    }

    func setFocusedPin(_ id: UUID?) {
        if focusedPinID == id {
            focusedPinID = nil
        } else {
            focusedPinID = id
        }
        persist()
    }

    func focusPin(_ id: UUID) {
        focusedPinID = id
        persist()
    }

    var focusedPin: WorkPin? {
        guard let focusedPinID else { return nil }
        return tasks.first(where: { $0.id == focusedPinID && $0.completedAt == nil })
    }

    var pendingPins: [WorkPin] {
        tasks.filter { $0.completedAt == nil }.sorted { $0.dueDate < $1.dueDate }
    }

    var overduePins: [WorkPin] {
        pendingPins.filter(\.isOverdue)
    }

    var dueTodayPins: [WorkPin] {
        pendingPins.filter(\.isDueToday)
    }

    var openHabits: [HabitPin] {
        let today = DayStamp.string()
        return habits.filter { $0.lastCompletedDay != today }
    }

    func finishShutdown(pinIDs: [UUID], interruptionNote: String) {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month, .day], from: Date())
        comps.day = (comps.day ?? 0) + 1
        comps.hour = 9
        comps.minute = 0
        comps.second = 0
        let due = calendar.date(from: comps) ?? Date().addingTimeInterval(86400)
        for id in pinIDs.prefix(3) {
            if let index = tasks.firstIndex(where: { $0.id == id && $0.completedAt == nil }) {
                tasks[index].dueDate = due
            }
        }
        let trimmed = interruptionNote.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            logInterruption(note: trimmed, relatedTaskID: focusedPinID)
        } else {
            persist()
        }
    }

    // MARK: - Habits

    func upsertHabit(_ habit: HabitPin) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index] = habit
        } else {
            habits.insert(habit, at: 0)
        }
        persist()
        HabitReminders.refresh(habits)
    }

    func deleteHabit(_ habit: HabitPin) {
        habits.removeAll { $0.id == habit.id }
        persist()
        HabitReminders.refresh(habits)
    }

    func toggleHabitToday(_ habit: HabitPin) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let today = DayStamp.string()
        let yesterday = offsetStamp(-1)
        let twoAgo = offsetStamp(-2)
        if habits[index].lastCompletedDay == today {
            if habits[index].skippedDay == yesterday {
                habits[index].lastCompletedDay = twoAgo
                habits[index].streak = max(0, habits[index].streak - 1)
            } else if habits[index].streak <= 1 {
                habits[index].lastCompletedDay = ""
                habits[index].streak = 0
            } else {
                habits[index].lastCompletedDay = yesterday
                habits[index].streak -= 1
            }
        } else if habits[index].lastCompletedDay == yesterday {
            habits[index].lastCompletedDay = today
            habits[index].streak += 1
        } else if habits[index].skippedDay == yesterday && habits[index].lastCompletedDay == twoAgo {
            habits[index].lastCompletedDay = today
            habits[index].streak += 1
        } else {
            habits[index].lastCompletedDay = today
            habits[index].streak = 1
        }
        persist()
        BoardFeedback.tap(haptic: hapticEnabled)
        HabitReminders.refresh(habits)
    }

    func canSkipMiss(_ habit: HabitPin) -> Bool {
        habit.streak > 0
            && habit.lastCompletedDay == offsetStamp(-2)
            && habit.skippedDay != offsetStamp(-1)
    }

    func skipMiss(for habit: HabitPin) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        guard canSkipMiss(habits[index]) else { return }
        habits[index].skippedDay = offsetStamp(-1)
        persist()
        BoardFeedback.tap(haptic: hapticEnabled)
    }

    func moveHabit(from index: Int, by offset: Int) {
        let destination = index + offset
        guard habits.indices.contains(index), habits.indices.contains(destination) else { return }
        let item = habits.remove(at: index)
        habits.insert(item, at: destination)
        persist()
    }

    func markedDays(for habit: HabitPin) -> Set<String> {
        guard habit.streak > 0, let end = DayStamp.date(from: habit.lastCompletedDay) else {
            return []
        }
        var days = Set<String>()
        for step in 0..<habit.streak {
            if let day = Calendar.current.date(byAdding: .day, value: -step, to: end) {
                days.insert(DayStamp.string(from: day))
            }
        }
        if let skipped = habit.skippedDay, !skipped.isEmpty {
            days.remove(skipped)
        }
        return days
    }

    private func offsetStamp(_ days: Int) -> String {
        DayStamp.string(from: Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date())
    }

    // MARK: - Timer

    func setFocusDuration(_ seconds: Int) {
        let clamped = min(3600, max(300, seconds))
        focusDurationSec = clamped
        if !isTimerRunning && !isOnBreak {
            remainingSec = clamped
        }
        persist()
    }

    func setBreakDuration(_ seconds: Int) {
        let clamped = min(1200, max(60, seconds))
        breakDurationSec = clamped
        if !isTimerRunning && isOnBreak {
            remainingSec = clamped
        }
        persist()
    }

    func setAutoContinuePulse(_ on: Bool) {
        autoContinuePulse = on
        persist()
    }

    func setSoundEnabled(_ on: Bool) {
        soundEnabled = on
        persist()
    }

    func setHapticEnabled(_ on: Bool) {
        hapticEnabled = on
        persist()
    }

    func startTimer() {
        hasStartedPulse = true
        if remainingSec <= 0 {
            remainingSec = isOnBreak ? breakDurationSec : focusDurationSec
        }
        timerEndDate = Date().addingTimeInterval(TimeInterval(remainingSec))
        isTimerRunning = true
        persist()
    }

    func pauseTimer() {
        guard isTimerRunning else { return }
        if let end = timerEndDate {
            remainingSec = max(0, Int(ceil(end.timeIntervalSinceNow)))
        }
        isTimerRunning = false
        timerEndDate = nil
        persist()
    }

    func tickIfNeeded() {
        guard isTimerRunning, let end = timerEndDate else { return }
        let left = max(0, Int(ceil(end.timeIntervalSinceNow)))
        remainingSec = left
        if left == 0 {
            finishCycle()
        }
    }

    func finishCycle() {
        isTimerRunning = false
        timerEndDate = nil
        if isOnBreak {
            isOnBreak = false
            remainingSec = focusDurationSec
        } else {
            completedSessions += 1
            sessionDays.append(DayStamp.string())
            isOnBreak = true
            remainingSec = breakDurationSec
            if lastInterruptionTime != nil || !interruptions.isEmpty {
                pendingResumePrompt = true
            }
        }
        BoardFeedback.pulseEnded(sound: soundEnabled, haptic: hapticEnabled)
        persist()
        if autoContinuePulse {
            startTimer()
        }
    }

    func appendResumeNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolved = trimmed.isEmpty ? "Resumed after interruption" : trimmed
        let entry = InterruptionLog(
            id: UUID(),
            at: Date(),
            note: resolved,
            relatedTaskID: focusedPinID
        )
        interruptions.insert(entry, at: 0)
        lastInterruptionTime = entry.at
        pendingResumePrompt = false
        persist()
    }

    func dismissResumePrompt() {
        pendingResumePrompt = false
    }

    // MARK: - Reset

    func resetAllData() {
        applyReset(posting: true)
    }

    private func handleExternalReset() {
        if applyingExternalReset { return }
        applyReset(posting: false)
    }

    private func applyReset(posting: Bool) {
        applyingExternalReset = true
        tasks = []
        habits = []
        interruptions = []
        completedTaskCount = 0
        focusDurationSec = 1500
        breakDurationSec = 300
        completedSessions = 0
        sessionDays = []
        lastInterruptionTime = nil
        isTimerRunning = false
        isOnBreak = false
        timerEndDate = nil
        remainingSec = 1500
        hasStartedPulse = false
        pendingResumePrompt = false
        focusedPinID = nil
        autoContinuePulse = false
        soundEnabled = true
        hapticEnabled = true
        Self.allKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        persist()
        HabitReminders.refresh(habits)
        if posting {
            NotificationCenter.default.post(name: Notification.Name("dataReset"), object: nil)
        }
        applyingExternalReset = false
    }

    // MARK: - Persistence

    private func reconcileTimerOnLaunch() {
        if isTimerRunning, let end = timerEndDate {
            let left = Int(ceil(end.timeIntervalSinceNow))
            if left <= 0 {
                finishCycle()
            } else {
                remainingSec = left
            }
        } else if remainingSec <= 0 {
            remainingSec = isOnBreak ? breakDurationSec : focusDurationSec
        }
    }

    private func load() {
        tasks = decode([WorkPin].self, key: Key.tasks, fallback: [])
        habits = decode([HabitPin].self, key: Key.habits, fallback: [])
        interruptions = decode([InterruptionLog].self, key: Key.interruptions, fallback: [])
        completedTaskCount = decode(Int.self, key: Key.completedTaskCount, fallback: 0)
        focusDurationSec = decode(Int.self, key: Key.focusDurationSec, fallback: 1500)
        breakDurationSec = decode(Int.self, key: Key.breakDurationSec, fallback: 300)
        completedSessions = decode(Int.self, key: Key.completedSessions, fallback: 0)
        sessionDays = decode([String].self, key: Key.sessionDays, fallback: [])
        if let interval = decodeOptional(TimeInterval.self, key: Key.lastInterruptionTime) {
            lastInterruptionTime = Date(timeIntervalSince1970: interval)
        }
        isTimerRunning = decode(Bool.self, key: Key.isTimerRunning, fallback: false)
        isOnBreak = decode(Bool.self, key: Key.isOnBreak, fallback: false)
        if let interval = decodeOptional(TimeInterval.self, key: Key.timerEndDate) {
            timerEndDate = Date(timeIntervalSince1970: interval)
        }
        remainingSec = decode(Int.self, key: Key.remainingSec, fallback: 1500)
        hasStartedPulse = decode(Bool.self, key: Key.hasStartedPulse, fallback: false)
        if let raw = decodeOptional(UUID.self, key: Key.focusedPinID) {
            focusedPinID = raw
        }
        autoContinuePulse = decode(Bool.self, key: Key.autoContinuePulse, fallback: false)
        soundEnabled = decode(Bool.self, key: Key.soundEnabled, fallback: true)
        hapticEnabled = decode(Bool.self, key: Key.hapticEnabled, fallback: true)
    }

    private func persist() {
        encode(tasks, key: Key.tasks)
        encode(habits, key: Key.habits)
        encode(interruptions, key: Key.interruptions)
        encode(completedTaskCount, key: Key.completedTaskCount)
        encode(focusDurationSec, key: Key.focusDurationSec)
        encode(breakDurationSec, key: Key.breakDurationSec)
        encode(completedSessions, key: Key.completedSessions)
        encode(sessionDays, key: Key.sessionDays)
        if let lastInterruptionTime {
            encode(lastInterruptionTime.timeIntervalSince1970, key: Key.lastInterruptionTime)
        } else {
            UserDefaults.standard.removeObject(forKey: Key.lastInterruptionTime)
        }
        encode(isTimerRunning, key: Key.isTimerRunning)
        encode(isOnBreak, key: Key.isOnBreak)
        if let timerEndDate {
            encode(timerEndDate.timeIntervalSince1970, key: Key.timerEndDate)
        } else {
            UserDefaults.standard.removeObject(forKey: Key.timerEndDate)
        }
        encode(remainingSec, key: Key.remainingSec)
        encode(hasStartedPulse, key: Key.hasStartedPulse)
        if let focusedPinID {
            encode(focusedPinID, key: Key.focusedPinID)
        } else {
            UserDefaults.standard.removeObject(forKey: Key.focusedPinID)
        }
        encode(autoContinuePulse, key: Key.autoContinuePulse)
        encode(soundEnabled, key: Key.soundEnabled)
        encode(hapticEnabled, key: Key.hapticEnabled)
    }

    private func encode<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key) else { return fallback }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            return fallback
        }
    }

    private func decodeOptional<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
