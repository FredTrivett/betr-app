import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let task: Task
    let isRecurring: Bool
    let selectedDate: Date
    @ObservedObject var viewModel: TaskListViewModel
    
    @State private var title: String
    @State private var description: String
    
    init(task: Task, isRecurring: Bool, selectedDate: Date, viewModel: TaskListViewModel) {
        self.task = task
        self.isRecurring = isRecurring
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                if isRecurring {
                    Section {
                        Text("This is a recurring task. Changes will only affect this instance.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if isRecurring {
                            // Create a one-time override
                            let override = Task(
                                title: title,
                                description: description,
                                isRecurring: false,
                                creationDate: selectedDate
                            )
                            viewModel.addTask(override)
                            viewModel.excludeRecurringTask(task, for: selectedDate)
                        } else {
                            // Update the existing task
                            var updatedTask = task
                            updatedTask.title = title
                            updatedTask.description = description
                            viewModel.updateTask(updatedTask)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    EditTaskView(
        task: Task(title: "Sample Task", description: "Sample Description"),
        isRecurring: false,
        selectedDate: Date(),
        viewModel: TaskListViewModel()
    )
} 