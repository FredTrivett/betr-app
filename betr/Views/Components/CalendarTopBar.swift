import SwiftUI

struct CalendarTopBar: View {
    let streak: Int
    let onStreakTap: () -> Void
    
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
                
                Spacer()
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
        onStreakTap: {}
    )
    .padding()
} 