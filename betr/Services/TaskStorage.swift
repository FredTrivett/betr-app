import Foundation

protocol TaskStorageProtocol {
    func saveTasks(_ tasks: [Task]) throws
    func loadTasks() throws -> [Task]
}

struct TaskStorage: TaskStorageProtocol {
    private let defaults = UserDefaults.standard
    private let tasksKey = "com.FredericTRIVETT.betr.tasks"
    
    func saveTasks(_ tasks: [Task]) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(tasks)
        defaults.set(data, forKey: tasksKey)
    }
    
    func loadTasks() throws -> [Task] {
        guard let data = defaults.data(forKey: tasksKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Task].self, from: data)
    }
}

// Custom errors for task storage
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