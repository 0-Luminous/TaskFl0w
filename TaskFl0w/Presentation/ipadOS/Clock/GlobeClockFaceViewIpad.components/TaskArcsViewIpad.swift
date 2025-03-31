//
//  MainTaskArcsView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct TaskArcsViewIpad: View {
    let tasks: [TaskOnRing]
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        ForEach(tasks) { task in
            ClockTaskArcIpad(task: task, viewModel: viewModel)
        }
    }
}
