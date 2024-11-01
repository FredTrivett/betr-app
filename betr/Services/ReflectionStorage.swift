import Foundation

protocol ReflectionStorageProtocol {
    func saveReflection(_ reflection: Reflection) throws
    func loadReflection(for date: Date) throws -> Reflection?
    func loadAllReflections() throws -> [Reflection]
}

struct ReflectionStorage: ReflectionStorageProtocol {
    private let defaults = UserDefaults.standard
    private let reflectionsKey = "com.FredericTRIVETT.betr.reflections"
    
    func saveReflection(_ reflection: Reflection) throws {
        var reflections = try loadAllReflections()
        
        // Remove existing reflection for the same day if exists
        reflections.removeAll { Calendar.current.isDate($0.date, inSameDayAs: reflection.date) }
        reflections.append(reflection)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(reflections)
        defaults.set(data, forKey: reflectionsKey)
    }
    
    func loadReflection(for date: Date) throws -> Reflection? {
        let reflections = try loadAllReflections()
        return reflections.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
    
    func loadAllReflections() throws -> [Reflection] {
        guard let data = defaults.data(forKey: reflectionsKey) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode([Reflection].self, from: data)
    }
} 