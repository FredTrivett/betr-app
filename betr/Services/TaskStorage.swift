import Foundation

/// Protocol defining task storage operations
protocol TaskStorageProtocol {
    /// Saves tasks to persistent storage
    /// - Parameter tasks: Array of tasks to save
    /// - Throws: TaskStorageError if save fails
    func saveTasks(_ tasks: [Task]) throws
    
    /// Loads tasks from persistent storage
    /// - Returns: Array of stored tasks
    /// - Throws: TaskStorageError if load fails
    func loadTasks() throws -> [Task]
}

/// Service for persisting tasks using UserDefaults
struct TaskStorage: TaskStorageProtocol {
    /// UserDefaults instance for storing tasks
    private let defaults: UserDefaults
    
    /// Key for storing tasks in UserDefaults
    private let tasksKey = "com.FredericTRIVETT.betr.tasks"
    
    /// Creates a new TaskStorage instance
    /// - Parameter defaults: UserDefaults instance to use (defaults to standard)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func saveTasks(_ tasks: [Task]) throws {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(tasks)
            defaults.set(data, forKey: tasksKey)
        } catch {
            throw TaskStorageError.saveError
        }
    }
    
    func loadTasks() throws -> [Task] {
        guard let data = defaults.data(forKey: tasksKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Task].self, from: data)
        } catch {
            throw TaskStorageError.loadError
        }
    }
}

/// Errors that can occur during task storage operations
enum TaskStorageError: LocalizedError {
    case saveError
    case loadError
    
    var errorDescription: String? {
        switch self {
        case .saveError:
            return "Failed to save tasks"
        case .loadError:
            return "Failed to load tasks"
        }
    }
} 