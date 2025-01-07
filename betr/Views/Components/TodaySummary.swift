import SwiftUI

struct TodaySummary: View {
    let reflection: DailyReflection?
    let completedTasks: Int
    let totalTasks: Int
    let onTap: () -> Void
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject var reflectionViewModel: ReflectionHistoryViewModel
    
    @State private var showingReflection = false
    
    var body: some View {
        Button(action: {
            if reflection != nil {
                showingReflection = true
            } else {
                onTap()
            }
        }) {
            VStack(spacing: 16) {
                // Progress section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.headline)
                        Text("\(completedTasks)/\(totalTasks) tasks completed")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Progress circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .bold()
                    }
                    .frame(width: 44, height: 44)
                }
                
                Divider()
                
                // Reflection section
                if let reflection = reflection {
                    // Show existing reflection
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Today's Reflection")
                                    .font(.headline)
                                
                                HStack(spacing: 8) {
                                    Image(systemName: reflection.rating.icon)
                                        .foregroundStyle(reflection.rating.color)
                                    
                                    Text("You did")
                                        .foregroundStyle(.secondary)
                                    Text(reflection.rating.rawValue)
                                        .foregroundStyle(reflection.rating.color)
                                        .bold()
                                    Text("than yesterday")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("Tap to update your reflection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Show reflection prompt
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Reflection")
                                .font(.headline)
                            Text("How did you do today?")
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "square.and.pencil.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingReflection) {
            BetterThanYesterdayView(viewModel: viewModel, selectedDate: Date())
        }
        .onChange(of: showingReflection) { _, isShowing in
            if !isShowing {
                reflectionViewModel.loadReflections()
            }
        }
    }
    
    private var progress: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(completedTasks) / Double(totalTasks)
    }
}

#Preview {
    VStack {
        TodaySummary(
            reflection: DailyReflection(
                rating: .better,
                tasksCompleted: 5,
                totalTasks: 7
            ),
            completedTasks: 5,
            totalTasks: 7,
            onTap: {},
            viewModel: TaskListViewModel(),
            reflectionViewModel: ReflectionHistoryViewModel()
        )
        
        TodaySummary(
            reflection: nil,
            completedTasks: 2,
            totalTasks: 7,
            onTap: {},
            viewModel: TaskListViewModel(),
            reflectionViewModel: ReflectionHistoryViewModel()
        )
    }
    .padding()
} 