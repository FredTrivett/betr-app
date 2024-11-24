import SwiftUI

/// Represents the completion status of tasks for a specific day
public enum DayCompletionStatus: Equatable {
    /// No tasks completed
    case none
    
    /// Some tasks completed
    case partial
    
    /// All tasks completed
    case full
    
    /// Description of the completion status
    var description: String {
        switch self {
        case .none: return "No tasks completed"
        case .partial: return "Some tasks completed"
        case .full: return "All tasks completed"
        }
    }
    
    /// Color representing the completion status
    var color: Color {
        switch self {
        case .none: return .gray
        case .partial: return .yellow
        case .full: return .green
        }
    }
} 