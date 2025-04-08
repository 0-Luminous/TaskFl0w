//
//  TaskArcsViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct TaskArcsViewIOS: View {
    let tasks: [TaskOnRing]
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        ZStack {
            ForEach(tasks) { task in
                ClockTaskArcIOS(task: task, viewModel: viewModel)
            }
        }
        // Применяем вращение ко всем задачам сразу
        .rotationEffect(.degrees(viewModel.zeroPosition))
    }
}
