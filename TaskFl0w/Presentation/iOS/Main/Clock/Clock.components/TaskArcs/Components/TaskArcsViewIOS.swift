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
    let arcLineWidth: CGFloat

    var body: some View {
        ZStack {
            ForEach(tasks) { task in
                ClockTaskArcIOS(task: task, viewModel: viewModel, arcLineWidth: arcLineWidth)
            }
        }
        .rotationEffect(.degrees(viewModel.zeroPosition))
    }
}
