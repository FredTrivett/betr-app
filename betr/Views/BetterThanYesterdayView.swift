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
    
    private var comparison: ProgressComparison? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return nil }
        return viewModel.compareProgress(current: selectedDate, previous: yesterday)
    }
    
    var body: some View {
        NavigationStack {
            // Main content in the back
            ZStack {
                // Content layer
                ZStack(alignment: .bottom) {
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
                                        title: "Completed"
                                    )
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // VS indicator
                                Text("vs")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                
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
                                        title: "Completed"
                                    )
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                    
                    // Fixed reflection section at bottom
                    if let comparison = comparison {
                        HStack {
                            Text("How do you feel about today?")
                                .font(.headline)
                            
                            Spacer()
                            
                            HStack(spacing: 12) {
                                ReflectionButton(
                                    title: "Better",
                                    systemImage: "arrow.up.circle.fill",
                                    color: .green
                                ) {
                                    submitReflection(.better, stats: comparison.currentStats)
                                }
                                
                                ReflectionButton(
                                    title: "Same",
                                    systemImage: "equal.circle.fill",
                                    color: .blue
                                ) {
                                    submitReflection(.same, stats: comparison.currentStats)
                                }
                                
                                ReflectionButton(
                                    title: "Worse",
                                    systemImage: "arrow.down.circle.fill",
                                    color: .red
                                ) {
                                    submitReflection(.worse, stats: comparison.currentStats)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                    }
                }
            }
            .navigationTitle("Daily Comparison")
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

struct ReflectionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) { // Reduced spacing
                Image(systemName: systemImage)
                    .font(.title2) // Slightly smaller icon
                Text(title)
                    .font(.caption)
            }
            .frame(width: 60) // Reduced width
            .foregroundStyle(color)
            .padding(.vertical, 8) // Reduced padding
            .padding(.horizontal, 4) // Reduced padding
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    BetterThanYesterdayView(viewModel: TaskListViewModel(), selectedDate: Date())
} 