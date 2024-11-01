//
//  ContentView.swift
//  betr
//
//  Created by Fred Trivett on 01/11/2024.
//

import SwiftUI
import ConfettiSwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @State private var isAddingTask = false
    @State private var selectedDate: Date = Date()
    @State private var showConfetti = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskRow(
                            task: task,
                            onToggle: {
                                viewModel.toggleTaskCompletion(task, for: selectedDate)
                            },
                            selectedDate: selectedDate,
                            onConfetti: {
                                showConfetti += 1
                            }
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteTask(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                
                ConfettiCannon(
                    counter: $showConfetti,
                    num: 75,
                    openingAngle: Angle(degrees: 0),
                    closingAngle: Angle(degrees: 360),
                    radius: 300,
                    repetitions: 1,
                    repetitionInterval: 0.05
                )
                .position(x: UIScreen.main.bounds.width / 2, y: -100)
                .allowsHitTesting(false)
                .zIndex(.infinity)
            }
            .navigationTitle("Daily Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingTask) {
                AddTaskView(viewModel: viewModel, selectedDate: selectedDate)
            }
        }
    }
}

#Preview {
    ContentView(viewModel: TaskListViewModel())
}
