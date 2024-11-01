import SwiftUI
import ConfettiSwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let selectedDate: Date
    let onConfetti: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                Button(action: {
                    handleTaskToggle()
                }) {
                    Image(systemName: task.isCompletedForDate(selectedDate) ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(task.isCompletedForDate(selectedDate) ? .green : .gray)
                        .animation(.spring(duration: 0.2), value: task.isCompletedForDate(selectedDate))
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompletedForDate(selectedDate))
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if task.isRecurring {
                    Image(systemName: "repeat.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTaskToggle()
            }
            .padding(.vertical, 8)
        }
        .frame(height: task.description.isEmpty ? 44 : 65)
    }
    
    private func handleTaskToggle() {
        let wasCompleted = task.isCompletedForDate(selectedDate)
        if !wasCompleted {
            onConfetti()
            DispatchQueue.main.async {
                onToggle()
            }
        } else {
            onToggle()
        }
    }
} 
