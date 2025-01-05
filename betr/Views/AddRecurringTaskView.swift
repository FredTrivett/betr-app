import SwiftUI

struct AddRecurringTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let taskToEdit: Task?
    
    @State private var title: String
    @State private var description: String
    @State private var selectedDays: Set<Weekday>
    
    init(viewModel: TaskListViewModel, taskToEdit: Task? = nil) {
        self.viewModel = viewModel
        self.taskToEdit = taskToEdit
        
        _title = State(initialValue: taskToEdit?.title ?? "")
        _description = State(initialValue: taskToEdit?.description ?? "")
        _selectedDays = State(initialValue: Set(Weekday.allCases))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Repeat on")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(Weekday.allCases, id: \.self) { day in
                                DayToggle(
                                    day: day,
                                    isSelected: selectedDays.contains(day),
                                    onTap: {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(taskToEdit == nil ? "Add Recurring Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(taskToEdit == nil ? "Add" : "Save") {
                        let task = Task(
                            id: taskToEdit?.id ?? UUID(),
                            title: title,
                            description: description,
                            isRecurring: true,
                            creationDate: taskToEdit?.creationDate ?? Date()
                        )
                        
                        if taskToEdit != nil {
                            viewModel.updateTask(task)
                        } else {
                            viewModel.addTask(task)
                        }
                        dismiss()
                    }
                    .disabled(title.isEmpty || selectedDays.isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddRecurringTaskView(viewModel: TaskListViewModel())
} 