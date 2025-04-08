import Foundation
//
//  ClockTaskArcIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockTaskArcIOS: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2
            // Используем метод с учетом zeroPosition, чтобы задачи правильно отображались на циферблате
            // Важно: весь циферблат вращается в родительском компоненте, поэтому нам нужно 
            // рассчитать углы без учета zeroPosition для правильного расположения дуг
            let (startAngle, endAngle) = RingTimeCalculator.calculateAngles(for: task)

            ZStack {
                // Дуга задачи
                Path { path in
                    path.addArc(
                        center: center,
                        radius: radius + 10,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
                }
                .stroke(task.category.color, lineWidth: 20)
                .gesture(
                    TapGesture()
                        .onEnded {
                            withAnimation {
                                if viewModel.isEditingMode, viewModel.editingTask?.id == task.id {
                                    viewModel.isEditingMode = false
                                    viewModel.editingTask = nil
                                } else {
                                    viewModel.isEditingMode = true
                                    viewModel.editingTask = task
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if !viewModel.isEditingMode {
                                viewModel.selectedTask = task
                                viewModel.showingTaskDetail = true
                            }
                        }
                )

                // Если текущая задача в режиме редактирования — показываем маркеры
                if viewModel.isEditingMode && task.id == viewModel.editingTask?.id {
                    // Маркер начала
                    Circle()
                        .fill(task.category.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .position(
                            x: center.x + (radius + 10) * CGFloat(cos(startAngle.radians)),
                            y: center.y + (radius + 10) * CGFloat(sin(startAngle.radians))
                        )
                        .animation(.none, value: startAngle)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    viewModel.isDraggingStart = true
                                    let newTime = viewModel.clockState.timeForLocation(
                                        value.location,
                                        screenWidth: UIScreen.main.bounds.width
                                    )
                                    viewModel.previewTime = newTime
                                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                                        task, newStartTime: newTime)
                                }
                                .onEnded { _ in
                                    // Сохраняем обновленное время для редактируемой задачи
                                    if let updatedTask = viewModel.editingTask {
                                        // Найдем актуальную задачу в списке (она могла обновиться)
                                        if let actualTask = viewModel.tasks.first(where: { $0.id == updatedTask.id }) {
                                            viewModel.editingTask = actualTask
                                        }
                                    }
                                    viewModel.isDraggingStart = false
                                    viewModel.previewTime = nil
                                }
                        )

                    // Маркер конца
                    Circle()
                        .fill(task.category.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        .position(
                            x: center.x + (radius + 10) * CGFloat(cos(endAngle.radians)),
                            y: center.y + (radius + 10) * CGFloat(sin(endAngle.radians))
                        )
                        .animation(.none, value: endAngle)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    viewModel.isDraggingEnd = true
                                    let newTime = viewModel.clockState.timeForLocation(
                                        value.location,
                                        screenWidth: UIScreen.main.bounds.width
                                    )
                                    viewModel.previewTime = newTime
                                    viewModel.taskManagement.updateTaskDuration(
                                        task, newEndTime: newTime)
                                }
                                .onEnded { _ in
                                    // Сохраняем обновленное время для редактируемой задачи
                                    if let updatedTask = viewModel.editingTask {
                                        // Найдем актуальную задачу в списке (она могла обновиться)
                                        if let actualTask = viewModel.tasks.first(where: { $0.id == updatedTask.id }) {
                                            viewModel.editingTask = actualTask
                                        }
                                    }
                                    viewModel.isDraggingEnd = false
                                    viewModel.previewTime = nil
                                }
                        )
                }

                // Иконка категории на середине дуги
                let midAngle = RingTimeCalculator.calculateMidAngle(
                    start: startAngle, end: endAngle)
                Image(systemName: task.category.iconName)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(task.category.color)
                            .frame(width: 20, height: 20)
                    )
                    .position(
                        x: center.x + (radius + 20) * CGFloat(cos(midAngle.radians)),
                        y: center.y + (radius + 20) * CGFloat(sin(midAngle.radians))
                    )
                    // Добавляем идентификатор, чтобы заставить переотрисовываться при изменении zeroPosition
                    .id("task-icon-\(task.id)-\(viewModel.zeroPosition)")
            }
        }
    }
}
