import Foundation

struct Task: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var description: String
    var isRecurring: Bool
    var completedDates: Set<Date>
    var excludedDates: Set<Date>
    var creationDate: Date
    var lastModifiedDate: Date?
    var originalTaskId: UUID?  // To track which recurring task this was created from
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isRecurring: Bool = false,
        completedDates: Set<Date> = [],
        excludedDates: Set<Date> = [],
        creationDate: Date = Date(),
        lastModifiedDate: Date? = nil,
        originalTaskId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isRecurring = isRecurring
        self.completedDates = completedDates
        self.excludedDates = excludedDates
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.originalTaskId = originalTaskId
    }
    
    func isCompletedForDate(_ date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
    }
    
    func isAvailableForDate(_ date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        let normalizedCreationDate = Calendar.current.startOfDay(for: creationDate)
        let isExcluded = excludedDates.contains { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        
        if isRecurring {
            // For recurring tasks, show on or after creation date
            let isAfterCreation = Calendar.current.compare(normalizedDate, to: normalizedCreationDate, toGranularity: .day) != .orderedAscending
            return isAfterCreation && !isExcluded
        } else {
            // Non-recurring tasks only show on their creation date
            return Calendar.current.isDate(normalizedCreationDate, inSameDayAs: normalizedDate) && !isExcluded
        }
    }
    
    mutating func updateCompletion(_ completed: Bool, for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if completed {
            completedDates.insert(normalizedDate)
        } else {
            completedDates = completedDates.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
    
    // Get completion count for a specific date
    func getCompletionCount(for date: Date) -> (total: Int, completed: Int) {
        if !isAvailableForDate(date) {
            return (0, 0)
        }
        return (1, isCompletedForDate(date) ? 1 : 0)
    }
}

// Add Weekday enum
enum Weekday: Int, Codable, Hashable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var singleLetter: String {
        switch self {
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        case .sunday: return "S"
        }
    }
}