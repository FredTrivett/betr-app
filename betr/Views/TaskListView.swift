import SwiftUI
import ConfettiSwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @Environment(\.dismiss) private var dismiss
    let selectedDate: Date
    @State private var isAddingTask = false
    @State private var showingComparison = false
    @State private var taskToEdit: Task? = nil
    @State private var confettiCounter = 0
    @State private var isConfettiActive = false
    @State private var confettiOpacity = 0.0
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var isFutureDate: Bool {
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    var availableTasks: [Task] {
        viewModel.tasks.filter { task in
            task.isAvailableForDate(selectedDate)
        }
    }
    
    var sortedTasks: [Task] {
        availableTasks.sorted { task1, task2 in
            if task1.isRecurring == task2.isRecurring {
                return task1.title < task2.title // Alphabetical within groups
            }
            return task1.isRecurring && !task2.isRecurring // Recurring tasks first
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                ZStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Date and Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(isToday ? "Today's Tasks" : isFutureDate ? "Future Tasks" : "Tasks")
                                .font(.title.bold())
                        }
                        .padding(.horizontal)
                        
                        if availableTasks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checklist")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text(isFutureDate ? "Plan ahead by adding tasks" : "No tasks for this day")
                                    .foregroundStyle(.secondary)
                                Button("Add Task") {
                                    isAddingTask = true
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(sortedTasks) { task in
                                    TaskRow(
                                        task: task,
                                        onToggle: {
                                            viewModel.toggleTaskCompletion(task, for: selectedDate)
                                        },
                                        selectedDate: selectedDate,
                                        onConfetti: {
                                            triggerConfetti()
                                        }
                                    )
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.deleteTask(task, for: task.isRecurring ? selectedDate : nil)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            taskToEdit = task
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                            .listStyle(.inset)
                        }
                    }
                    
                    if DayBoundary.canReflectOn(selectedDate) {
                        Button {
                            showingComparison = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("Did I get better?")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                    }
                }
                
                // Confetti layer
                ZStack {
                    if isConfettiActive {
                        ConfettiCannon(
                            counter: $confettiCounter,
                            num: 50,
                            openingAngle: Angle(degrees: 0),
                            closingAngle: Angle(degrees: 360),
                            radius: 200,
                            repetitions: 1,
                            repetitionInterval: 0.02
                        )
                        .position(x: UIScreen.main.bounds.width / 2, y: -100)
                        .opacity(confettiOpacity)
                        .animation(.easeOut(duration: 0.5), value: confettiOpacity)
                        .onAppear {
                            confettiOpacity = 1.0
                            scheduleConfettiCleanup()
                        }
                    }
                }
                .allowsHitTesting(false)
                .zIndex(.infinity)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingTask = true
                    } label: {
                        Text("Add Task")
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView(viewModel: viewModel, selectedDate: selectedDate)
        }
        .sheet(item: $taskToEdit) { task in
            if task.isRecurring {
                AddRecurringTaskView(viewModel: viewModel, taskToEdit: task)
            } else {
                AddTaskView(viewModel: viewModel, selectedDate: selectedDate, taskToEdit: task)
            }
        }
        .sheet(isPresented: $showingComparison) {
            BetterThanYesterdayView(viewModel: viewModel, selectedDate: selectedDate)
        }
    }
    
    private func triggerConfetti() {
        // Reset states for new animation
        isConfettiActive = true
        confettiOpacity = 0.0
        
        // Trigger new confetti
        DispatchQueue.main.async {
            confettiCounter += 1
        }
    }
    
    private func scheduleConfettiCleanup() {
        // Start fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation {
                confettiOpacity = 0.0
            }
            
            // Cleanup after fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isConfettiActive = false
            }
        }
    }
} 