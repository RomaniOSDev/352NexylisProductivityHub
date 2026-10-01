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

enum InterruptKind: String, Codable, CaseIterable, Identifiable {
    case chat
    case meeting
    case contextSwitch
    case noise
    case fatigue
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chat: return "Chat"
        case .meeting: return "Meeting"
        case .contextSwitch: return "Context switch"
        case .noise: return "Noise"
        case .fatigue: return "Fatigue"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .meeting: return "person.3.fill"
        case .contextSwitch: return "arrow.triangle.swap"
        case .noise: return "speaker.wave.2.fill"
        case .fatigue: return "battery.25"
        case .other: return "waveform.path"
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
    var kind: InterruptKind

    enum CodingKeys: String, CodingKey {
        case id, at, note, relatedTaskID, kind
    }

    init(id: UUID, at: Date, note: String, relatedTaskID: UUID?, kind: InterruptKind) {
        self.id = id
        self.at = at
        self.note = note
        self.relatedTaskID = relatedTaskID
        self.kind = kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        at = try container.decode(Date.self, forKey: .at)
        note = try container.decode(String.self, forKey: .note)
        relatedTaskID = try container.decodeIfPresent(UUID.self, forKey: .relatedTaskID)
        kind = try container.decodeIfPresent(InterruptKind.self, forKey: .kind) ?? .other
    }
}

struct ShutdownSeal: Codable, Equatable {
    var dayStamp: String
    var carriedPinIDs: [UUID]
    var residueNote: String
    var sealedAt: Date
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

struct QuietWindow: Equatable {
    var startHour: Int
    var endHour: Int

    var label: String {
        String(format: "%02d:00–%02d:00", startHour, endHour)
    }
}
