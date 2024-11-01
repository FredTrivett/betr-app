import Foundation

protocol ReflectionHistoryStorageProtocol {
    func saveReflection(_ reflection: DailyReflection) throws
    func loadReflections() throws -> [DailyReflection]
}

struct ReflectionHistoryStorage: ReflectionHistoryStorageProtocol {
    private let defaults = UserDefaults.standard
    private let reflectionsKey = "com.FredericTRIVETT.betr.reflectionHistory"
    
    func saveReflection(_ reflection: DailyReflection) throws {
        var reflections = try loadReflections()
        
        // Remove any existing reflection for the same day
        reflections.removeAll { existingReflection in
            Calendar.current.isDate(existingReflection.date, inSameDayAs: reflection.date)
        }
        
        // Add the new reflection
        reflections.append(reflection)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(reflections)
        defaults.set(data, forKey: reflectionsKey)
    }
    
    func loadReflections() throws -> [DailyReflection] {
        guard let data = defaults.data(forKey: reflectionsKey) else {
            return []
        }
        let decoder = JSONDecoder()
        return try decoder.decode([DailyReflection].self, from: data)
    }
} 