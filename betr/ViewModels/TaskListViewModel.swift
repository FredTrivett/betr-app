import Foundation

@MainActor
class TaskListViewModel: ObservableObject {
    private let storage: TaskStorageProtocol
    @Published var tasks: [Task] = []
    
    init(storage: TaskStorageProtocol = TaskStorage()) {
        self.storage = storage
        loadTasks()
    }
    
    private func loadTasks() {
        do {
            tasks = try storage.loadTasks()
        } catch {
            print("Failed to load tasks: \(error.localizedDescription)")
        }
    }
    
    private func saveTasks() {
        do {
            try storage.saveTasks(tasks)
        } catch {
            print("Failed to save tasks: \(error.localizedDescription)")
        }
    }
    
    func toggleTaskCompletion(_ task: Task, for date: Date = Date()) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let currentlyCompleted = updatedTask.isCompletedForDate(date)
            updatedTask.updateCompletion(!currentlyCompleted, for: date)
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func deleteTask(_ task: Task, for date: Date? = nil) {
        if task.isRecurring && date != nil {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = tasks[index]
                let normalizedDate = Calendar.current.startOfDay(for: date!)
                updatedTask.excludedDates.insert(normalizedDate)
                tasks[index] = updatedTask
                saveTasks()
            }
        } else {
            tasks.removeAll { $0.id == task.id }
            saveTasks()
        }
    }
    
    func addTask(_ task: Task) {
        var newTask = task
        if task.isRecurring {
            newTask.creationDate = Calendar.current.startOfDay(for: Date())
            newTask.originalTaskId = task.id
        }
        tasks.append(newTask)
        saveTasks()
    }
    
    // Get completion statistics for a specific date
    func getCompletionStats(for date: Date) -> (total: Int, completed: Int) {
        let stats = tasks.map { $0.getCompletionCount(for: date) }
        let totalTasks = stats.reduce(0) { $0 + $1.total }
        let completedTasks = stats.reduce(0) { $0 + $1.completed }
        return (totalTasks, completedTasks)
    }
    
    // Get completion percentage for a date
    func getCompletionPercentage(for date: Date) -> Double {
        let stats = getCompletionStats(for: date)
        guard stats.total > 0 else { return 0 }
        return Double(stats.completed) / Double(stats.total) * 100
    }
    
    // Compare progress between two dates
    func compareProgress(current: Date = Date(), previous: Date) -> ProgressComparison {
        let currentStats = getCompletionStats(for: current)
        let previousStats = getCompletionStats(for: previous)
        
        let currentPercentage = getCompletionPercentage(for: current)
        let previousPercentage = getCompletionPercentage(for: previous)
        
        return ProgressComparison(
            currentDate: current,
            previousDate: previous,
            currentStats: currentStats,
            previousStats: previousStats,
            percentageChange: currentPercentage - previousPercentage
        )
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            if task.isRecurring {
                // For recurring tasks, set lastModifiedDate to today
                updatedTask.lastModifiedDate = Calendar.current.startOfDay(for: Date())
                
                // Get the original task
                let originalTask = tasks[index]
                
                // Preserve completion dates for past dates
                let today = Calendar.current.startOfDay(for: Date())
                updatedTask.completedDates = originalTask.completedDates.filter { date in
                    Calendar.current.compare(date, to: today, toGranularity: .day) == .orderedAscending
                }
            }
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func completedTasksCount(for date: Date) -> Int {
        tasks.filter { task in
            task.isAvailableForDate(date) && task.isCompletedForDate(date)
        }.count
    }
    
    func availableTasksCount(for date: Date) -> Int {
        tasks.filter { task in
            task.isAvailableForDate(date)
        }.count
    }
    
    func excludeRecurringTask(_ task: Task, for date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let normalizedDate = Calendar.current.startOfDay(for: date)
            updatedTask.excludedDates.insert(normalizedDate)
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func getReflectionForDate(_ date: Date) -> DailyReflection? {
        // This should connect to your reflection storage system
        let storage = ReflectionHistoryStorage()
        let reflections = try? storage.loadReflections()
        return reflections?.first { reflection in
            Calendar.current.isDate(reflection.date, inSameDayAs: date)
        }
    }
    
    func ignoreTaskForDay(_ task: Task, on date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let normalizedDate = Calendar.current.startOfDay(for: date)
            updatedTask.excludedDates.insert(normalizedDate)
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func unignoreTaskForDay(_ task: Task, on date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let normalizedDate = Calendar.current.startOfDay(for: date)
            updatedTask.excludedDates.remove(normalizedDate)
            tasks[index] = updatedTask
            saveTasks()
        }
    }
    
    func hasIgnoredTasksForDate(_ date: Date) -> Bool {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return tasks.contains { task in
            task.isRecurring && task.excludedDates.contains { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        }
    }
    
    func getIgnoredTasksForDate(_ date: Date) -> [Task] {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return tasks.filter { task in
            task.isRecurring && task.excludedDates.contains { Calendar.current.isDate($0, inSameDayAs: normalizedDate) }
        }
    }
}

// Add this struct to represent progress comparison
struct ProgressComparison {
    let currentDate: Date
    let previousDate: Date
    let currentStats: (total: Int, completed: Int)
    let previousStats: (total: Int, completed: Int)
    let percentageChange: Double
    
    var isImprovement: Bool {
        percentageChange > 0
    }
    
    var isPerfect: Bool {
        currentStats.total > 0 && currentStats.completed == currentStats.total &&
        previousStats.total > 0 && previousStats.completed == previousStats.total
    }
    
    var formattedPercentageChange: String {
        let prefix = percentageChange > 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", percentageChange))%"
    }
} 