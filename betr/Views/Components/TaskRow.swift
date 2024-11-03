import SwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let selectedDate: Date
    let onConfetti: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggle()
                if task.isCompletedForDate(selectedDate) {
                    onConfetti()
                }
            }) {
                Image(systemName: task.isCompletedForDate(selectedDate) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompletedForDate(selectedDate) ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompletedForDate(selectedDate))
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if task.isRecurring {
                Image(systemName: "repeat")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    TaskRow(
        task: Task(title: "Sample Task", description: "Sample Description"),
        onToggle: {},
        selectedDate: Date(),
        onConfetti: {}
    )
    .padding()
} 
