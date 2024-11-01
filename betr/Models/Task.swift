import Foundation

struct Task: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var isCompleted: Bool
    var isRecurring: Bool
    var lastCompletedDate: Date?
    var creationDate: Date
    var deletedDate: Date?
    var recurringDays: Set<Weekday>?
    var completionDates: [Date] = []
    
    init(id: UUID = UUID(), 
         title: String, 
         description: String = "",
         isCompleted: Bool = false, 
         isRecurring: Bool = false,
         lastCompletedDate: Date? = nil,
         creationDate: Date = Date(),
         completionDates: [Date] = [],
         deletedDate: Date? = nil,
         recurringDays: Set<Weekday>? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.isRecurring = isRecurring
        self.lastCompletedDate = lastCompletedDate
        self.creationDate = creationDate
        self.completionDates = completionDates
        self.deletedDate = deletedDate
        self.recurringDays = recurringDays
    }
    
    // Check if task is completed for a specific date
    func isCompletedForDate(_ date: Date) -> Bool {
        if isRecurring {
            return completionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
        } else {
            guard let lastCompleted = lastCompletedDate else {
                return false
            }
            return Calendar.current.isDate(lastCompleted, inSameDayAs: date) && isCompleted
        }
    }
    
    // Check if task is available for a specific date
    func isAvailableForDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Check if the date is after deletion
        if let deletedDate = deletedDate,
           calendar.compare(date, to: deletedDate, toGranularity: .day) != .orderedAscending {
            return false
        }
        
        if isRecurring {
            // Check if the date is after creation date
            guard calendar.compare(date, to: creationDate, toGranularity: .day) != .orderedAscending else {
                return false
            }
            
            // If recurring days are specified, check if the date matches
            if let recurringDays = recurringDays {
                let weekday = Weekday(rawValue: calendar.component(.weekday, from: date))!
                return recurringDays.contains(weekday)
            }
            
            // If no specific days are set, task recurs daily
            return true
        }
        
        // For non-recurring tasks, they should only appear on their creation date
        return calendar.isDate(creationDate, inSameDayAs: date)
    }
    
    // Update completion status for a specific date
    mutating func updateCompletion(_ isCompleted: Bool, for date: Date) {
        if isRecurring {
            if isCompleted {
                // Add the date to completionDates if not already present
                if !self.isCompletedForDate(date) {
                    completionDates.append(date)
                }
            } else {
                // Remove the date from completionDates
                completionDates.removeAll { Calendar.current.isDate($0, inSameDayAs: date) }
            }
        } else {
            self.isCompleted = isCompleted
            self.lastCompletedDate = isCompleted ? date : nil
        }
    }
}

// Extension to add task management functionality
extension Task {
    var shouldResetCompletion: Bool {
        // Recurring tasks don't need resetting as they use completionDates
        if isRecurring {
            return false
        }
        guard let lastCompleted = lastCompletedDate else {
            return false
        }
        return !Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
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
}