import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var isRecurring: Bool
    @State private var selectedDays: Set<Weekday>
    
    init(viewModel: TaskListViewModel, task: Task) {
        self.viewModel = viewModel
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _isRecurring = State(initialValue: task.isRecurring)
        _selectedDays = State(initialValue: task.selectedDays)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                if !task.isRecurring {
                    Section {
                        Toggle("Make Recurring", isOn: $isRecurring)
                        
                        if isRecurring {
                            HStack {
                                ForEach(Weekday.sortedCases, id: \.self) { day in
                                    DayToggle(
                                        day: day,
                                        isSelected: selectedDays.contains(day),
                                        onTap: { toggleDay(day) }
                                    )
                                }
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
                        let updatedTask = Task(
                            id: task.id,
                            title: title,
                            description: description,
                            isRecurring: isRecurring,
                            creationDate: task.creationDate,
                            originalTaskId: task.originalTaskId,
                            selectedDays: selectedDays
                        )
                        viewModel.updateTask(updatedTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty || (isRecurring && selectedDays.isEmpty))
                }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

#Preview {
    EditTaskView(
        viewModel: TaskListViewModel(),
        task: Task(title: "Sample Task", description: "Sample Description")
    )
} 