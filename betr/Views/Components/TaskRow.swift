import SwiftUI

struct TaskRow: View {
    let task: Task
    let onToggle: () -> Void
    let selectedDate: Date
    let onConfetti: () -> Void
    
    var body: some View {
        Button {
            onToggle()
            if task.isCompletedForDate(selectedDate) {
                onConfetti()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: task.isCompletedForDate(selectedDate) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompletedForDate(selectedDate) ? .green : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .strikethrough(task.isCompletedForDate(selectedDate))
                        .foregroundStyle(.primary)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 0)
                
                if task.isRecurring {
                    Image(systemName: "repeat")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
