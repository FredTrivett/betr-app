import SwiftUI
import ConfettiSwiftUI

struct ReflectionFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    let rating: ReflectionRating
    let stats: (completed: Int, total: Int)
    @Binding var shouldDismissToRoot: Bool
    @State private var showConfetti = 0
    @State private var confettiOpacity: Double = 1.0
    
    var body: some View {
        NavigationStack {
            ZStack {
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
                
                // Confetti layer
                if rating == .better {
                    ConfettiCannon(
                        counter: $showConfetti,
                        num: 50,
                        openingAngle: Angle(degrees: 0),
                        closingAngle: Angle(degrees: 360),
                        radius: 200,
                        repetitions: 1,
                        repetitionInterval: 0.02
                    )
                    .position(x: UIScreen.main.bounds.width / 2, y: 0) // Ensure it's at the top
                    .allowsHitTesting(false)
                    .opacity(confettiOpacity)
                    .onAppear {
                        showConfetti += 1
                        confettiOpacity = 1.0
                        // Start fade out after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.linear(duration: 1.0)) {
                                confettiOpacity = 0
                            }
                        }
                    }
                    .zIndex(.infinity)
                }
            }
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