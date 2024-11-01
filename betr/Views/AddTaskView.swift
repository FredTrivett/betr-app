import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TaskListViewModel
    let selectedDate: Date
    var taskToEdit: Task? = nil
    
    @State private var title: String = ""
    @State private var description: String = ""
    
    init(viewModel: TaskListViewModel, selectedDate: Date, taskToEdit: Task? = nil) {
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self.taskToEdit = taskToEdit
        
        if let task = taskToEdit {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Task title", text: $title)
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Button(action: taskToEdit != nil ? updateTask : addTask) {
                    Text(taskToEdit != nil ? "Update Task" : "Add Task")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
            .navigationTitle(taskToEdit != nil ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addTask() {
        let task = Task(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            isRecurring: false,
            creationDate: selectedDate
        )
        viewModel.addTask(task)
        dismiss()
    }
    
    private func updateTask() {
        guard let existingTask = taskToEdit else { return }
        let updatedTask = Task(
            id: existingTask.id,
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            isRecurring: false,
            lastCompletedDate: existingTask.lastCompletedDate,
            creationDate: existingTask.creationDate,
            completionDates: existingTask.completionDates
        )
        viewModel.updateTask(updatedTask)
        dismiss()
    }
}

#Preview {
    AddTaskView(viewModel: TaskListViewModel(), selectedDate: Date())
} 