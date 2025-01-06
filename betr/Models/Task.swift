import Foundation

/// Represents a task that can be either one-time or recurring
struct Task: Identifiable, Hashable, Codable {
    /// Unique identifier for the task
    var id: UUID
    
    /// The title of the task
    var title: String
    
    /// Optional description providing more details about the task
    var description: String
    
    /// Indicates whether this task repeats
    var isRecurring: Bool
    
    /// Dates when this task was completed
    var completedDates: Set<Date>
    
    /// Dates when this recurring task was excluded
    var excludedDates: Set<Date>
    
    /// The date when this task was created
    var creationDate: Date
    
    /// The date when this task was last modified
    var lastModifiedDate: Date?
    
    /// Reference to the original task if this is a recurring instance
    var originalTaskId: UUID?
    
    /// The days this task repeats on (if it's recurring)
    var selectedDays: Set<Weekday> = []
    
    /// The effective date for this task
    var effectiveDate: Date?
    
    /// Creates a new task
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Task title
    ///   - description: Optional task description
    ///   - isRecurring: Whether task repeats
    ///   - completedDates: Set of completion dates
    ///   - excludedDates: Set of exclusion dates
    ///   - creationDate: When task was created
    ///   - lastModifiedDate: When task was last modified
    ///   - originalTaskId: Reference to original task
    ///   - selectedDays: The selected days for this task
    ///   - effectiveDate: The effective date for this task
    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        isRecurring: Bool = false,
        completedDates: Set<Date> = [],
        excludedDates: Set<Date> = [],
        creationDate: Date = Date(),
        lastModifiedDate: Date? = nil,
        originalTaskId: UUID? = nil,
        selectedDays: Set<Weekday> = [],
        effectiveDate: Date? = nil
    ) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            fatalError("Task title cannot be empty")
        }
        
        self.id = id
        self.title = title
        self.description = description
        self.isRecurring = isRecurring
        self.completedDates = completedDates
        self.excludedDates = excludedDates
        self.creationDate = creationDate
        self.lastModifiedDate = lastModifiedDate
        self.originalTaskId = originalTaskId
        self.selectedDays = selectedDays
        self.effectiveDate = effectiveDate
    }
    
    /// Checks if the task is completed for a specific date
    /// - Parameter date: The date to check
    /// - Returns: Whether the task is completed on that date
    func isCompletedForDate(_ date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return completedDates.contains { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
    }
    
    /// Checks if the task is available for a specific date
    /// - Parameter date: The date to check
    /// - Returns: Whether the task is available on that date
    func isAvailableForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        // Check if the date is excluded
        if excludedDates.contains(where: { calendar.isDate($0, inSameDayAs: normalizedDate) }) {
            return false
        }
        
        if isRecurring {
            // If we have an effective date and this date is before it,
            // use the historical task configuration
            if let effectiveDate = effectiveDate, 
               calendar.compare(date, to: effectiveDate, toGranularity: .day) == .orderedAscending {
                // For past dates, check if it was originally scheduled for this day
                return true
            }
            
            // For current and future dates, use the new configuration
            return selectedDays.contains(date.weekday)
        }
        
        return calendar.isDate(normalizedDate, inSameDayAs: creationDate)
    }
    
    /// Updates the completion status for a specific date
    /// - Parameters:
    ///   - completed: New completion status
    ///   - date: The date to update
    mutating func updateCompletion(_ completed: Bool, for date: Date) {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if completed {
            completedDates.insert(normalizedDate)
        } else {
            completedDates = completedDates.filter { !Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        }
        lastModifiedDate = Date()
    }
    
    /// Gets completion statistics for a specific date
    /// - Parameter date: The date to check
    /// - Returns: Tuple containing total and completed count
    func getCompletionCount(for date: Date) -> (total: Int, completed: Int) {
        if !isAvailableForDate(date) {
            return (0, 0)
        }
        return (1, isCompletedForDate(date) ? 1 : 0)
    }
}

// MARK: - CustomDebugStringConvertible
extension Task: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        Task(id: \(id),
             title: \(title),
             isRecurring: \(isRecurring),
             completed: \(completedDates.count) times)
        """
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
    
    static var sortedCases: [Weekday] {
        return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    }
}

// Add this extension to get weekday from Date
extension Date {
    var weekday: Weekday {
        let calendar = Calendar.current
        let weekdayNumber = calendar.component(.weekday, from: self)
        return Weekday(rawValue: weekdayNumber)!
    }
}