import SwiftUI

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var selectedDays: Set<Weekday>
    
    init(viewModel: TaskListViewModel, task: Task) {
        self.viewModel = viewModel
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _selectedDays = State(initialValue: Set(task.selectedDays))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                }
                
                if task.isRecurring {
                    Section(header: Text("Recurring Days")) {
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
                        saveTask()
                    }
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
    
    private func saveTask() {
        let currentDate = Date()
        let updatedTask = Task(
            id: task.id,
            title: title,
            description: description,
            isRecurring: task.isRecurring,
            completedDates: task.completedDates,
            excludedDates: task.excludedDates,
            creationDate: task.creationDate,
            lastModifiedDate: currentDate,
            originalTaskId: task.originalTaskId,
            selectedDays: Array(selectedDays),
            effectiveDate: currentDate
        )
        
        viewModel.updateTask(updatedTask, preserveHistoryBefore: currentDate)
        dismiss()
    }
}

#Preview {
    EditTaskView(
        viewModel: TaskListViewModel(),
        task: Task(title: "Sample Task", description: "Sample Description")
    )
} 