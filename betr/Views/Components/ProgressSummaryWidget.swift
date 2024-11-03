import SwiftUI

struct ProgressSummaryWidget: View {
    @ObservedObject var viewModel: TaskListViewModel
    
    private var todayStats: (completed: Int, total: Int) {
        (
            completed: viewModel.completedTasksCount(for: Date()),
            total: viewModel.availableTasksCount(for: Date())
        )
    }
    
    private var lastFiveReflections: [DailyReflection?] {
        let calendar = Calendar.current
        return (1...5).map { daysAgo in
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                return viewModel.getReflectionForDate(date)
            }
            return nil
        }.reversed()
    }
    
    var body: some View {
        HStack {
            // Left side: Title and Tasks
            VStack(alignment: .leading, spacing: 4) {
                Text("My Progress")
                    .font(.title3.bold())
                HStack(spacing: 4) {
                    Text("\(todayStats.completed)/\(todayStats.total)")
                        .font(.body)
                    Text("Tasks")
                        .font(.body)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Right side: Reflection circles
            HStack(spacing: 8) {
                ForEach(Array(lastFiveReflections.enumerated()), id: \.offset) { _, reflection in
                    Circle()
                        .fill(reflection?.rating.color ?? Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            .padding(.trailing, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProgressSummaryWidget(viewModel: TaskListViewModel())
        .padding()
} 