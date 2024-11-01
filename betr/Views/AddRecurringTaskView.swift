import SwiftUI

struct AddRecurringTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TaskListViewModel
    var taskToEdit: Task? = nil
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedDays: Set<Weekday> = []
    @State private var isCustomSchedule = false
    
    private let weekdays: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
    
    init(viewModel: TaskListViewModel, taskToEdit: Task? = nil) {
        self.viewModel = viewModel
        self.taskToEdit = taskToEdit
        
        if let task = taskToEdit {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _isCustomSchedule = State(initialValue: task.recurringDays != nil)
            _selectedDays = State(initialValue: task.recurringDays ?? [])
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
                    
                    Section {
                        Toggle("Custom Schedule", isOn: $isCustomSchedule)
                        
                        if isCustomSchedule {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Repeat on:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    ForEach(weekdays, id: \.self) { weekday in
                                        WeekdayBubble(
                                            letter: String(weekday.shortName.prefix(1)),
                                            isSelected: selectedDays.contains(weekday),
                                            action: {
                                                if selectedDays.contains(weekday) {
                                                    selectedDays.remove(weekday)
                                                } else {
                                                    selectedDays.insert(weekday)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } else {
                            Text("Task will repeat daily")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button(action: addOrUpdateTask) {
                    Text(taskToEdit == nil ? "Add Recurring Task" : "Update Task")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || 
                         (isCustomSchedule && selectedDays.isEmpty))
                .padding()
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
    
    private func addOrUpdateTask() {
        let task = Task(
            id: taskToEdit?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            description: description.trimmingCharacters(in: .whitespaces),
            isRecurring: true,
            creationDate: taskToEdit?.creationDate ?? Date(),
            completionDates: taskToEdit?.completionDates ?? [],
            recurringDays: isCustomSchedule ? selectedDays : nil
        )
        
        if taskToEdit != nil {
            viewModel.updateTask(task)
        } else {
            viewModel.addTask(task)
        }
        dismiss()
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