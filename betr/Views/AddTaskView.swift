import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let selectedDate: Date
    let showToggle: Bool
    
    @State private var title = ""
    @State private var description = ""
    @State private var isRecurring = false
    @State private var selectedDays = Set(Weekday.allCases)
    
    init(viewModel: TaskListViewModel, selectedDate: Date, showToggle: Bool) {
        self.viewModel = viewModel
        self.selectedDate = selectedDate
        self.showToggle = showToggle
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                if showToggle {
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
                } else {
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
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let task = Task(
                            id: UUID(),
                            title: title,
                            description: description,
                            isRecurring: isRecurring,
                            creationDate: selectedDate,
                            originalTaskId: nil,
                            selectedDays: selectedDays
                        )
                        viewModel.addTask(task)
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
    AddTaskView(
        viewModel: TaskListViewModel(),
        selectedDate: Date(),
        showToggle: true
    )
} 