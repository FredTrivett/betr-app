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
        if let date = date, task.isRecurring {
            tasks.removeAll { $0.originalTaskId == task.id && Calendar.current.isDate($0.creationDate, inSameDayAs: date) }
        } else {
            tasks.removeAll { $0.id == task.id }
        }
        saveTasks()
    }
    
    func addTask(_ task: Task) {
        if task.isRecurring {
            var recurringTask = task
            recurringTask.id = UUID()
            recurringTask.originalTaskId = task.id
            tasks.append(recurringTask)
        } else {
            tasks.append(task)
        }
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
    
    func updateTask(_ updatedTask: Task, preserveHistoryBefore date: Date? = nil) {
        if let preserveDate = date, updatedTask.isRecurring {
            if let historicalTask = tasks.first(where: { $0.id == updatedTask.id }) {
                let hybridTask = Task(
                    id: updatedTask.id,
                    title: updatedTask.title,
                    description: updatedTask.description,
                    isRecurring: true,
                    completedDates: historicalTask.completedDates,
                    excludedDates: historicalTask.excludedDates,
                    creationDate: historicalTask.creationDate,
                    lastModifiedDate: date,
                    originalTaskId: historicalTask.originalTaskId,
                    selectedDays: updatedTask.selectedDays,
                    effectiveDate: preserveDate
                )
                
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    tasks[index] = hybridTask
                }
            }
        } else {
            if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                tasks[index] = updatedTask
            }
        }
        
        saveTasks()
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
    
    var recurringTasks: [Task] {
        tasks.filter { $0.isRecurring }
    }
    
    func moveTaskToNextDay(_ task: Task, from currentDate: Date) {
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: currentDate) ?? Date())
        
        if task.isRecurring {
            // 1. Create a new one-time task for tomorrow
            let newTask = Task(
                id: UUID(),
                title: task.title,
                description: task.description,
                isRecurring: false,
                completedDates: Set<Date>(),
                excludedDates: Set<Date>(),
                creationDate: tomorrow,
                lastModifiedDate: Date(),
                originalTaskId: task.id,
                selectedDays: Set<Weekday>(),
                effectiveDate: tomorrow
            )
            
            // 2. Exclude the recurring task from today
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = tasks[index]
                updatedTask.excludedDates.insert(calendar.startOfDay(for: currentDate))
                tasks[index] = updatedTask
            }
            
            // 3. Add the new task after updating the recurring task
            tasks.append(newTask)
            
            print("DEBUG: Created new task for \(tomorrow)")
        } else {
            // Handle non-recurring tasks
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].effectiveDate = tomorrow
                tasks[index].lastModifiedDate = Date()
            }
        }
        
        // Save all changes at once
        saveTasks()
        objectWillChange.send()
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