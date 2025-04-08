//
//  TimeTaskEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//

import SwiftUI

struct TimeTaskEditorOverlay: View {
    @ObservedObject var viewModel: ClockViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isInternalUpdate = false
    
    init(viewModel: ClockViewModel, task: TaskOnRing) {
        self.viewModel = viewModel
        
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

            // Внутренний круг
            Circle()
                .fill(
                    colorScheme == .dark
                        ? Color(red: 0.192, green: 0.192, blue: 0.192)
                        : Color(red: 0.933, green: 0.933, blue: 0.933)
                )
                .frame(width: 170, height: 170)

            if let task = viewModel.editingTask {
                VStack(spacing: 20) {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(colorScheme)
                        .scaleEffect(1)
                        .onChange(of: startTime) { newValue in
                            guard !isInternalUpdate else { return }
                            viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                                task, newStartTime: newValue)
                        }

                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(colorScheme)
                        .scaleEffect(1)
                        .onChange(of: endTime) { newValue in
                            guard !isInternalUpdate else { return }
                            viewModel.taskManagement.updateTaskDuration(task, newEndTime: newValue)
                        }
                }
                .padding()
            }
        }
        .transition(.opacity)
        .onChange(of: viewModel.previewTime) { newValue in
            if let previewTime = newValue {
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
        .onChange(of: viewModel.editingTask) { newTask in
            if let newTask = newTask {
                // Обновляем времена при смене задачи
                isInternalUpdate = true
                startTime = newTask.startTime
                endTime = newTask.startTime.addingTimeInterval(newTask.duration)
                isInternalUpdate = false
            }
        }
    }
}
