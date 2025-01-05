import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let task: Task
    let isRecurring: Bool
    let selectedDate: Date
    
    @State private var title: String
    @State private var description: String
    @State private var makeRecurring: Bool = false
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    
    init(task: Task, isRecurring: Bool, selectedDate: Date, viewModel: TaskListViewModel) {
        self.task = task
        self.isRecurring = isRecurring
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                if !isRecurring {
                    Section {
                        Toggle("Make Recurring", isOn: $makeRecurring)
                        
                        if makeRecurring {
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
                        var updatedTask = task
                        updatedTask.title = title
                        updatedTask.description = description
                        
                        if makeRecurring {
                            // Create a new recurring task
                            let recurringTask = Task(
                                title: title,
                                description: description,
                                isRecurring: true,
                                creationDate: selectedDate
                            )
                            viewModel.addTask(recurringTask)
                            // Delete the original non-recurring task
                            viewModel.deleteTask(task)
                        } else {
                            // Update existing task
                            viewModel.updateTask(updatedTask)
                        }
                        
                        dismiss()
                    }
                    .disabled(title.isEmpty || (makeRecurring && selectedDays.isEmpty))
                }
            }
        }
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