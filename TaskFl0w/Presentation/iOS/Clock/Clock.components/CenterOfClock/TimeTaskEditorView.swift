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

    @ObservedObject private var themeManager = ThemeManager.shared
    
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

            // Внутренний круг с эффектом стекла
            Circle()
                .fill(.ultraThinMaterial)
                .blur(radius: 0.5)
                .overlay(
                    Circle()
                        .stroke(
                            .linearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(width: 170, height: 170)

            if let task = viewModel.editingTask {
                VStack(spacing: 20) {
                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .labelsHidden()
                        .colorScheme(colorScheme)
                        .scaleEffect(1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.gray.opacity(0.3), .gray.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .onChange(of: startTime) { oldValue, newValue in
                            guard !isInternalUpdate else { return }
                            viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                                task, newStartTime: newValue)
                        }
                        .shadow(color: .black.opacity(0.9), radius: 10, x: 0, y: 0)

                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .labelsHidden()
                        .colorScheme(colorScheme)
                        .scaleEffect(1)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [.gray.opacity(0.3), .gray.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .onChange(of: endTime) { oldValue, newValue in
                            guard !isInternalUpdate else { return }
                            viewModel.taskManagement.updateTaskDuration(task, newEndTime: newValue)
                        }
                        .shadow(color: .black.opacity(0.9), radius: 10, x: 0, y: 0)
                }
                .padding()
            }
        }
        .transition(.opacity)
        .onChange(of: viewModel.previewTime) { oldValue, newValue in
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
        .onChange(of: viewModel.editingTask) { oldValue, newTask in
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
