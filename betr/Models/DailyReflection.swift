import Foundation
import SwiftUI

struct DailyReflection: Identifiable, Codable {
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
        self.id = id
        self.date = date
        self.rating = rating
        self.tasksCompleted = tasksCompleted
        self.totalTasks = totalTasks
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
        case .same: return .blue
        case .worse: return .red
        }
    }
} 