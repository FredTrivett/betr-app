import SwiftUI

struct StatsSummary: View {
    let title: String
    let stats: (better: Int, same: Int, worse: Int)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(count: stats.better, label: "Better", color: .green)
                StatItem(count: stats.same, label: "Same", color: .orange)
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
        VStack(spacing: 4) {
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

#Preview {
    StatsSummary(
        title: "Weekly Summary",
        stats: (better: 3, same: 2, worse: 1)
    )
    .padding()
} 