import SwiftUI

struct ProgressComparisonView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var comparison: ProgressComparison?
    @State private var showingTaskList = false
    
    var body: some View {
        VStack(spacing: 12) {
            if let comparison = comparison {
                Button {
                    showingTaskList = true
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Progress")
                                .font(.headline)
                            Text("\(comparison.currentStats.completed)/\(comparison.currentStats.total) tasks")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            if comparison.isPerfect {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                
                                Text("Perfect!")
                                    .foregroundStyle(.green)
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: comparison.isImprovement ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundStyle(comparison.isImprovement ? .green : .red)
                                
                                Text(comparison.formattedPercentageChange)
                                    .foregroundStyle(comparison.isImprovement ? .green : .red)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            updateComparison()
        }
        .onChange(of: viewModel.tasks) { _, _ in
            updateComparison()
        }
        .sheet(isPresented: $showingTaskList) {
            TaskListView(viewModel: viewModel, selectedDate: Date())
        }
    }
    
    private func updateComparison() {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else { return }
        comparison = viewModel.compareProgress(previous: yesterday)
    }
} 