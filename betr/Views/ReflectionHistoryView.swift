import SwiftUI

struct ReflectionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReflectionHistoryViewModel()
    @ObservedObject var taskViewModel: TaskListViewModel
    @State private var selectedDate: Date?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats Section
                    VStack(spacing: 16) {
                        // Weekly Stats
                        StatsSummary(
                            title: "This Week",
                            stats: viewModel.weeklyStats
                        )
                        
                        // Monthly Stats
                        StatsSummary(
                            title: "This Month",
                            stats: viewModel.monthlyStats
                        )
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // History Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("History")
                            .font(.headline)
                        
                        ForEach(viewModel.reflectionsByDate.keys.sorted(by: >), id: \.self) { date in
                            if let reflections = viewModel.reflectionsByDate[date] {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    
                                    ForEach(reflections) { reflection in
                                        Button {
                                            selectedDate = reflection.date
                                        } label: {
                                            HStack {
                                                Image(systemName: reflection.rating.iconName)
                                                    .foregroundStyle(reflection.rating.color)
                                                Text("\(reflection.tasksCompleted)/\(reflection.totalTasks) tasks")
                                                
                                                Spacer()
                                                
                                                Text(reflection.rating.rawValue.capitalized)
                                                    .foregroundStyle(reflection.rating.color)
                                                    .font(.callout.bold())
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Progress History")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedDate) { date in
                TaskListView(viewModel: taskViewModel, selectedDate: date)
            }
        }
    }
}

extension Date: Identifiable {
    public var id: Date { self }
}

struct StatsSummary: View {
    let title: String
    let stats: (better: Int, same: Int, worse: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(count: stats.better, label: "Better", color: .green)
                StatItem(count: stats.same, label: "Same", color: .blue)
                StatItem(count: stats.worse, label: "Worse", color: .red)
            }
        }
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

extension ReflectionRating {
    var iconName: String {
        switch self {
        case .better: return "arrow.up.circle.fill"
        case .same: return "equal.circle.fill"
        case .worse: return "arrow.down.circle.fill"
        }
    }
} 