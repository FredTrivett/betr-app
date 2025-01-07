import SwiftUI

struct ReflectionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReflectionHistoryViewModel
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var path = NavigationPath()
    @ObservedObject var taskViewModel: TaskListViewModel
    @State private var showingReflection = false
    
    init(taskViewModel: TaskListViewModel) {
        self.taskViewModel = taskViewModel
        self._viewModel = StateObject(wrappedValue: ReflectionHistoryViewModel())
    }
    
    var body: some View {
        NavigationStack(path: $path) {
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
                        onTap: { path.append(Date()) },
                        viewModel: taskViewModel,
                        reflectionViewModel: viewModel
                    )
                    .onAppear {
                        // Refresh both task counts and reflections when view appears
                        taskViewModel.objectWillChange.send()
                        viewModel.loadReflections()
                    }
                    
                    // History
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ReflectionHistoryList(
                            reflections: viewModel.displayedReflections,
                            onLoadMore: viewModel.loadMoreReflections,
                            onTapReflection: { date in
                                path.append(date)
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
            .navigationDestination(for: Date.self) { date in
                TaskListView(viewModel: taskViewModel, selectedDate: date)
            }
            .sheet(isPresented: $showingReflection) {
                BetterThanYesterdayView(viewModel: taskViewModel, selectedDate: Date())
            }
            .onChange(of: showingReflection) { _, isShowing in
                if !isShowing {
                    // Refresh reflections when the sheet is dismissed
                    viewModel.loadReflections()
                    taskViewModel.objectWillChange.send()
                }
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