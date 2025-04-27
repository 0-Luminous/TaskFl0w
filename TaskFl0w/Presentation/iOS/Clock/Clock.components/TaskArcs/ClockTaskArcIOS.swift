import SwiftUI

//
//  ClockTaskArcIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

struct ClockTaskArcIOS: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let arcLineWidth: CGFloat

    @State private var isDragging: Bool = false
    @State private var isVisible: Bool = true

    var body: some View {
        if !isVisible {
            EmptyView()
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let (startAngle, endAngle) = RingTimeCalculator.calculateAngles(for: task)
                let midAngle = RingTimeCalculator.calculateMidAngle(
                    start: startAngle, end: endAngle)

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
                    .stroke(task.category.color, lineWidth: arcLineWidth)
                    .contentShape(
                        Path { path in
                            path.addArc(
                                center: center,
                                radius: radius + 30,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: false
                            )
                            path.addArc(
                                center: center,
                                radius: radius - 40,
                                startAngle: endAngle,
                                endAngle: startAngle,
                                clockwise: true
                            )
                            path.closeSubpath()
                        }
                    )
                    .contentShape(.dragPreview, Circle().scale(1.2))
                    .gesture(
                        TapGesture()
                            .onEnded {
                                withAnimation {
                                    if viewModel.isEditingMode, viewModel.editingTask?.id == task.id
                                    {
                                        viewModel.isEditingMode = false
                                        viewModel.editingTask = nil
                                    } else {
                                        viewModel.isEditingMode = true
                                        viewModel.editingTask = task
                                    }
                                }
                            }
                    )
                    .onDrag {
                        if !viewModel.isEditingMode && viewModel.editingTask == nil && !isDragging {
                            print("onDrag: начало перетаскивания \(task.category.rawValue)")

                            // Начинаем перетаскивание
                            viewModel.startDragging(task)
                            isDragging = true
                            return NSItemProvider(object: task.id.uuidString as NSString)
                        }
                        return NSItemProvider()
                    } preview: {
                        CategoryDragPreview(task: task)
                            .onAppear {
                                print("preview: \(task.category.rawValue)")
                            }
                    }

                    // Если текущая задача в режиме редактирования — показываем маркеры
                    if viewModel.isEditingMode && task.id == viewModel.editingTask?.id {
                        // Маркер начала
                        createDragHandle(
                            color: task.category.color,
                            center: center,
                            radius: radius,
                            angle: startAngle,
                            isDraggingStart: true,
                            adjustTask: adjustTaskStartTimesForOverlap
                        )

                        // Маркер конца
                        createDragHandle(
                            color: task.category.color,
                            center: center,
                            radius: radius,
                            angle: endAngle,
                            isDraggingStart: false,
                            adjustTask: adjustTaskEndTimesForOverlap
                        )
                    }

                    // Иконка категории на середине дуги
                    Image(systemName: task.category.iconName)
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .background(
                            Circle()
                                .fill(task.category.color)
                                .frame(width: 20, height: 20)
                        )
                        .position(
                            x: center.x + (radius + 20) * cos(midAngle.radians),
                            y: center.y + (radius + 20) * sin(midAngle.radians)
                        )
                        .id("task-icon-\(task.id)-\(viewModel.zeroPosition)")
                }
            }
            .onChange(of: isDragging) { oldValue, newValue in
                if oldValue == newValue { return }

                if newValue && task.id == viewModel.draggedTask?.id && isVisible {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Добавляем проверку на то, что задача находится за пределами циферблата
                        if isDragging && viewModel.draggedTask?.id == task.id && isVisible
                            && viewModel.isDraggingOutside
                        {
                            viewModel.taskManagement.removeTask(task)
                            isVisible = false
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func createDragHandle(
        color: Color,
        center: CGPoint,
        radius: CGFloat,
        angle: Angle,
        isDraggingStart: Bool,
        adjustTask: @escaping (TaskOnRing, Date) -> Void
    ) -> some View {
        Circle()
            .fill(color)
            .frame(width: 24, height: 24)
            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            .position(
                x: center.x + (radius + 10) * cos(angle.radians),
                y: center.y + (radius + 10) * sin(angle.radians)
            )
            .animation(.none, value: angle)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if isDraggingStart {
                            viewModel.isDraggingStart = true
                        } else {
                            viewModel.isDraggingEnd = true
                        }

                        let newTime = viewModel.clockState.timeForLocation(
                            value.location,
                            screenWidth: UIScreen.main.bounds.width
                        )
                        viewModel.previewTime = newTime
                        adjustTask(task, newTime)
                    }
                    .onEnded { _ in
                        if let updatedTask = viewModel.editingTask,
                            let actualTask = viewModel.tasks.first(where: {
                                $0.id == updatedTask.id
                            })
                        {
                            viewModel.editingTask = actualTask
                        }

                        if isDraggingStart {
                            viewModel.isDraggingStart = false
                        } else {
                            viewModel.isDraggingEnd = false
                        }
                        viewModel.previewTime = nil
                    }
            )
    }

    func adjustTaskStartTimesForOverlap(_ currentTask: TaskOnRing, newStartTime: Date) {
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
            currentTask, newStartTime: newStartTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.startTime >= otherTask.startTime
                && updatedTask.startTime < otherTask.endTime
            {
                viewModel.taskManagement.updateTaskDuration(
                    otherTask, newEndTime: updatedTask.startTime)
            }
        }
    }

    func adjustTaskEndTimesForOverlap(_ currentTask: TaskOnRing, newEndTime: Date) {
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime
            {
                viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                    otherTask, newStartTime: updatedTask.endTime)
            }
        }
    }

}
