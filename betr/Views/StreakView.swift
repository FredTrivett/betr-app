import SwiftUI

struct StreakView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    let streak: Int
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Streak
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Text("\(streak)")
                                .font(.system(size: 48, weight: .bold))
                            Image(systemName: "flame.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                        }
                        
                        Text("Current Streak")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Streak Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Streak Details")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Use the app daily to maintain your streak", systemImage: "calendar")
                            Label("Complete at least one task to count for the day", systemImage: "checkmark.circle")
                            Label("Missing a day will reset your streak", systemImage: "exclamationmark.triangle")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Streak")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 