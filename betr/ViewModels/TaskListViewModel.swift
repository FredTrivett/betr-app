import Foundation

@MainActor
class TaskListViewModel: ObservableObject {
    private let cloudKitService: CloudServiceProtocol?
    private let localStorage: TaskStorageProtocol
    @Published var tasks: [Task] = []
    
    init(cloudKitService: CloudServiceProtocol? = CloudKitService(localStorage: TaskStorage()), localStorage: TaskStorageProtocol = TaskStorage()) {
        self.cloudKitService = cloudKitService
        self.localStorage = localStorage
        loadTasks()
    }
    
    private func loadTasks() {
        cloudKitService?.fetchTasks { [weak self] result in
            switch result {
            case .success(let fetchedTasks):
                self?.tasks = fetchedTasks
            case .failure(let error):
                print("Failed to load tasks: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveTasks() {
        if let cloudKitService = cloudKitService {
            for task in tasks {
                cloudKitService.saveTask(task) { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        print("Failed to save task: \(error.localizedDescription)")
                        // Fallback to local storage on failure
                        try? self.localStorage.saveTasks(self.tasks)
                    }
                }
            }
        } else {
            // just use local storage for previews
            try? localStorage.saveTasks(tasks)
        }
    }
    
    func toggleTaskCompletion(_ task: Task, for date: Date = Date()) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let currentlyCompleted = updatedTask.isCompletedForDate(date)
            updatedTask.updateCompletion(!currentlyCompleted, for: date)
            tasks[index] = updatedTask
            cloudKitService?.saveTask(updatedTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to save task: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func deleteTask(_ task: Task, for date: Date? = nil) {
        if let date = date, task.isRecurring {
            tasks.removeAll { $0.originalTaskId == task.id && Calendar.current.isDate($0.creationDate, inSameDayAs: date) }
        } else {
            tasks.removeAll { $0.id == task.id }
            cloudKitService?.deleteTask(task) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to delete task: \(error.localizedDescription)")
                }
            }
        }
        saveTasks()
    }
    
    func addTask(_ task: Task) {
        cloudKitService?.saveTask(task) { [weak self] result in
            switch result {
            case .success(let savedTask):
                if task.isRecurring {
                    var recurringTask = task
                    recurringTask.id = UUID()
                    recurringTask.originalTaskId = savedTask.id
                    self?.tasks.append(recurringTask)
                } else {
                    self?.tasks.append(task)
                }
            case .failure(let error):
                print("Failed to save task: \(error.localizedDescription)")
            }
        }
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
                    lastModifiedDate: date ?? Date(),
                    originalTaskId: historicalTask.originalTaskId,
                    selectedDays: updatedTask.selectedDays,
                    effectiveDate: preserveDate
                )
                
                if let index = tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    tasks[index] = hybridTask
                }
            }
        } else {
            cloudKitService?.saveTask(updatedTask) { result in
                switch result {
                case .success(let savedTask):
                    if let index = self.tasks.firstIndex(where: { $0.id == savedTask.id }) {
                        self.tasks[index] = savedTask
                    }
                case .failure(let error):
                    print("Failed to update task: \(error.localizedDescription)")
                }
            }
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
            updatedTask.excludedDates.append(normalizedDate)
            tasks[index] = updatedTask
            cloudKitService?.saveTask(updatedTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to exclude task: \(error.localizedDescription)")
                }
            }
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
            updatedTask.excludedDates.append(normalizedDate)
            tasks[index] = updatedTask
            cloudKitService?.saveTask(updatedTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to ignore task: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func unignoreTaskForDay(_ task: Task, on date: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = tasks[index]
            let normalizedDate = Calendar.current.startOfDay(for: date)
            updatedTask.excludedDates.removeAll(where: { Calendar.current.isDate($0, inSameDayAs: normalizedDate) })
            tasks[index] = updatedTask
            cloudKitService?.saveTask(updatedTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to unignore task: \(error.localizedDescription)")
                }
            }
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
            // Recurring task handling
            let newTask = Task(
                id: UUID(),
                title: task.title,
                description: task.description,
                isRecurring: false,
                completedDates: [],
                excludedDates: [],
                creationDate: tomorrow,
                lastModifiedDate: Date(),
                originalTaskId: task.id,
                selectedDays: [],
                effectiveDate: tomorrow
            )
            
            // Exclude the recurring task from today
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = tasks[index]
                updatedTask.excludedDates.append(calendar.startOfDay(for: currentDate))
                tasks[index] = updatedTask
                cloudKitService?.saveTask(updatedTask) { result in
                    switch result {
                    case .success:
                        break
                    case .failure(let error):
                        print("Failed to exclude recurring task: \(error.localizedDescription)")
                    }
                }
            }
            
            tasks.append(newTask)
            cloudKitService?.saveTask(newTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to save new recurring task: \(error.localizedDescription)")
                }
            }
        } else {
            // For non-recurring (one-time) tasks
            let newTask = Task(
                id: UUID(),
                title: task.title,
                description: task.description,
                isRecurring: false,
                completedDates: [],
                excludedDates: [],
                creationDate: tomorrow,
                lastModifiedDate: Date(),
                originalTaskId: nil,
                selectedDays: [],
                effectiveDate: tomorrow
            )
            
            // Remove the task from today
            tasks.removeAll { $0.id == task.id }
            cloudKitService?.deleteTask(task) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to delete old task: \(error.localizedDescription)")
                }
            }
            
            // Add the new task for tomorrow
            tasks.append(newTask)
            cloudKitService?.saveTask(newTask) { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print("Failed to save moved task: \(error.localizedDescription)")
                }
            }
        }
        
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