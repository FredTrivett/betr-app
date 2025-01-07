import SwiftUI

struct TaskListView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TaskListViewModel
    @StateObject private var reflectionViewModel = ReflectionHistoryViewModel()
    let selectedDate: Date
    @State private var showingAddTask = false
    @State private var showManageRecurring = false
    @State private var showingReflection = false
    @State private var showingIgnoredTasks = false
    @State private var selectedTaskToEdit: Task? = nil
    
    private var sortedTasks: (recurring: [Task], nonRecurring: [Task]) {
        let available = viewModel.tasks.filter { task in
            task.isAvailableForDate(selectedDate)
        }
        return (
            recurring: available.filter { $0.isRecurring },
            nonRecurring: available.filter { !$0.isRecurring }
        )
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var isFutureDate: Bool {
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    private var isYesterday: Bool {
        Calendar.current.isDateInYesterday(selectedDate)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            VStack(spacing: 16) {
                // Date and Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(isToday ? "Today's Tasks" : isFutureDate ? "Future Tasks" : "Tasks")
                        .font(.title.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                if sortedTasks.recurring.isEmpty && sortedTasks.nonRecurring.isEmpty {
                    Button {
                        showingAddTask = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                            Text("Add New Task")
                                .font(.body)
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(isFutureDate ? "Plan ahead by adding tasks" : "No tasks for this day")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        // Recurring Tasks Section
                        if !sortedTasks.recurring.isEmpty || hasIgnoredTasks {
                            Section {
                                ForEach(sortedTasks.recurring) { task in
                                    TaskRow(
                                        task: task,
                                        onToggle: {
                                            viewModel.toggleTaskCompletion(task, for: selectedDate)
                                        },
                                        selectedDate: selectedDate,
                                        onConfetti: {}
                                    )
                                    .padding(.vertical, 8)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button {
                                            viewModel.ignoreTaskForDay(task, on: selectedDate)
                                        } label: {
                                            Label("Ignore", systemImage: "")
                                        }
                                        .tint(.orange)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.moveTaskToNextDay(task, from: selectedDate)
                                        } label: {
                                            Label("Tomorrow", systemImage: "arrow.right")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text("Recurring Tasks")
                                    Spacer()
                                    if hasIgnoredTasks {
                                        Button("Show Ignored") {
                                            showingIgnoredTasks = true
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .listSectionSpacing(.compact)
                        }
                        
                        // Non-recurring Tasks Section
                        if !sortedTasks.nonRecurring.isEmpty {
                            Section(header: Text("One-time Tasks")) {
                                ForEach(sortedTasks.nonRecurring) { task in
                                    TaskRow(
                                        task: task,
                                        onToggle: {
                                            viewModel.toggleTaskCompletion(task, for: selectedDate)
                                        },
                                        selectedDate: selectedDate,
                                        onConfetti: {}
                                    )
                                    .padding(.vertical, 6)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            viewModel.deleteTask(task, for: selectedDate)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        
                                        Button {
                                            selectedTaskToEdit = task
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(.blue)
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            viewModel.moveTaskToNextDay(task, from: selectedDate)
                                        } label: {
                                            Label("Tomorrow", systemImage: "arrow.right")
                                        }
                                        .tint(.blue)
                                    }
                                }
                            }
                            .listSectionSpacing(.compact)
                        }
                        
                        // Add Task Button Section at the bottom of the list
                        Section {
                            Button {
                                showingAddTask = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text("Add New Task")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            
            // Reflection Button at bottom
            if isToday || isYesterday {
                Button {
                    showingReflection = true
                } label: {
                    if let reflection = isToday ? reflectionViewModel.todayReflection : reflectionViewModel.getReflection(for: selectedDate) {
                        VStack(alignment: .leading) {
                            Text("Your Reflection")
                                .font(.headline)
                                .padding(.top, 24)
                            HStack {
                                Image(systemName: reflection.rating.icon)
                                    .foregroundStyle(reflection.rating.color)
                                Text("You did")
                                    .foregroundStyle(.secondary)
                                Text(reflection.rating.rawValue)
                                    .foregroundStyle(reflection.rating.color)
                                    .bold()
                                Text(isToday ? "than yesterday" : "than the day before")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 6)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    } else {
                        Text(isToday ? "Reflect on Today" : "Reflect on Yesterday")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .onChange(of: showingReflection) { _, isShowing in
                    if !isShowing {
                        // Reload reflections immediately
                        DispatchQueue.main.async {
                            reflectionViewModel.loadReflections()
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showManageRecurring = true
                } label: {
                    Image(systemName: "repeat")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel, selectedDate: selectedDate, showToggle: true)
        }
        .sheet(isPresented: $showManageRecurring) {
            ManageRecurringTasksView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingReflection) {
            BetterThanYesterdayView(viewModel: viewModel, selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingIgnoredTasks) {
            IgnoredTasksView(
                viewModel: viewModel,
                date: selectedDate
            )
        }
        .sheet(item: $selectedTaskToEdit) { task in
            EditTaskView(
                viewModel: viewModel,
                task: task
            )
        }
    }
    
    private var hasIgnoredTasks: Bool {
        viewModel.hasIgnoredTasksForDate(selectedDate)
    }
}

#Preview {
    NavigationStack {
        TaskListView(
            viewModel: TaskListViewModel(),
            selectedDate: Date()
        )
    }
} 