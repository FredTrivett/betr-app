import SwiftUI

struct IgnoredTasksView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var viewModel: TaskListViewModel
    let date: Date
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    ForEach(viewModel.getIgnoredTasksForDate(date)) { task in
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
                            
                            Button {
                                viewModel.unignoreTaskForDay(task, on: date)
                            } label: {
                                Text("Add Back")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                Button {
                    showingAddTask = true
                } label: {
                    Text("Add Recurring Task")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationTitle("Ignored Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel, selectedDate: date, showToggle: false)
        }
    }
} 