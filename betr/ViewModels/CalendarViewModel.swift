import Foundation

@MainActor
class CalendarViewModel: ObservableObject {
    private let taskViewModel: TaskListViewModel
    private let calendar = Calendar.current
    @Published var selectedDate: Date = Date()
    @Published var currentMonth: Date = Date()
    @Published var streak: Int = 0
    
    init(taskViewModel: TaskListViewModel) {
        self.taskViewModel = taskViewModel
        calculateStreak()
    }
    
    var daysInMonth: [Date] {
        let interval = calendar.dateInterval(of: .month, for: currentMonth)!
        let days = calendar.generateDates(
            inside: interval,
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
        return days
    }
    
    var monthYearString: String {
        currentMonth.formatted(.dateTime.year().month(.wide))
    }
    
    func moveMonth(by value: Int) {
        if let newDate = calendar.date(
            byAdding: .month,
            value: value,
            to: currentMonth
        ) {
            currentMonth = newDate
        }
    }
    
    func isDateInCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    func getDayCompletion(_ date: Date) -> DayCompletionStatus {
        // Don't show completion status for future dates
        if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending {
            return .none
        }
        
        // Filter tasks that are available for this date
        let availableTasks = taskViewModel.tasks.filter { task in
            task.isAvailableForDate(date)
        }
        
        if availableTasks.isEmpty { return .none }
        
        let completedTasks = availableTasks.filter { task in
            task.isCompletedForDate(date)
        }
        
        if completedTasks.count == availableTasks.count {
            return .full
        } else if completedTasks.isEmpty {
            return .none
        } else {
            return .partial
        }
    }
    
    private func calculateStreak() {
        var currentStreak = 0
        var currentDate = Date()
        let calendar = Calendar.current
        
        while true {
            // Get the tasks for the current date
            let tasksForDate = taskViewModel.tasks.filter { task in
                task.isAvailableForDate(currentDate)
            }
            
            // Check if there are any completed tasks for this date
            let hasCompletedTasks = tasksForDate.contains { task in
                task.isCompletedForDate(currentDate)
            }
            
            if hasCompletedTasks {
                currentStreak += 1
                // Move to previous day
                if let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) {
                    currentDate = previousDay
                } else {
                    break
                }
            } else {
                // Break if we find a day with no completed tasks
                break
            }
        }
        
        streak = currentStreak
    }
    
    // Add this method to check and update streak when needed
    func checkAndUpdateStreak() {
        calculateStreak()
    }
}

// Calendar helper extension
extension Calendar {
    func generateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        
        enumerateDates(
            startingAfter: interval.start,
            matching: components,
            matchingPolicy: .nextTime
        ) { date, _, stop in
            if let date = date {
                if date <= interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        
        return dates
    }
} 