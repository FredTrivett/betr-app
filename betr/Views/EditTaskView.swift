import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let task: Task
    let isRecurring: Bool
    let selectedDate: Date
    
    @State private var title: String
    @State private var description: String
    @State private var makeRecurring = false
    @State private var selectedDays: Set<Weekday>
    
    init(task: Task, isRecurring: Bool, selectedDate: Date, viewModel: TaskListViewModel) {
        self.task = task
        self.isRecurring = isRecurring
        self.selectedDate = selectedDate
        self.viewModel = viewModel
        
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description)
        self._selectedDays = State(initialValue: task.selectedDays.isEmpty ? Set(Weekday.allCases) : task.selectedDays)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                Section(header: Text("Selected days")) {
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
                        updatedTask.isRecurring = isRecurring
                        updatedTask.selectedDays = selectedDays
                        updatedTask.creationDate = selectedDate
                        viewModel.updateTask(updatedTask)
                        dismiss()
                    }
                    .disabled(title.isEmpty || (isRecurring && selectedDays.isEmpty))
                }
            }
        }
    }
    
    private func toggleDay(_ day: Weekday) {
        if selectedDays.count == Weekday.allCases.count {
            selectedDays = [day]
        } else {
            if selectedDays.contains(day) {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
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