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
            || store.lastShutdown != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                kpiRow
                radarInsightCard
                if hasAnyData {
                    kindChart
                    interruptionChart
                    completionsChart
                    pulseChart
                    streakChart
                } else {
                    emptyState
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var kpiRow: some View {
        HStack(spacing: 8) {
            kpiTile(value: "\(store.completedTaskCount)", label: "cleared")
            kpiTile(value: "\(store.completedSessions)", label: "focus")
            kpiTile(value: "\(store.interruptions.count)", label: "tags")
            kpiTile(value: store.isDaySealed ? "ON" : "OFF", label: "seal")
        }
    }

    private func kpiTile(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundColor(Palette.ink)
                .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Palette.accent)
                .shadow(color: Color.black.opacity(0.35), radius: 1, y: 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(DepthFill(cornerRadius: 14))
    }

    private var radarInsightCard: some View {
        StickyNote(compact: true) {
            VStack(alignment: .leading, spacing: 10) {
                Text("INTERRUPTION RADAR")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)

                Text("Suggested quiet window: \(store.quietWindow.label)")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.white)

                if let peak = store.peakInterruptHour {
                    Text(String(format: "Peak interference around %02d:00", peak))
                        .font(.footnote)
                        .foregroundColor(Palette.inkSoft)
                } else {
                    Text("Tag interruptions to map your noisiest hours.")
                        .font(.footnote)
                        .foregroundColor(Palette.inkSoft)
                }

                if store.topInterruptKinds.isEmpty {
                    Text("No tagged pulls yet.")
                        .font(.caption)
                        .foregroundColor(Palette.inkMuted)
                } else {
                    ForEach(store.topInterruptKinds.prefix(3), id: \.0) { kind, count in
                        HStack {
                            Image(systemName: kind.symbol)
                                .foregroundColor(Palette.accent)
                            Text(kind.label)
                                .foregroundColor(Color.white)
                            Spacer()
                            Text("\(count)")
                                .font(.system(.caption, design: .monospaced).weight(.bold))
                                .foregroundColor(Palette.accent)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        StickyNote {
            VStack(spacing: 10) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 34))
                    .foregroundColor(Palette.accent)
                Text("Radar is quiet")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundColor(Color.white)
                Text("Clear signals, run focus, tag interruptions, and seal a day to fill the radar.")
                    .font(.subheadline)
                    .foregroundColor(Palette.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(.top, 8)
    }

    private var kindChart: some View {
        let points = kindPoints
        return chartCard(title: "PULL REASONS", isEmpty: points.isEmpty, emptyText: "Tag an interruption to see reason mix.") {
            Chart(points) { point in
                BarMark(
                    x: .value("Count", point.count),
                    y: .value("Kind", point.label)
                )
                .foregroundStyle(Palette.accent)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkMuted)
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkSoft)
                        .font(.caption.weight(.semibold))
                }
            }
            .chartXScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: CGFloat(max(120, points.count * 36)))
        }
    }

    private var completionsChart: some View {
        let points = completionPoints
        return chartCard(title: "SIGNALS CLEARED · 7 DAYS", isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No cleared signals this week.") {
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
                                .foregroundColor(Palette.inkMuted)
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Palette.inkMuted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkMuted)
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private var pulseChart: some View {
        let points = pulsePoints
        return chartCard(title: "FOCUS CYCLES · 7 DAYS", isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No focus cycles this week.") {
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
                                .foregroundColor(Palette.inkMuted)
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Palette.inkMuted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkMuted)
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private var streakChart: some View {
        let points = streakPoints
        return chartCard(title: "CADENCE STREAKS", isEmpty: points.isEmpty || points.allSatisfy { $0.count == 0 }, emptyText: "Add a cadence rhythm to track streak length.") {
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
                        .foregroundStyle(Palette.inkMuted)
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkSoft)
                        .font(.caption.weight(.semibold))
                }
            }
            .chartXScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: CGFloat(max(120, points.count * 40)))
        }
    }

    private var interruptionChart: some View {
        let points = interruptionPoints
        return chartCard(title: "TAGS · 7 DAYS", isEmpty: points.allSatisfy { $0.count == 0 }, emptyText: "No interruption tags this week.") {
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
                                .foregroundColor(Palette.inkMuted)
                        } else if let doubleValue = value.as(Double.self) {
                            Text("\(Int(doubleValue.rounded()))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(Palette.inkMuted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Palette.inkMuted)
                        .font(.caption2.weight(.semibold))
                }
            }
            .chartYScale(domain: 0...yMax(points.map(\.count)))
            .frame(height: 168)
        }
    }

    private func chartCard<Content: View>(
        title: String,
        isEmpty: Bool,
        emptyText: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let chart = content()
        return StickyNote {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(Palette.accent)
                if isEmpty {
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundColor(Palette.inkSoft)
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

    private var kindPoints: [StatPoint] {
        store.topInterruptKinds.map { kind, count in
            StatPoint(id: kind.rawValue, label: kind.label, count: count)
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
