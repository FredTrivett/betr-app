import Foundation

/// Protocol defining reflection storage operations
protocol ReflectionStorageProtocol {
    /// Saves a reflection to storage
    /// - Parameter reflection: The reflection to save
    /// - Throws: Error if save fails
    func saveReflection(_ reflection: Reflection) throws
    
    /// Loads reflection for a specific date
    /// - Parameter date: The date to load reflection for
    /// - Returns: Optional reflection if found
    /// - Throws: Error if load fails
    func loadReflection(for date: Date) throws -> Reflection?
    
    /// Loads all stored reflections
    /// - Returns: Array of stored reflections
    /// - Throws: Error if load fails
    func loadAllReflections() throws -> [Reflection]
}

/// Service for persisting reflections using UserDefaults
struct ReflectionStorage: ReflectionStorageProtocol {
    /// UserDefaults instance for storing reflections
    private let defaults: UserDefaults
    
    /// Key for storing reflections in UserDefaults
    private let reflectionsKey = "com.FredericTRIVETT.betr.reflections"
    
    /// Creates a new ReflectionStorage instance
    /// - Parameter defaults: UserDefaults instance to use (defaults to standard)
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func saveReflection(_ reflection: Reflection) throws {
        var reflections = try loadAllReflections()
        
        // Remove existing reflection for the same day if exists
        reflections.removeAll { Calendar.current.isDate($0.date, inSameDayAs: reflection.date) }
        reflections.append(reflection)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(reflections)
            defaults.set(data, forKey: reflectionsKey)
        } catch {
            throw ReflectionStorageError.saveError
        }
    }
    
    func loadReflection(for date: Date) throws -> Reflection? {
        let reflections = try loadAllReflections()
        return reflections.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func loadAllReflections() throws -> [Reflection] {
        guard let data = defaults.data(forKey: reflectionsKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Reflection].self, from: data)
        } catch {
            throw ReflectionStorageError.loadError
        }
    }
}

/// Errors that can occur during reflection storage operations
enum ReflectionStorageError: LocalizedError {
    case saveError
    case loadError
    
    var errorDescription: String? {
        switch self {
        case .saveError:
            return "Failed to save reflection"
        case .loadError:
            return "Failed to load reflections"
        }
    }
} 