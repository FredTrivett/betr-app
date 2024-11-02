import SwiftUI

struct TodaySummary: View {
    let reflection: DailyReflection?
    let completedTasks: Int
    let totalTasks: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 20) {
                Text("Today")
                    .font(.title2.bold())
                
                HStack(spacing: 30) {
                    // Tasks Progress
                    VStack(spacing: 8) {
                        Text("\(completedTasks)/\(totalTasks)")
                            .font(.system(size: 34, weight: .bold))
                        Text("Tasks Completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 50)
                    
                    // Day Rating
                    VStack(spacing: 8) {
                        if let reflection = reflection {
                            Image(systemName: reflection.rating.iconName)
                                .font(.system(size: 34))
                                .foregroundStyle(reflection.rating.color)
                            Text(reflection.rating.rawValue.capitalized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 34))
                                .foregroundStyle(.secondary)
                            Text("Not Rated")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
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
            onTap: {}
        )
        
        TodaySummary(
            reflection: nil,
            completedTasks: 2,
            totalTasks: 7,
            onTap: {}
        )
    }
    .padding()
} 