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
                let midAngle = RingTimeCalculator.calculateMidAngle(start: startAngle, end: endAngle)
                let iconSize: CGFloat = 20
                let isAnalog = viewModel.isAnalogArcStyle
                let minOuterRingWidth: CGFloat = 20
                let maxOuterRingWidth: CGFloat = 38
                let minOffset: CGFloat = 10
                let maxOffset: CGFloat = 0
                let tArcOffset = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
                let analogOffset = minOffset + (maxOffset - minOffset) * tArcOffset
                let arcRadius: CGFloat = isAnalog
                    ? radius + (viewModel.outerRingLineWidth / 2) + analogOffset
                    : radius + arcLineWidth / 2

                let minArcWidth: CGFloat = 20
                let maxArcWidth: CGFloat = 32
                let minIconOffset: CGFloat = 0

                // Для аналогового режима — иконка ближе к циферблату при min толщине кольца
                let minAnalogIconOffset: CGFloat = -16
                let maxAnalogIconOffset: CGFloat = -4
                let tRing = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
                let analogIconOffset = minAnalogIconOffset + (maxAnalogIconOffset - minAnalogIconOffset) * tRing

                let maxIconOffset: CGFloat = isAnalog ? analogIconOffset : 6

                let tIconOffset = (arcLineWidth - minArcWidth) / (maxArcWidth - minArcWidth)
                let iconOffset = minIconOffset + (maxIconOffset - minIconOffset) * tIconOffset
                let iconRadius: CGFloat = isAnalog
                    ? arcRadius
                    : arcRadius + iconSize / 2 + iconOffset

                let minIconFontSize: CGFloat = 12
                let maxIconFontSize: CGFloat = 19
                let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
                let iconFontSize: CGFloat = isAnalog
                    ? minIconFontSize + (maxIconFontSize - minIconFontSize) * t
                    : minIconFontSize

                ZStack {
                    // Дуга задачи
                    Path { path in
                        path.addArc(
                            center: center,
                            radius: arcRadius,
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
                            adjustTask: adjustTaskStartTimesForOverlap,
                            analogOffset: analogOffset
                        )

                        // Маркер конца
                        createDragHandle(
                            color: task.category.color,
                            center: center,
                            radius: radius,
                            angle: endAngle,
                            isDraggingStart: false,
                            adjustTask: adjustTaskEndTimesForOverlap,
                            analogOffset: analogOffset
                        )
                    }

                    // Иконка категории на середине дуги
                    Image(systemName: task.category.iconName)
                        .font(.system(size: iconFontSize))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                        .background(
                            Circle()
                                .fill(task.category.color)
                                .frame(width: iconSize, height: iconSize)
                        )
                        .position(
                            x: center.x + iconRadius * cos(midAngle.radians),
                            y: center.y + iconRadius * sin(midAngle.radians)
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
        adjustTask: @escaping (TaskOnRing, Date) -> Void,
        analogOffset: CGFloat
    ) -> some View {
        let minOuterRingWidth: CGFloat = 20
        let maxOuterRingWidth: CGFloat = 38
        let minHandleSize: CGFloat = 24
        let maxHandleSize: CGFloat = 36

        // Интерполяция размера маркера
        let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        let handleSize: CGFloat = viewModel.isAnalogArcStyle
            ? minHandleSize + (maxHandleSize - minHandleSize) * t
            : minHandleSize

        let arcRadius: CGFloat = viewModel.isAnalogArcStyle
            ? radius + (viewModel.outerRingLineWidth / 2) + analogOffset
            : radius + arcLineWidth / 2

        let handleRadius: CGFloat = viewModel.isAnalogArcStyle
            ? arcRadius
            : radius + arcLineWidth / 2

        Circle()
            .fill(color)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
            .position(
                x: center.x + handleRadius * cos(angle.radians),
                y: center.y + handleRadius * sin(angle.radians)
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
