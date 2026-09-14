import UserNotifications

enum HabitReminders {
    static func refresh(_ habits: [HabitPin]) {
        let center = UNUserNotificationCenter.current()
        if habits.allSatisfy({ $0.reminderTime == nil }) {
            clearPending(center)
            return
        }
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            schedule(habits, granted: granted)
        }
    }

    private static func clearPending(_ center: UNUserNotificationCenter) {
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("habit.") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func schedule(_ habits: [HabitPin], granted: Bool) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix("habit.") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
            guard granted else { return }
            let today = DayStamp.string()
            let calendar = Calendar.current
            for habit in habits {
                guard let time = habit.reminderTime else { continue }
                let hourMinute = calendar.dateComponents([.hour, .minute], from: time)
                let trigger: UNCalendarNotificationTrigger
                if habit.lastCompletedDay == today {
                    guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else { continue }
                    var comps = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                    comps.hour = hourMinute.hour
                    comps.minute = hourMinute.minute
                    trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                } else {
                    var comps = DateComponents()
                    comps.hour = hourMinute.hour
                    comps.minute = hourMinute.minute
                    trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
                }
                let content = UNMutableNotificationContent()
                content.title = "Streak pin"
                content.body = habit.title
                content.sound = .default
                let request = UNNotificationRequest(
                    identifier: "habit.\(habit.id.uuidString)",
                    content: content,
                    trigger: trigger
                )
                center.add(request)
            }
        }
    }
}
