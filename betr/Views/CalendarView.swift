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
