import SwiftUI

struct ReflectionHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskViewModel: TaskListViewModel
    @State private var selectedDate: Date = Date()
    
    private var allowedDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        return [yesterday, today]
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Date Selector
                Picker("Select Date", selection: $selectedDate) {
                    ForEach(allowedDates, id: \.self) { date in
                        Text(date == Date() ? "Today" : "Yesterday")
                            .tag(date)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Reflection content for selected date
                BetterThanYesterdayView(
                    viewModel: taskViewModel,
                    selectedDate: selectedDate
                )
            }
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ReflectionHistoryView(taskViewModel: TaskListViewModel())
} 