import Foundation

@Observable
class ReflectionViewModel {
    private let storage: ReflectionStorageProtocol
    var currentReflection: Reflection
    var reflections: [Reflection] = []
    var errorMessage: String?
    
    init(storage: ReflectionStorageProtocol = ReflectionStorage()) {
        self.storage = storage
        self.currentReflection = Reflection.empty
        loadTodayReflection()
        loadAllReflections()
    }
    
    private func loadTodayReflection() {
        do {
            if let reflection = try storage.loadReflection(for: Date()) {
                currentReflection = reflection
            }
        } catch {
            errorMessage = "Failed to load today's reflection"
            print("Failed to load reflection: \(error.localizedDescription)")
        }
    }
    
    private func loadAllReflections() {
        do {
            reflections = try storage.loadAllReflections()
            reflections.sort { $0.date > $1.date } // Most recent first
        } catch {
            errorMessage = "Failed to load reflections"
            print("Failed to load reflections: \(error.localizedDescription)")
        }
    }
    
    func saveReflection() {
        do {
            try storage.saveReflection(currentReflection)
            loadAllReflections() // Reload to update the list
        } catch {
            errorMessage = "Failed to save reflection"
            print("Failed to save reflection: \(error.localizedDescription)")
        }
    }
} 