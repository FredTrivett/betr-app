import Foundation

class ReflectionHistoryViewModel: ObservableObject {
    private let storage: ReflectionHistoryStorageProtocol
    @Published var reflections: [DailyReflection] = []
    @Published var reflectionsByDate: [Date: [DailyReflection]] = [:]
    
    init(storage: ReflectionHistoryStorageProtocol = ReflectionHistoryStorage()) {
        self.storage = storage
        loadReflections()
    }
    
    private func loadReflections() {
        do {
            reflections = try storage.loadReflections()
            reflections.sort { $0.date > $1.date }
            groupReflectionsByDate()
        } catch {
            print("Failed to load reflections: \(error)")
        }
    }
    
    private func groupReflectionsByDate() {
        reflectionsByDate = Dictionary(grouping: reflections) { reflection in
            Calendar.current.startOfDay(for: reflection.date)
        }
    }
    
    func addReflection(_ rating: ReflectionRating, stats: (completed: Int, total: Int)) {
        let reflection = DailyReflection(
            rating: rating,
            tasksCompleted: stats.completed,
            totalTasks: stats.total
        )
        
        do {
            try storage.saveReflection(reflection)
            loadReflections()
        } catch {
            print("Failed to save reflection: \(error)")
        }
    }
    
    // Statistics
    var weeklyStats: (better: Int, same: Int, worse: Int) {
        calculateStats(for: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    }
    
    var monthlyStats: (better: Int, same: Int, worse: Int) {
        calculateStats(for: Calendar.current.date(byAdding: .month, value: -1, to: Date())!)
    }
    
    private func calculateStats(for startDate: Date) -> (better: Int, same: Int, worse: Int) {
        let recentReflections = reflections.filter { $0.date >= startDate }
        let better = recentReflections.filter { $0.rating == .better }.count
        let same = recentReflections.filter { $0.rating == .same }.count
        let worse = recentReflections.filter { $0.rating == .worse }.count
        return (better, same, worse)
    }
} 