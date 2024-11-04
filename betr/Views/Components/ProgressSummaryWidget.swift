import SwiftUI

struct ProgressSummaryWidget: View {
    @ObservedObject var viewModel: TaskListViewModel
    @StateObject private var reflectionViewModel = ReflectionHistoryViewModel()
    
    private var recentReflections: [DailyReflection?] {
        let today = Calendar.current.startOfDay(for: Date())
        var reflections = [DailyReflection?](repeating: nil, count: 5)
        
        // If we have today's reflection, put it in the last spot
        if let todayReflection = reflectionViewModel.todayReflection {
            reflections[4] = todayReflection
        }
        
        // Get past reflections (excluding today)
        let pastReflections = reflectionViewModel.reflections
            .filter { !Calendar.current.isDate($0.date, inSameDayAs: today) }
            .prefix(4) // Take only up to 4 past reflections
        
        // Fill in the remaining spots from right to left
        for (index, reflection) in pastReflections.enumerated() {
            let insertIndex = 3 - index // Start from the right (excluding today's spot)
            if insertIndex >= 0 {
                reflections[insertIndex] = reflection
            }
        }
        
        return reflections
    }
    
    var body: some View {
        HStack {
            // Left side: Title and Tasks
            VStack(alignment: .leading, spacing: 4) {
                Text("My Progress")
                    .font(.title3.bold())
                HStack(spacing: 4) {
                    Text("\(viewModel.completedTasksCount(for: Date()))/\(viewModel.availableTasksCount(for: Date()))")
                        .font(.body)
                    Text("Tasks")
                        .font(.body)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Right side: Reflection circles
            HStack(spacing: 8) {
                ForEach(Array(recentReflections.enumerated()), id: \.offset) { _, reflection in
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
        .onAppear {
            reflectionViewModel.loadReflections()
        }
    }
}

#Preview {
    ProgressSummaryWidget(viewModel: TaskListViewModel())
        .padding()
} 