import SwiftUI

struct ManageRecurringTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    @State private var isAddingTask = false
    @State private var selectedTask: Task? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.recurringTasks.isEmpty {
                    ContentUnavailableView(
                        "No Recurring Tasks",
                        systemImage: "repeat.circle",
                        description: Text("Add a recurring task using the + button")
                    )
                } else {
                    List {
                        ForEach(viewModel.recurringTasks) { task in
                            VStack(alignment: .leading) {
                                Text(task.title)
                                    .font(.headline)
                                if !task.description.isEmpty {
                                    Text(task.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    ForEach(Weekday.sortedCases, id: \.self) { day in
                                        DayIndicator(
                                            day: day,
                                            isSelected: task.selectedDays.contains(day)
                                        )
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    selectedTask = task
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recurring Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isAddingTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(viewModel: viewModel, selectedDate: Date(), showToggle: false)
        }
        .sheet(item: $selectedTask) { task in
            EditTaskView(
                viewModel: viewModel,
                task: task
            )
        }
    }
}

struct DayIndicator: View {
    let day: Weekday
    let isSelected: Bool
    
    var body: some View {
        Text(day.dayLetter)
            .font(.caption)
            .padding(6)
            .frame(width: 24, height: 24)
            .background(isSelected ? .blue.opacity(0.2) : .clear)
            .clipShape(Circle())
            .foregroundStyle(isSelected ? .blue : .secondary)
    }
}

#Preview {
    NavigationStack {
        ManageRecurringTasksView(viewModel: TaskListViewModel())
    }
} 