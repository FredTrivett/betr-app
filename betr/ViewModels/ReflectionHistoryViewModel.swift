import Foundation

@MainActor
class ReflectionHistoryViewModel: ObservableObject {
    @Published var reflections: [DailyReflection] = []
    @Published private(set) var displayedReflections: [DailyReflection] = []
    @Published private(set) var todayReflection: DailyReflection?
    private let cloudKitService: CloudServiceProtocol
    private var currentPage = 0
    private let pageSize = 7
    
    init(cloudKitService: CloudServiceProtocol = CloudKitService()) {
        self.cloudKitService = cloudKitService
        loadReflections()
    }
    
    func getReflection(for date: Date) -> DailyReflection? {
        reflections.first { reflection in
            Calendar.current.isDate(reflection.date, inSameDayAs: date)
        }
    }
    
    func loadReflections() {
        cloudKitService.fetchReflections { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let reflections):
                    self?.reflections = reflections.sorted { $0.date > $1.date }
                    
                    // Set today's reflection
                    let today = Calendar.current.startOfDay(for: Date())
                    self?.todayReflection = reflections.first { 
                        Calendar.current.isDate($0.date, inSameDayAs: today)
                    }
                    
                    // Reset and reload displayed reflections
                    self?.displayedReflections = []
                    self?.currentPage = 0
                    self?.loadMoreReflections()
                    
                case .failure(let error):
                    print("Failed to load reflections: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addReflection(_ rating: ReflectionRating, stats: (completed: Int, total: Int), for date: Date) {
        let reflection = DailyReflection(
            date: date,
            rating: rating,
            tasksCompleted: stats.completed,
            totalTasks: stats.total
        )
        
        saveReflection(reflection)
    }
    
    private func saveReflection(_ reflection: DailyReflection) {
        cloudKitService.saveReflection(reflection) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.loadReflections()
                case .failure(let error):
                    print("Failed to save reflection: \(error.localizedDescription)")
                }
            }
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
    
    func getChartData(for timeFrame: TimeFrame) -> [(date: Date, value: Int, hasReflection: Bool, rating: ReflectionRating?)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = today
        let startDate: Date
        
        switch timeFrame {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -6, to: endDate)!
        case .month:
            startDate = calendar.date(byAdding: .day, value: -29, to: endDate)!
        }
        
        var result: [(date: Date, value: Int, hasReflection: Bool, rating: ReflectionRating?)] = []
        var currentDate = startDate
        var cumulativeValue = 0
        
        while currentDate <= endDate {
            let reflection = if calendar.isDate(currentDate, inSameDayAs: today) {
                todayReflection
            } else {
                getReflection(for: currentDate)
            }
            
            if let reflection = reflection {
                let dayValue = switch reflection.rating {
                case .better: 1
                case .same: 0
                case .worse: -1
                }
                cumulativeValue += dayValue
                result.append((
                    date: currentDate,
                    value: cumulativeValue,
                    hasReflection: true,
                    rating: reflection.rating
                ))
            } else {
                result.append((
                    date: currentDate,
                    value: cumulativeValue,
                    hasReflection: false,
                    rating: nil
                ))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return result
    }
    
    func loadMoreReflections() {
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, reflections.count)
        
        guard startIndex < reflections.count else { return }
        
        let newReflections = reflections[startIndex..<endIndex]
        displayedReflections.append(contentsOf: newReflections)
        currentPage += 1
    }
} 