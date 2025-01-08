import Foundation

/// Protocol defining task storage operations
protocol TaskStorageProtocol {
    func saveTasks(_ tasks: [Task]) throws
    func fetchTasks() throws -> [Task]
    func deleteTask(_ task: Task) throws
}

/// Service for persisting tasks using UserDefaults
struct TaskStorage: TaskStorageProtocol {
    private let defaults: UserDefaults
    private let tasksKey = "com.FredericTRIVETT.betr.tasks"
    
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
    
    func fetchTasks() throws -> [Task] {
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
    
    func deleteTask(_ task: Task) throws {
        var tasks = try fetchTasks()
        tasks.removeAll { $0.id == task.id }
        try saveTasks(tasks)
    }
}

/// Mock implementation for previews and testing
class MockTaskStorage: TaskStorageProtocol {
    private var tasks: [Task] = []
    
    func saveTasks(_ tasks: [Task]) throws {
        self.tasks.append(contentsOf: tasks)
    }
    
    func fetchTasks() throws -> [Task] {
        return tasks
    }
    
    func deleteTask(_ task: Task) throws {
        tasks.removeAll { $0.id == task.id }
    }
}

enum TaskStorageError: LocalizedError {
    case saveError
    case loadError
    
    var errorDescription: String? {
        switch self {
        case .saveError: return "Failed to save tasks"
        case .loadError: return "Failed to load tasks"
        }
    }
} 