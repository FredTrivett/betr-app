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
    @State private var selectedDate: Date?
    @State private var path = NavigationPath()
    
    init(taskViewModel: TaskListViewModel) {
        self._calendarViewModel = StateObject(wrappedValue: CalendarViewModel(taskViewModel: taskViewModel))
        self.taskViewModel = taskViewModel
    }
    
    private var monthsToShow: (past: Int, future: Int) {
        let calendar = Calendar.current
        let pastMonths = abs(calendar.dateComponents([.month], from: AppSettings.installationDate, to: Date()).month ?? 0) + 1
        return (past: pastMonths, future: 12)
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                // Status bar background
                statusBarBackground
                
                ZStack(alignment: .bottom) {
                    // Calendar content
                    calendarContent
                    
                    // Top bar
                    VStack {
                        CalendarTopBar(
                            streak: calendarViewModel.streak,
                            onStreakTap: { showingStreakView = true },
                            onProgressTap: { showingProgressHistory = true },
                            onManageRecurringTap: { showManageRecurring = true }
                        )
                        Spacer()
                    }
                    
                    // Bottom content
                    bottomContent
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Date.self) { date in
                TaskListView(viewModel: taskViewModel, selectedDate: date)
            }
        }
        .onChange(of: selectedDate) { _, newDate in
            if let date = newDate {
                path.append(date)
            }
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
        .onPreferenceChange(ScrollOffsetPreferenceKey.self, perform: handleScrollOffset)
        .onChange(of: taskViewModel.tasks) { _, _ in
            calendarViewModel.checkAndUpdateStreak()
        }
    }
    
    private var statusBarBackground: some View {
        GeometryReader { geometry in
            Color(uiColor: .systemBackground)
                .frame(height: geometry.safeAreaInsets.top)
                .ignoresSafeArea()
                .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    
    private var calendarContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                calendarMonths(proxy: proxy)
            }
            .coordinateSpace(name: "scroll")
            .onAppear {
                scrollProxy = proxy
                withAnimation {
                    proxy.scrollTo(0, anchor: .center)
                }
            }
        }
    }
    
    private func calendarMonths(proxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 32) {
            Color.clear.frame(height: 20)
            
            ForEach(-monthsToShow.past...monthsToShow.future, id: \.self) { monthOffset in
                MonthView(
                    date: Calendar.current.date(
                        byAdding: .month,
                        value: monthOffset,
                        to: Date()
                    ) ?? Date(),
                    selectedDate: $selectedDate,
                    taskViewModel: taskViewModel,
                    showingTaskList: $showingTaskList
                )
                .id(monthOffset)
                .background(scrollOffsetDetector)
            }
            .padding(.horizontal)
        }
        .padding(.top, 70)
        .padding(.bottom, 100)
    }
    
    private var scrollOffsetDetector: some View {
        GeometryReader { geometry in
            Color.clear.preference(
                key: ScrollOffsetPreferenceKey.self,
                value: geometry.frame(in: .named("scroll")).minY
            )
        }
    }
    
    private var bottomContent: some View {
        VStack {
            ProgressComparisonView(viewModel: taskViewModel)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            if showScrollToToday {
                scrollToTodayButton
            }
        }
    }
    
    private var scrollToTodayButton: some View {
        VStack {
            Spacer()
            Button(action: scrollToToday) {
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
    
    private func handleScrollOffset(_ offset: CGFloat) {
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
    
    private func scrollToToday() {
        withAnimation {
            scrollProxy?.scrollTo(0, anchor: .center)
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

// Keep the UIApplication extension
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
