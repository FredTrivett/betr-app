import SwiftUI

struct ReflectionFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    let rating: ReflectionRating
    let stats: (completed: Int, total: Int)
    @Binding var shouldDismissToRoot: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon and Rating
                VStack(spacing: 16) {
                    Image(systemName: rating.iconName)
                        .font(.system(size: 60))
                        .foregroundStyle(rating.color)
                    
                    Text(rating.rawValue.capitalized)
                        .font(.title.bold())
                        .foregroundStyle(rating.color)
                }
                .padding(.top, 40)
                
                // Stats
                Text("\(stats.completed)/\(stats.total) tasks completed")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Message
                Text(rating.message)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue Button at bottom
                Button {
                    shouldDismissToRoot = true
                    dismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .navigationBarBackButtonHidden(true)
        }
    }
}

#Preview {
    ReflectionFeedbackView(
        rating: .better,
        stats: (5, 7),
        shouldDismissToRoot: .constant(false)
    )
} 