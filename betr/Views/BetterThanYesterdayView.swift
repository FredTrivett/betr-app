import SwiftUI

struct BetterThanYesterdayView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    @StateObject private var reflectionViewModel = ReflectionHistoryViewModel()
    @State private var showingMessage = false
    @State private var selectedRating: ReflectionRating?
    @State private var showingFeedback = false
    @State private var shouldDismissToRoot = false
    let selectedDate: Date
    
    private var canReflect: Bool {
        DayBoundary.canReflectOn(selectedDate)
    }
    
    private var comparison: ProgressComparison? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return nil }
        return viewModel.compareProgress(current: selectedDate, previous: yesterday)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        if let comparison = comparison {
                            // Today's stats
                            VStack(spacing: 8) {
                                Text("Today")
                                    .font(.headline)
                                Text("\(comparison.currentStats.completed)/\(comparison.currentStats.total) tasks")
                                    .font(.title)
                                
                                // Today's task list
                                TaskList(
                                    tasks: viewModel.tasks,
                                    date: selectedDate,
                                    title: "Today's Tasks"
                                )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Yesterday's stats
                            VStack(spacing: 8) {
                                Text("Yesterday")
                                    .font(.headline)
                                Text("\(comparison.previousStats.completed)/\(comparison.previousStats.total) tasks")
                                    .font(.title)
                                
                                // Yesterday's task list
                                TaskList(
                                    tasks: viewModel.tasks,
                                    date: comparison.previousDate,
                                    title: "Yesterday's Tasks"
                                )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Percentage change indicator
                            if comparison.currentStats.total > 0 && comparison.previousStats.total > 0 {
                                HStack(spacing: 12) {
                                    Image(systemName: comparison.isImprovement ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(comparison.isImprovement ? .green : .red)
                                    
                                    Text(comparison.formattedPercentageChange)
                                        .font(.headline)
                                        .foregroundStyle(comparison.isImprovement ? .green : .red)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            // Add spacer to push content up
                            Spacer(minLength: 100)
                        }
                    }
                    .padding()
                }
                
                // Fixed bottom rating section
                if let comparison = comparison, canReflect {
                    VStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Text("How do you feel about your progress?")
                                .font(.headline)
                            
                            HStack(spacing: 16) {
                                RatingButton(
                                    rating: .better,
                                    isSelected: selectedRating == .better,
                                    action: { submitReflection(.better, stats: comparison.currentStats) }
                                )
                                
                                RatingButton(
                                    rating: .same,
                                    isSelected: selectedRating == .same,
                                    action: { submitReflection(.same, stats: comparison.currentStats) }
                                )
                                
                                RatingButton(
                                    rating: .worse,
                                    isSelected: selectedRating == .worse,
                                    action: { submitReflection(.worse, stats: comparison.currentStats) }
                                )
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                    }
                } else if !canReflect {
                    VStack {
                        Spacer()
                        Text("Reflection period has ended")
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding()
                    }
                }
            }
            .navigationTitle("Progress Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFeedback) {
                if shouldDismissToRoot {
                    dismiss()
                }
            } content: {
                if let rating = selectedRating, let comparison = comparison {
                    ReflectionFeedbackView(
                        rating: rating,
                        stats: comparison.currentStats,
                        shouldDismissToRoot: $shouldDismissToRoot
                    )
                }
            }
        }
    }
    
    private func submitReflection(_ rating: ReflectionRating, stats: (completed: Int, total: Int)) {
        selectedRating = rating
        reflectionViewModel.addReflection(rating, stats: stats)
        showingFeedback = true
    }
}

// MARK: - Supporting Views
private struct RatingButton: View {
    let rating: ReflectionRating
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch rating {
        case .better: return "arrow.up.circle.fill"
        case .same: return "equal.circle.fill"
        case .worse: return "arrow.down.circle.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(rating.rawValue.capitalized)
                    .font(.caption)
            }
            .frame(width: 60)
            .foregroundStyle(rating.color)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(rating.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct TaskList: View {
    let tasks: [Task]
    let date: Date
    let title: String
    
    var completedTasks: [Task] {
        tasks.filter { task in
            task.isAvailableForDate(date) && task.isCompletedForDate(date)
        }
    }
    
    var incompleteTasks: [Task] {
        tasks.filter { task in
            task.isAvailableForDate(date) && !task.isCompletedForDate(date)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !completedTasks.isEmpty {
                HStack {
                    Text("Completed")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                ForEach(completedTasks) { task in
                    Text("• \(task.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !incompleteTasks.isEmpty {
                HStack {
                    Text("Not Completed")
                        .font(.subheadline.bold())
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                ForEach(incompleteTasks) { task in
                    Text("• \(task.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BetterThanYesterdayView(viewModel: TaskListViewModel(), selectedDate: Date())
} 