import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let selectedDate: Date
    
    @State private var title = ""
    @State private var description = ""
    @State private var isRecurring = false
    @State private var selectedDays: Set<Weekday> = Set(Weekday.allCases)
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(4...6)
                }
                
                Section {
                    Toggle("Make Recurring", isOn: $isRecurring)
                    
                    if isRecurring {
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
                            title: title,
                            description: description,
                            isRecurring: isRecurring,
                            creationDate: selectedDate
                        )
                        viewModel.addTask(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty || (isRecurring && selectedDays.isEmpty))
                }
            }
        }
    }
}

#Preview {
    AddTaskView(
        viewModel: TaskListViewModel(),
        selectedDate: Date()
    )
} 