//
//  TimeTaskEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//

import SwiftUI

struct TimeTaskEditorOverlay: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isInternalUpdate = false
    let task: TaskOnRing

    init(viewModel: ClockViewModel, task: TaskOnRing) {
        self.viewModel = viewModel
        self.task = task

        // Используем прямое время без коррекции для отображения
        _startTime = State(initialValue: task.startTime)
        _endTime = State(initialValue: task.startTime.addingTimeInterval(task.duration))
    }

    var body: some View {
        ZStack {
            // Основной круг-подложка с серой окантовкой
            Circle()
                .stroke(Color(red: 0.655, green: 0.639, blue: 0.639), lineWidth: 2)
                .frame(width: 170, height: 170)

            // Внутренний темный круг
            Circle()
                .fill(Color(red: 0.192, green: 0.192, blue: 0.192))  // #313131
                .frame(width: 170, height: 170)

            VStack(spacing: 20) {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1)
                    .onChange(of: startTime) { newTime in
                        guard !isInternalUpdate else { return }
                        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                            task, newStartTime: newTime)
                    }

                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .scaleEffect(1)
                    .onChange(of: endTime) { newTime in
                        guard !isInternalUpdate else { return }
                        viewModel.taskManagement.updateTaskDuration(task, newEndTime: newTime)
                    }
            }
            .padding()
        }
        .transition(.opacity)
        .onChange(of: viewModel.previewTime) { newTime in
            if let previewTime = newTime {
                isInternalUpdate = true
                if viewModel.isDraggingStart {
                    startTime = previewTime
                }
                if viewModel.isDraggingEnd {
                    endTime = previewTime
                }
                isInternalUpdate = false
            }
        }
    }
}
