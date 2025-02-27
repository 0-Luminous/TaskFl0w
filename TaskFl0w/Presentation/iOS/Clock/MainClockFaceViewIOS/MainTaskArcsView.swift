//
//  MainTaskArcsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct MainTaskArcsView: View {
    let tasks: [Task]
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        ForEach(tasks) { task in
            MainClockTaskArc(task: task, viewModel: viewModel)
        }
    }
}
