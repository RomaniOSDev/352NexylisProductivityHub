import Charts
import SwiftUI

struct BoardStatsView: View {
    @EnvironmentObject private var store: BoardStore

    private var hasAnyData: Bool {
        !store.tasks.isEmpty
            || !store.habits.isEmpty
            || !store.interruptions.isEmpty
            || store.completedSessions > 0
            || store.completedTaskCount > 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                kpiRow
                if hasAnyData {
                    completionsChart
                    categoryChart
                    pulseChart
                    streakChart
                    interruptionChart
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var kpiRow: some View {
        HStack(spacing: 8) {
            kpiTile(value: "\(store.completedTaskCount)", label: "done")
            kpiTile(value: "\(store.completedSessions)", label: "pulses")
            kpiTile(value: "\(store.habits.count)", label: "habits")
            kpiTile(value: "\(store.interruptions.count)", label: "breaks")
        }
    }

    private func kpiTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundColor(Color.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Palette.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Palette.surface.opacity(0.72))
    }

    private var emptyState: some View {
        StickyNote(tilt: -1.8) {
            VStack(spacing: 10) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("No Stats Yet")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Color.white)
                Text("Complete pins, run a pulse, or mark a habit to fill the board.")
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.top, 8)
    }

    private var completionsChart: some View {
        let points = completionPoints
        return chartCard(title: "PINS COMPLETED · 7 DAYS", tilt: -1.4, isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No completed pins this week.") {
            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.label),
                    y: .value("Done", point.count)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Palette.accent, Palette.primary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.14))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.75))
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private var categoryChart: some View {
        let points = categoryPoints
        return chartCard(title: "PINS BY CATEGORY", tilt: 1.2, isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No pins to split by category.") {
            Chart(points) { point in
                BarMark(
                    x: .value("Count", point.count),
                    y: .value("Category", point.label)
                )
                .foregroundStyle(Palette.accent)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.75))
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.85))
                        .font(.caption.weight(.semibold))
                }
            }
            .chartXScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: CGFloat(max(120, points.count * 36)))
        }
    }

    private var pulseChart: some View {
        let points = pulsePoints
        return chartCard(title: "FOCUS PULSES · 7 DAYS", tilt: 0, isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No focus sessions this week.") {
            Chart(points) { point in
                LineMark(
                    x: .value("Day", point.label),
                    y: .value("Sessions", point.count)
                )
                .foregroundStyle(Palette.accent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                PointMark(
                    x: .value("Day", point.label),
                    y: .value("Sessions", point.count)
                )
                .foregroundStyle(Palette.primary)
                .symbolSize(48)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.14))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.75))
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private var streakChart: some View {
        let points = streakPoints
        return chartCard(title: "HABIT STREAKS", tilt: -1.1, isEmpty: points.isEmpty || points.allSatisfy { $0.count == 0 }, emptyText: "Pin a habit to track streak length.") {
            Chart(points) { point in
                BarMark(
                    x: .value("Days", point.count),
                    y: .value("Habit", point.label)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Palette.primary, Palette.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.75))
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.85))
                        .font(.caption.weight(.semibold))
                }
            }
            .chartXScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: CGFloat(max(120, points.count * 40)))
        }
    }

    private var interruptionChart: some View {
        let points = interruptionPoints
        return chartCard(title: "INTERRUPTIONS · 7 DAYS", tilt: 1.6, isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No interruption notes this week.") {
            Chart(points) { point in
                AreaMark(
                    x: .value("Day", point.label),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(Palette.primary.opacity(0.28))
                .interpolationMethod(.catmullRom)
                BarMark(
                    x: .value("Day", point.label),
                    y: .value("Count", point.count)
                )
                .foregroundStyle(Palette.accent)
                .cornerRadius(3)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.white.opacity(0.14))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.75))
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private func chartCard<Content: View>(
        title: String,
        tilt: Double,
        isEmpty: Bool,
        emptyText: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let chart = content()
        return StickyNote(tilt: tilt) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                if isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 22)
                } else {
                    chart
                }
            }
        }
    }

    private var completionPoints: [StatPoint] {
        weekPoints { stamp in
            store.tasks.filter { pin in
                guard let completed = pin.completedAt else { return false }
                return DayStamp.string(from: completed) == stamp
            }.count
        }
    }

    private var pulsePoints: [StatPoint] {
        weekPoints { stamp in
            store.sessionDays.filter { $0 == stamp }.count
        }
    }

    private var interruptionPoints: [StatPoint] {
        weekPoints { stamp in
            store.interruptions.filter { DayStamp.string(from: $0.at) == stamp }.count
        }
    }

    private var categoryPoints: [StatPoint] {
        let completed = store.tasks.filter { $0.completedAt != nil }
        let source = completed.isEmpty ? store.tasks : completed
        return PinCategory.allCases.map { category in
            StatPoint(
                id: category.rawValue,
                label: category.rawValue,
                count: source.filter { $0.category == category }.count
            )
        }
    }

    private var streakPoints: [StatPoint] {
        store.habits.map { habit in
            let label = habit.title.count > 16 ? String(habit.title.prefix(14)) + "…" : habit.title
            return StatPoint(id: habit.id.uuidString, label: label, count: habit.streak)
        }
    }

    private func weekPoints(countFor: (String) -> Int) -> [StatPoint] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            let letter = symbols.indices.contains(weekday - 1) ? symbols[weekday - 1] : "?"
            let stamp = DayStamp.string(from: date)
            return StatPoint(id: stamp, label: letter, count: countFor(stamp))
        }
    }

    private func yMax(_ values: [Int]) -> Int {
        max(1, values.max() ?? 1)
    }
}

private struct StatPoint: Identifiable {
    var id: String
    var label: String
    var count: Int
}
