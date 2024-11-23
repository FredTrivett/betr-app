import SwiftUI

struct MonthView: View {
    let date: Date
    @Binding var selectedDate: Date?
    let taskViewModel: TaskListViewModel
    @Binding var showingTaskList: Bool
    @StateObject private var reflectionViewModel = ReflectionHistoryViewModel()
    
    private let calendar = Calendar.current
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date.formatted(.dateTime.year().month(.wide)))
                .font(.title2.bold())
                .padding(.leading, 4)
            
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.1) { _, date in
                    if let date = date {
                        let isFutureDate = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
                        
                        DayCell(
                            date: date,
                            isSelected: selectedDate.map { calendar.isDate(date, inSameDayAs: $0) } ?? false,
                            isToday: calendar.isDateInToday(date),
                            completionStatus: getCompletionStatus(for: date),
                            isFutureDate: isFutureDate,
                            reflectionRating: getTodayReflection(for: date)?.rating
                        )
                        .id(calendar.isDateInToday(date) ? 0 : nil)
                        .onTapGesture {
                            selectedDate = nil  // Reset first to ensure trigger
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                    }
                }
            }
        }
        .onAppear {
            // This will ensure we have the latest reflection data
            reflectionViewModel.loadReflections()
        }
    }
    
    private func daysInMonth() -> [Date?] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // Set Monday as first weekday
        
        let interval = calendar.dateInterval(of: .month, for: date)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let offsetDays = (firstWeekday + 5) % 7 // Adjust offset for Monday start
        
        let daysInMonth = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var days: [Date?] = Array(repeating: nil, count: offsetDays)
        
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func getCompletionStatus(for date: Date) -> DayCompletionStatus {
        let tasks = taskViewModel.tasks.filter { task in
            task.isAvailableForDate(date)
        }
        
        if tasks.isEmpty { return .none }
        
        let completedTasks = tasks.filter { task in
            task.isCompletedForDate(date)
        }
        
        if completedTasks.count == tasks.count {
            return .full
        } else if completedTasks.isEmpty {
            return .none
        } else {
            return .partial
        }
    }
    
    private func getTodayReflection(for date: Date) -> DailyReflection? {
        if calendar.isDateInToday(date) {
            return reflectionViewModel.todayReflection
        }
        return reflectionViewModel.getReflection(for: date)
    }
}

#Preview {
    MonthView(
        date: Date(),
        selectedDate: .constant(Date()),
        taskViewModel: TaskListViewModel(),
        showingTaskList: .constant(false)
    )
} 