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
        guard let previousDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return nil }
        return viewModel.compareProgress(current: selectedDate, previous: previousDate)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private func getDateDisplay(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return dateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 12) {
                        if let comparison = comparison {
                            // Selected date stats
                            VStack(spacing: 8) {
                                Text(getDateDisplay(selectedDate))
                                    .font(.headline)
                                Text("\(comparison.currentStats.completed)/\(comparison.currentStats.total) tasks")
                                    .font(.title)
                                
                                // Today's task list
                                TaskList(
                                    tasks: viewModel.tasks,
                                    date: selectedDate,
                                    title: "Tasks"
                                )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            // Add VS text here with reduced padding
                            Text("vs")
                                .font(.title2.bold())
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 4)
                            
                            // Previous day stats
                            VStack(spacing: 8) {
                                Text(getDateDisplay(comparison.previousDate))
                                    .font(.headline)
                                Text("\(comparison.previousStats.completed)/\(comparison.previousStats.total) tasks")
                                    .font(.title)
                                
                                // Previous day's task list
                                TaskList(
                                    tasks: viewModel.tasks,
                                    date: comparison.previousDate,
                                    title: "Tasks"
                                )
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
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
                            
                            HStack {
                                Spacer(minLength: 8)  // Reduced from 16 to 8
                                
                                RatingButton(
                                    rating: .better,
                                    isSelected: selectedRating == .better,
                                    action: { submitReflection(.better, stats: comparison.currentStats) }
                                )
                                
                                Spacer()
                                
                                RatingButton(
                                    rating: .same,
                                    isSelected: selectedRating == .same,
                                    action: { submitReflection(.same, stats: comparison.currentStats) }
                                )
                                
                                Spacer()
                                
                                RatingButton(
                                    rating: .worse,
                                    isSelected: selectedRating == .worse,
                                    action: { submitReflection(.worse, stats: comparison.currentStats) }
                                )
                                
                                Spacer(minLength: 8)  // Reduced from 16 to 8
                            }
                        }
                        .padding(.horizontal, 8)  // Reduced from default to 8
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 8)  // Reduced outer padding too
                        .padding(.bottom)
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
        reflectionViewModel.addReflection(rating, stats: stats, for: selectedDate)
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
            .frame(maxWidth: .infinity)  // Make button take equal width
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
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(completedTasks) { task in
                        Text("• \(task.title)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
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
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(incompleteTasks) { task in
                        Text("• \(task.title)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    BetterThanYesterdayView(viewModel: TaskListViewModel(), selectedDate: Date())
} 