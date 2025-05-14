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
        if !isVisible {
            EmptyView()
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let (startAngle, endAngle) = RingTimeCalculator.calculateAngles(for: task)
                let midAngle = RingTimeCalculator.calculateMidAngle(start: startAngle, end: endAngle)
                
                // Вычисляем коэффициент масштаба для коротких задач (менее часа)
                let taskDurationMinutes = task.duration / 60
                let isShortTask = taskDurationMinutes < 60
                let shortTaskScale: CGFloat = isShortTask ? max(0.6, taskDurationMinutes / 60) : 1.0
                
                // Базовый размер иконки с учетом масштаба для коротких задач
                let baseIconSize: CGFloat = 22
                let iconSize: CGFloat = baseIconSize * shortTaskScale
                
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

                let minIconFontSize: CGFloat = 11
                let maxIconFontSize: CGFloat = 19
                let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
                // Размер шрифта иконки с учетом короткой задачи
                let baseIconFontSize: CGFloat = isAnalog
                    ? minIconFontSize + (maxIconFontSize - minIconFontSize) * t
                    : minIconFontSize
                let iconFontSize: CGFloat = baseIconFontSize * shortTaskScale
                
                // Определение размера и отступа для текста времени
                let timeFontSize: CGFloat = 10 * shortTaskScale
                // Смещение текста внутрь циферблата
                let timeTextOffset: CGFloat = -8

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
                        createDragHandle(
                            color: task.category.color,
                            center: center,
                            radius: radius,
                            angle: startAngle,
                            isDraggingStart: true,
                            adjustTask: adjustTaskStartTimesForOverlap,
                            analogOffset: analogOffset,
                            shortTaskScale: shortTaskScale
                        )

                        // Маркер конца
                        createDragHandle(
                            color: task.category.color,
                            center: center,
                            radius: radius,
                            angle: endAngle,
                            isDraggingStart: false,
                            adjustTask: adjustTaskEndTimesForOverlap,
                            analogOffset: analogOffset,
                            shortTaskScale: shortTaskScale
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
                                    viewModel.taskManager.updateTaskStartTime(
                                        task, newStartTime: newTime)
                                }
                                .onEnded { _ in
                                    viewModel.isDraggingStart = false
                                    viewModel.previewTime = nil
                                }
                        )

                            ZStack {
                                // Фон в виде капсулы с фиксированной шириной, уменьшаем для коротких задач
                                Capsule()
                                    .fill(task.category.color)
                                    .frame(width: (CGFloat(startTimeText.count) * 6 + 6) * shortTaskScale, height: 16 * shortTaskScale)
                                
                                // Текст времени
                                Text(startTimeText)
                                    .font(.system(size: timeFontSize))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 1)
                            }
                            .rotationEffect(isStartInLeftHalf ? startAngle + .degrees(180) : startAngle)
                            .position(
                                x: center.x + (arcRadius + timeTextOffset) * cos(startAngle.radians),
                                y: center.y + (arcRadius + timeTextOffset) * sin(startAngle.radians)
                            )
                            
                            // Текст времени окончания задачи с корректной капсулой
                            ZStack {
                                // Фон в виде капсулы с фиксированной шириной, уменьшаем для коротких задач
                                Capsule()
                                    .fill(task.category.color)
                                    .frame(width: (CGFloat(endTimeText.count) * 6 + 6) * shortTaskScale, height: 16 * shortTaskScale)
                                
                                // Текст времени
                                Text(endTimeText)
                                    .font(.system(size: timeFontSize))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 1)
                            }
                            .rotationEffect(isEndInLeftHalf ? endAngle + .degrees(180) : endAngle)
                            .position(
                                x: center.x + (arcRadius + timeTextOffset) * cos(endAngle.radians),
                                y: center.y + (arcRadius + timeTextOffset) * sin(endAngle.radians)
                            )
                        }
                    }
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
        analogOffset: CGFloat,
        shortTaskScale: CGFloat
    ) -> some View {
        let minOuterRingWidth: CGFloat = 20
        let maxOuterRingWidth: CGFloat = 38
        let minHandleSize: CGFloat = 24
        let maxHandleSize: CGFloat = 36

        // Интерполяция размера маркера
        let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        // Базовый размер маркера с учетом масштаба для коротких задач
        let baseHandleSize: CGFloat = viewModel.isAnalogArcStyle
            ? minHandleSize + (maxHandleSize - minHandleSize) * t
            : minHandleSize
        let handleSize: CGFloat = baseHandleSize * shortTaskScale

        let arcRadius: CGFloat = viewModel.isAnalogArcStyle
            ? radius + (viewModel.outerRingLineWidth / 2) + analogOffset
            : radius + arcLineWidth / 2

        let handleRadius: CGFloat = viewModel.isAnalogArcStyle
            ? arcRadius
            : radius + arcLineWidth / 2

        Circle()
            .fill(color)
            .frame(width: handleSize, height: handleSize)
            .overlay(Circle().stroke(Color.gray, lineWidth: 2 * shortTaskScale))
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
                                    viewModel.taskManager.updateTaskEndTime(
                                        task, newEndTime: newTime)
                                }
                                .onEnded { _ in
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
            }
        }
    }
}
