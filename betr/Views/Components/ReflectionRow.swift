import SwiftUI

struct ReflectionRow: View {
    let reflection: DailyReflection
    let onTap: (DailyReflection) -> Void
    
    var body: some View {
        Button {
            onTap(reflection)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reflection.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.headline)
                    
                    Text("\(reflection.tasksCompleted)/\(reflection.totalTasks) Tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: reflection.rating.iconName)
                    .foregroundStyle(reflection.rating.color)
                    .font(.title2)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReflectionRow(
        reflection: DailyReflection(
            date: Date(),
            rating: .better,
            tasksCompleted: 3,
            totalTasks: 4
        ),
        onTap: { _ in }
    )
    .padding()
} 