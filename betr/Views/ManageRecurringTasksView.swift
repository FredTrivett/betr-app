import SwiftUI

struct ManageRecurringTasksView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    @State private var isAddingTask = false
    @State private var selectedTask: Task? = nil
    
    private var recurringTasks: [Task] {
        viewModel.tasks.filter { $0.isRecurring }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if recurringTasks.isEmpty {
                    ContentUnavailableView(
                        "No Recurring Tasks",
                        systemImage: "repeat.circle",
                        description: Text("Add a recurring task using the + button")
                    )
                } else {
                    ForEach(recurringTasks) { task in
                        Button {
                            selectedTask = task
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                    if !task.description.isEmpty {
                                        Text(task.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "repeat.circle")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteTask(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
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
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddRecurringTaskView(viewModel: viewModel)
            }
            .sheet(item: $selectedTask) { task in
                AddRecurringTaskView(viewModel: viewModel, taskToEdit: task)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageRecurringTasksView(viewModel: TaskListViewModel())
    }
} 