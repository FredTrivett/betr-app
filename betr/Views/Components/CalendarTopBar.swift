import SwiftUI

struct CalendarTopBar: View {
    let streak: Int
    let onStreakTap: () -> Void
    let onProgressTap: () -> Void
    let onManageRecurringTap: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                // Streak indicator
                Button(action: onStreakTap) {
                    HStack(spacing: 4) {
                        Text("\(streak)")
                            .font(.headline)
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                
                // Progress History Button
                Button(action: onProgressTap) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Progress")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Manage recurring tasks button
                Button(action: onManageRecurringTap) {
                    Image(systemName: "repeat.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    CalendarTopBar(
        streak: 5,
        onStreakTap: {},
        onProgressTap: {},
        onManageRecurringTap: {}
    )
    .padding()
} 