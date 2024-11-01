//
//  betrApp.swift
//  betr
//
//  Created by Fred Trivett on 01/11/2024.
//

import SwiftUI

@main
struct betrApp: App {
    @StateObject private var taskViewModel = TaskListViewModel()
    
    var body: some Scene {
        WindowGroup {
            CalendarView(taskViewModel: taskViewModel)
                .environmentObject(taskViewModel)
        }
    }
}
