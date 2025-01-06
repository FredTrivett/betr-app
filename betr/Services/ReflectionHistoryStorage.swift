import Foundation

/// Protocol defining reflection history storage operations
protocol ReflectionHistoryStorageProtocol {
    /// Saves a daily reflection to storage
    /// - Parameter reflection: The reflection to save
    /// - Throws: Error if save fails
    func saveReflection(_ reflection: DailyReflection) throws
    
    /// Loads all stored daily reflections
    /// - Returns: Array of stored reflections
    /// - Throws: Error if load fails
    func loadReflections() throws -> [DailyReflection]
}

/// Service for persisting daily reflection history using UserDefaults
struct ReflectionHistoryStorage: ReflectionHistoryStorageProtocol {
    /// UserDefaults instance for storing reflection history
    private let defaults: UserDefaults
    
    /// Key for storing reflection history in UserDefaults
    private let reflectionsKey = "com.FredericTRIVETT.betr.reflectionHistory"
    
    /// Creates a new ReflectionHistoryStorage instance
    /// - Parameter defaults: UserDefaults instance to use (defaults to standard)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func saveReflection(_ reflection: DailyReflection) throws {
        var reflections = try loadReflections()
        
        // Remove any existing reflection for the same day
        reflections.removeAll { existingReflection in
            Calendar.current.isDate(existingReflection.date, inSameDayAs: reflection.date)
        }
        
        reflections.append(reflection)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(reflections)
            defaults.set(data, forKey: reflectionsKey)
        } catch {
            throw ReflectionHistoryStorageError.saveError
        }
    }
    
    func loadReflections() throws -> [DailyReflection] {
        guard let data = defaults.data(forKey: reflectionsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([DailyReflection].self, from: data)
        } catch {
            throw ReflectionHistoryStorageError.loadError
        }
    }
}

/// Errors that can occur during reflection history storage operations
enum ReflectionHistoryStorageError: LocalizedError {
    case saveError
    case loadError
    
    var errorDescription: String? {
        switch self {
        case .saveError:
            return "Failed to save reflection history"
        case .loadError:
            return "Failed to load reflection history"
        }
    }
} 