import SwiftUI

struct AddRecurringTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TaskListViewModel
    var taskToEdit: Task? = nil
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedDays: Set<Weekday> = []
    
    // Track original values to detect changes
    private let originalTitle: String
    private let originalDescription: String
    private let originalSelectedDays: Set<Weekday>
    
    init(viewModel: TaskListViewModel, taskToEdit: Task? = nil) {
        self.viewModel = viewModel
        self.taskToEdit = taskToEdit
        
        let taskTitle = taskToEdit?.title ?? ""
        let taskDescription = taskToEdit?.description ?? ""
        let taskDays = taskToEdit?.recurringDays ?? []
        
        _title = State(initialValue: taskTitle)
        _description = State(initialValue: taskDescription)
        _selectedDays = State(initialValue: taskDays)
        
        originalTitle = taskTitle
        originalDescription = taskDescription
        originalSelectedDays = taskDays
    }
    
    private var hasChanges: Bool {
        title != originalTitle ||
        description != originalDescription ||
        selectedDays != originalSelectedDays
    }
    
    var body: some View {
        NavigationStack {
            TaskFormContent(
                title: $title,
                description: $description,
                selectedDays: $selectedDays
            )
            .safeAreaInset(edge: .bottom) {
                BottomButton(
                    title: title,
                    selectedDays: selectedDays,
                    hasChanges: hasChanges,
                    isEditing: taskToEdit != nil,
                    action: {
                        if taskToEdit != nil {
                            if hasChanges {
                                updateTask()
                            } else {
                                dismiss()
                            }
                        } else {
                            addTask()
                        }
                    }
                )
            }
            .navigationTitle(taskToEdit == nil ? "New Recurring Task" : "Edit Task")
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
            title: title,
            description: description,
            isRecurring: true,
            recurringDays: selectedDays
        )
        viewModel.addTask(task)
        dismiss()
    }
    
    private func updateTask() {
        guard let existingTask = taskToEdit else { return }
        
        var updatedTask = Task(
            id: existingTask.id,
            title: title,
            description: description,
            isRecurring: true,
            lastCompletedDate: existingTask.lastCompletedDate,
            creationDate: existingTask.creationDate,
            completionDates: existingTask.completionDates,
            deletedDate: existingTask.deletedDate,
            recurringDays: selectedDays
        )
        
        updatedTask.excludedDates = existingTask.excludedDates
        viewModel.updateTask(updatedTask)
        dismiss()
    }
}

// MARK: - Supporting Views
private struct TaskFormContent: View {
    @Binding var title: String
    @Binding var description: String
    @Binding var selectedDays: Set<Weekday>
    
    var body: some View {
        Form {
            Section {
                TextField("Task title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Repeat on") {
                WeekdaySelector(selectedDays: $selectedDays)
                    .padding(.vertical, 8)
            }
        }
    }
}

private struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Weekday>
    
    private let weekdays: [Weekday] = [
        .monday, .tuesday, .wednesday, 
        .thursday, .friday, .saturday, .sunday
    ]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekdays, id: \.self) { day in
                WeekdayBubble(
                    letter: day.singleLetter,
                    isSelected: selectedDays.contains(day)
                ) {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }
            }
        }
    }
}

private struct BottomButton: View {
    let title: String
    let selectedDays: Set<Weekday>
    let hasChanges: Bool
    let isEditing: Bool
    let action: () -> Void
    
    private var isDisabled: Bool {
        title.isEmpty || selectedDays.isEmpty
    }
    
    private var buttonText: String {
        if isEditing {
            return hasChanges ? "Update Task" : "Close"
        }
        return "Add Task"
    }
    
    var body: some View {
        VStack {
            Button(action: action) {
                Text(buttonText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isDisabled ? .gray.opacity(0.3) : .blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isDisabled)
            .padding()
            .background(.ultraThinMaterial)
        }
    }
}

struct WeekdayBubble: View {
    let letter: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.system(.subheadline, weight: .medium))
                .frame(width: 36, height: 36)
                .background(isSelected ? .blue : .clear)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? .clear : .gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddRecurringTaskView(viewModel: TaskListViewModel())
} 