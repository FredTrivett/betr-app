import SwiftUI

struct CalendarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var calendarViewModel: CalendarViewModel
    @ObservedObject var taskViewModel: TaskListViewModel
    @State private var showingTaskList = false
    @State private var showScrollToToday = false
    @State private var showManageRecurring = false
    @State private var scrollProxy: ScrollViewProxy?
    @State private var currentDayPosition: ScrollPosition = .visible
    @State private var showingProgressHistory = false
    @State private var showingStreakView = false
    
    init(taskViewModel: TaskListViewModel) {
        self._calendarViewModel = StateObject(wrappedValue: CalendarViewModel(taskViewModel: taskViewModel))
        self.taskViewModel = taskViewModel
    }
    
    private var monthsToShow: (past: Int, future: Int) {
        let calendar = Calendar.current
        let pastMonths = abs(calendar.dateComponents([.month], from: AppSettings.installationDate, to: Date()).month ?? 0) + 1
        return (past: pastMonths, future: 12)  // Show all past months and 12 months into future
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Fixed status bar background with proper height
                GeometryReader { geometry in
                    Color(uiColor: .systemBackground)
                        .frame(height: geometry.safeAreaInsets.top)
                        .ignoresSafeArea()
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 32) {
                                // Add padding to account for status bar
                                Color.clear
                                    .frame(height: 20)
                                
                                // Calendar months with unlimited past and 12 months future
                                ForEach(-monthsToShow.past...monthsToShow.future, id: \.self) { monthOffset in
                                    MonthView(
                                        date: Calendar.current.date(
                                            byAdding: .month,
                                            value: monthOffset,
                                            to: Date()
                                        ) ?? Date(),
                                        selectedDate: $calendarViewModel.selectedDate,
                                        taskViewModel: taskViewModel,
                                        showingTaskList: $showingTaskList
                                    )
                                    .id(monthOffset)
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: ScrollOffsetPreferenceKey.self,
                                                value: geometry.frame(in: .named("scroll")).minY
                                            )
                                        }
                                    )
                                }
                                .padding(.horizontal)
                            }
                            .padding(.top, 70)
                            .padding(.bottom, 100)
                        }
                        .coordinateSpace(name: "scroll")
                        .onAppear {
                            scrollProxy = proxy
                            withAnimation {
                                proxy.scrollTo(0, anchor: .center)
                            }
                        }
                    }
                    
                    // Fixed top bar with streak and buttons
                    VStack {
                        // White background container for all buttons
                        VStack {
                            HStack {
                                // Streak indicator
                                Button {
                                    showingStreakView = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Text("\(calendarViewModel.streak)")
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
                                Button {
                                    showingProgressHistory = true
                                } label: {
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
                                Button {
                                    showManageRecurring = true
                                } label: {
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
                        
                        Spacer()
                    }
                    
                    // Progress comparison view at bottom
                    ProgressComparisonView(viewModel: taskViewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    
                    // Scroll to Today button
                    if showScrollToToday {
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    scrollProxy?.scrollTo(0, anchor: .center)
                                }
                            }) {
                                HStack {
                                    Image(systemName: currentDayPosition == .above ? "arrow.up" : "arrow.down")
                                    Text("Today")
                                }
                                .padding()
                                .background(.thinMaterial)
                                .clipShape(Capsule())
                                .shadow(radius: 5)
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingTaskList) {
            TaskListView(viewModel: taskViewModel, selectedDate: calendarViewModel.selectedDate)
        }
        .sheet(isPresented: $showManageRecurring) {
            ManageRecurringTasksView(viewModel: taskViewModel)
        }
        .sheet(isPresented: $showingProgressHistory) {
            ReflectionHistoryView(taskViewModel: taskViewModel)
        }
        .sheet(isPresented: $showingStreakView) {
            StreakView(viewModel: taskViewModel, streak: calendarViewModel.streak)
        }
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            let threshold: CGFloat = 200
            if offset < -threshold {
                currentDayPosition = .above
                showScrollToToday = true
            } else if offset > threshold {
                currentDayPosition = .below
                showScrollToToday = true
            } else {
                showScrollToToday = false
            }
        }
        .onChange(of: taskViewModel.tasks) { _, _ in
            calendarViewModel.checkAndUpdateStreak()
        }
    }
}

// Keep these helper types in CalendarView.swift
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum ScrollPosition {
    case above
    case below
    case visible
}

// Keep MonthView and DayCell here as they are specific to CalendarView
// ... rest of the MonthView and DayCell implementations ...

struct MonthView: View {
    let date: Date
    @Binding var selectedDate: Date
    let taskViewModel: TaskListViewModel
    @Binding var showingTaskList: Bool
    
    private let calendar = Calendar.current
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(date.formatted(.dateTime.year().month(.wide)))
                .font(.title2.bold())
                .padding(.leading, 4)
            
            // Updated weekday labels
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days grid with Monday start
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(daysInMonth().enumerated()), id: \.1) { _, date in
                    if let date = date {
                        let isFutureDate = calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
                        
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            completionStatus: getCompletionStatus(for: date),
                            isFutureDate: isFutureDate
                        )
                        .id(calendar.isDateInToday(date) ? 0 : nil)
                        .onTapGesture {
                            selectedDate = date
                            showingTaskList = true
                        }
                    } else {
                        Color.clear
                    }
                }
            }
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
        
        // Pad to complete the last week
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
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let completionStatus: DayCompletionStatus
    let isFutureDate: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .overlay(
                    Circle()
                        .strokeBorder(isToday ? .blue : .clear, lineWidth: 2)
                )
            
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isFutureDate ? .secondary : .primary)
                
                if !isFutureDate {
                    completionIndicator
                }
            }
        }
        .opacity(isFutureDate ? 0.5 : 1.0)
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var backgroundColor: Color {
        if isFutureDate {
            return .clear
        }
        if isSelected {
            return .blue.opacity(0.3)
        }
        switch completionStatus {
        case .full:
            return .green.opacity(0.3)
        case .partial:
            return .yellow.opacity(0.3)
        case .none:
            return .clear
        }
    }
    
    private var completionIndicator: some View {
        Group {
            switch completionStatus {
            case .full:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.system(size: 8))
            case .partial:
                Image(systemName: "circle.bottomhalf.filled")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 8))
            case .none:
                EmptyView()
            }
        }
    }
}

// Add this extension to get the status bar height
extension UIApplication {
    var statusBarFrame: CGRect {
        if let windowScene = connectedScenes.first as? UIWindowScene {
            return windowScene.statusBarManager?.statusBarFrame ?? .zero
        }
        return .zero
    }
}

#Preview {
    CalendarView(taskViewModel: TaskListViewModel())
} 
