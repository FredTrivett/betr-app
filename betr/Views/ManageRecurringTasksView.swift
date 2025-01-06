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
            VStack {
                if recurringTasks.isEmpty {
                    ContentUnavailableView(
                        "No Recurring Tasks",
                        systemImage: "repeat.circle",
                        description: Text("Add a recurring task using the button below")
                    )
                } else {
                    List {
                        ForEach(recurringTasks) { task in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title)
                                        .foregroundStyle(.primary)
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
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTask = task
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
                
                // Add New Recurring Task button at bottom
                Button {
                    isAddingTask = true
                } label: {
                    Text("New Recurring Task")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Recurring Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(viewModel: viewModel, selectedDate: Date(), showToggle: false)
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