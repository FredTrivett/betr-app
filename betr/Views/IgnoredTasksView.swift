import SwiftUI

struct IgnoredTasksView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var viewModel: TaskListViewModel
    let date: Date
    
    var body: some View {
        NavigationStack {
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
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Ignored Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 