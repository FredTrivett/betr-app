import SwiftUI

struct ReflectionHistoryList: View {
    let reflections: [DailyReflection]
    let onTapReflection: (DailyReflection) -> Void
    
    var body: some View {
        List {
            ForEach(reflections) { reflection in
                ReflectionRow(reflection: reflection, onTap: onTapReflection)
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    ReflectionHistoryList(
        reflections: [
            DailyReflection(
                date: Date(),
                rating: .better,
                tasksCompleted: 3,
                totalTasks: 4
            )
        ],
        onTapReflection: { _ in }
    )
} 