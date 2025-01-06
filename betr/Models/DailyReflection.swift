import Foundation
import SwiftUI

struct DailyReflection: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let rating: ReflectionRating
    let tasksCompleted: Int
    let totalTasks: Int
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         rating: ReflectionRating,
         tasksCompleted: Int,
         totalTasks: Int) {
        guard tasksCompleted <= totalTasks else {
            fatalError("Completed tasks cannot exceed total tasks")
        }
        
        self.id = id
        self.date = date
        self.rating = rating
        self.tasksCompleted = tasksCompleted
        self.totalTasks = totalTasks
    }
    
    static func == (lhs: DailyReflection, rhs: DailyReflection) -> Bool {
        lhs.id == rhs.id
    }
    
    var completionPercentage: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(tasksCompleted) / Double(totalTasks) * 100
    }
}

enum ReflectionRating: String, Codable {
    case better
    case same
    case worse
    
    var message: String {
        switch self {
        case .better:
            return "Congratulations! Keep up the great work! 🎉"
        case .same:
            return "At least you didn't fall behind. Aim to be better tomorrow! 💪"
        case .worse:
            return "Remember your goals. Every day is a new opportunity to improve! 🎯"
        }
    }
    
    var color: Color {
        switch self {
        case .better: return .green
        case .same: return .orange
        case .worse: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .better: return "arrow.up.circle.fill"
        case .same: return "equal.circle.fill"
        case .worse: return "arrow.down.circle.fill"
        }
    }
} 