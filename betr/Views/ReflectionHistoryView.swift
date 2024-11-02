import SwiftUI

struct ReflectionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReflectionHistoryViewModel
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedDate: IdentifiableDate?
    let taskViewModel: TaskListViewModel
    
    init(taskViewModel: TaskListViewModel) {
        self.taskViewModel = taskViewModel
        self._viewModel = StateObject(wrappedValue: ReflectionHistoryViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time frame selector
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.rawValue)
                                .tag(timeFrame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Progress Chart
                    ProgressChart(
                        data: viewModel.getChartData(for: selectedTimeFrame),
                        timeFrame: selectedTimeFrame
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Today's Summary
                    TodaySummary(
                        reflection: viewModel.todayReflection,
                        completedTasks: taskViewModel.completedTasksCount(for: Date()),
                        totalTasks: taskViewModel.availableTasksCount(for: Date()),
                        onTap: { selectedDate = IdentifiableDate(date: Date()) }
                    )
                    
                    // History
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ReflectionHistoryList(
                            reflections: viewModel.displayedReflections,
                            onLoadMore: viewModel.loadMoreReflections,
                            onTapReflection: { date in
                                selectedDate = IdentifiableDate(date: date)
                            }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Progress History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDate) { identifiableDate in
                TaskListView(viewModel: taskViewModel, selectedDate: identifiableDate.date)
            }
        }
    }
}

struct ReflectionRow: View {
    let reflection: DailyReflection
    let onTap: (Date) -> Void
    
    var body: some View {
        Button {
            onTap(reflection.date)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(reflection.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                    Text("\(reflection.tasksCompleted)/\(reflection.totalTasks) tasks completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(reflection.rating.color)
                    .frame(width: 12, height: 12)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

#Preview {
    ReflectionHistoryView(taskViewModel: TaskListViewModel())
} 