import Foundation

struct EditTaskData: Identifiable {
    let id = UUID()
    let task: Task
    let isRecurring: Bool
} 