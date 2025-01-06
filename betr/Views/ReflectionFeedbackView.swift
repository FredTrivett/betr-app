import SwiftUI

struct ReflectionFeedbackView: View {
    let rating: ReflectionRating
    let stats: (total: Int, completed: Int)
    let dismiss: () -> Void
    @State private var shouldAnimate = true
    
    var completionPercentage: Int {
        guard stats.total > 0 else { return 0 }
        return Int((Double(stats.completed) / Double(stats.total)) * 100)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Increased top padding
            Spacer()
                .frame(height: 32)
            
            // Header with large icon and message
            VStack(spacing: 16) {
                Image(systemName: rating.feedbackIcon)
                    .font(.system(size: 80))
                    .foregroundStyle(rating.color)
                    .symbolEffect(.bounce, options: .speed(1), isActive: shouldAnimate)
                    .onAppear {
                        // Animate for 1 second then stop
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            shouldAnimate = false
                        }
                    }
                
                Text(rating.feedbackTitle)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
            }
            
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: CGFloat(stats.completed) / CGFloat(stats.total))
                    .stroke(rating.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(completionPercentage)%")
                        .font(.system(size: 44, weight: .bold))
                    Text("Complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            
            // Stats and motivation
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    VStack {
                        Text("\(stats.completed)")
                            .font(.title)
                            .bold()
                        Text("Completed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack {
                        Text("\(stats.total)")
                            .font(.title)
                            .bold()
                        Text("Total Tasks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(rating.motivationalMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer() // This pushes everything up and the button down
            
            // Updated button styling with more width
            Button(action: dismiss) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(rating.color)
            .padding(.horizontal, 16) // Reduced horizontal padding to make button wider
            .padding(.bottom, 16) // Reduced bottom padding to be closer to bottom
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .edgesIgnoringSafeArea(.bottom) // This ensures the button can go to the bottom
    }
}

// Add these properties to ReflectionRating
extension ReflectionRating {
    var feedbackIcon: String {
        switch self {
        case .better: return "star.circle.fill"
        case .same: return "checkmark.circle.fill"
        case .worse: return "arrow.up.circle.fill"
        }
    }
    
    var feedbackTitle: String {
        switch self {
        case .better: return "Amazing Progress!"
        case .same: return "Staying Consistent!"
        case .worse: return "Tomorrow is a\nNew Day!"
        }
    }
    
    var motivationalMessage: String {
        switch self {
        case .better: return "You're crushing it! Keep up the fantastic work and watch your progress soar! 🚀"
        case .same: return "Consistency is key! You're building strong habits that will lead to lasting success. 💪"
        case .worse: return "Every setback is a setup for a comeback. Focus on small wins and keep moving forward! 💫"
        }
    }
}

#Preview {
    ReflectionFeedbackView(
        rating: .better,
        stats: (5, 7),
        dismiss: {}
    )
} 