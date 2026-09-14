import Foundation

enum PinCategory: String, Codable, CaseIterable, Identifiable {
    case work = "Work"
    case client = "Client"
    case home = "Home"
    case admin = "Admin"

    var id: String { rawValue }
}

enum PinPriority: String, Codable, CaseIterable, Identifiable {
    case high
    case normal
    case low

    var id: String { rawValue }

    var label: String {
        switch self {
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }

    var sortRank: Int {
        switch self {
        case .high: return 0
        case .normal: return 1
        case .low: return 2
        }
    }
}

struct WorkPin: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var dueDate: Date
    var category: PinCategory
    var priority: PinPriority
    var completedAt: Date?
}

struct HabitPin: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var reminderTime: Date?
    var lastCompletedDay: String
    var streak: Int
    var skippedDay: String?
}

struct InterruptionLog: Identifiable, Codable, Equatable {
    var id: UUID
    var at: Date
    var note: String
    var relatedTaskID: UUID?
}

enum DayStamp {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date = Date()) -> String {
        formatter.string(from: date)
    }

    static func date(from value: String) -> Date? {
        formatter.date(from: value)
    }
}

enum CompleteOffer: Equatable {
    case none
    case interruption
    case habit(String)
    case both(String)
}

extension WorkPin {
    var isOverdue: Bool {
        completedAt == nil && dueDate < Date()
    }

    var isDueToday: Bool {
        completedAt == nil && Calendar.current.isDateInToday(dueDate) && dueDate >= Date()
    }
}

enum BoardNote {
    static let openPulse = Notification.Name("openPulse")
}
