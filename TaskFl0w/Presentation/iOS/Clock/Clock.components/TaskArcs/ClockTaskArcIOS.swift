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
    
    // Форматтер для отображения времени
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

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
                    
                    // Если текущая задача в режиме редактирования — показываем маркеры (после иконки, чтобы они были выше по Z-порядку)
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
                    
                    // Добавляем отображение времени начала задачи только для цифрового стиля
                    // Скрываем цифры, когда активны маркеры редактирования
                    // или когда задача не активна и включена опция "Время только у активной задачи"
                    if !isAnalog && 
                       !(viewModel.isEditingMode && task.id == viewModel.editingTask?.id) {
                        // Проверяем, является ли задача текущей по времени или выбранной пользователем
                        let now = Date()
                        let isActiveTask = (task.startTime <= now && task.endTime > now) || viewModel.editingTask?.id == task.id
                        
                        // Показываем время, если мы не в режиме "только для активной задачи" 
                        // или если мы в этом режиме и задача активна
                        if !viewModel.showTimeOnlyForActiveTask || (viewModel.showTimeOnlyForActiveTask && isActiveTask) {
                            // Проверяем, находится ли текст в левой части циферблата
                            let isStartInLeftHalf = isAngleInLeftHalf(startAngle)
                            let isEndInLeftHalf = isAngleInLeftHalf(endAngle)
                            
                            // Текст времени начала задачи с корректной капсулой
                            let startTimeText = timeFormatter.string(from: task.startTime)
                            let endTimeText = timeFormatter.string(from: task.endTime)

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

        // Определяем разные радиусы для маркеров начала и конца
        // Смещаем маркеры только для коротких задач (когда shortTaskScale < 1.0)
        let isSmallTask = shortTaskScale < 1.0
        let startHandleOffset: CGFloat = (isDraggingStart && isSmallTask) ? -4 * (1.0 - shortTaskScale) * 2 : 0
        let endHandleOffset: CGFloat = (!isDraggingStart && isSmallTask) ? 4 * (1.0 - shortTaskScale) * 2 : 0
        
        let handleRadius: CGFloat = viewModel.isAnalogArcStyle
            ? arcRadius + (isDraggingStart ? startHandleOffset : endHandleOffset)
            : radius + arcLineWidth / 2 + (isDraggingStart ? startHandleOffset : endHandleOffset)

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
                        
                        // Вычисляем вектор от центра к точке перетаскивания
                        let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
                        
                        // Рассчитываем угол в радианах от центра к текущей позиции
                        let angle = atan2(vector.dy, vector.dx)
                        
                        // Конвертируем в градусы
                        var degrees = angle * 180 / .pi
                        
                        // Нормализуем значение от 0 до 360 градусов (0 градусов - это направление вправо)
                        degrees = (degrees + 360).truncatingRemainder(dividingBy: 360)
                        
                        // Корректируем с учетом zeroPosition, где 270 градусов - 12 часов (верх циферблата)
                        let adjustedDegrees = (degrees - 270 - viewModel.zeroPosition + 360).truncatingRemainder(dividingBy: 360)
                        
                        // Вычисляем часы и минуты из градусов
                        // 360 градусов соответствуют 24 часам
                        let hours = adjustedDegrees / 15 // 15 градусов = 1 час
                        let hourComponent = Int(hours)
                        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
                        
                        // Используем компоненты из выбранной даты
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                        components.hour = hourComponent
                        components.minute = minuteComponent
                        components.timeZone = TimeZone.current
                        
                        if let newTime = Calendar.current.date(from: components) {
                            // Проверка минимальной длительности (20 минут)
                            let minimumDuration: TimeInterval = 20 * 60
                            
                            if isDraggingStart {
                                if task.endTime.timeIntervalSince(newTime) >= minimumDuration {
                                    viewModel.previewTime = newTime
                                    adjustTask(task, newTime)
                                } else {
                                    // Если минимальная длительность не соблюдается, устанавливаем ограничение
                                    let limitedStartTime = task.endTime.addingTimeInterval(-minimumDuration)
                                    viewModel.previewTime = limitedStartTime
                                    adjustTask(task, limitedStartTime)
                                }
                            } else {
                                if newTime.timeIntervalSince(task.startTime) >= minimumDuration {
                                    viewModel.previewTime = newTime
                                    adjustTask(task, newTime)
                                } else {
                                    // Если минимальная длительность не соблюдается, устанавливаем ограничение
                                    let limitedEndTime = task.startTime.addingTimeInterval(minimumDuration)
                                    viewModel.previewTime = limitedEndTime
                                    adjustTask(task, limitedEndTime)
                                }
                            }
                        }
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
        // Обновляем задачу с новым временем начала
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
            currentTask, newStartTime: newStartTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.startTime >= otherTask.startTime
                && updatedTask.startTime < otherTask.endTime
            {
                // Проверяем, не нарушит ли это минимальную длительность для другой задачи
                let minimumDuration: TimeInterval = 20 * 60
                if updatedTask.startTime.timeIntervalSince(otherTask.startTime) >= minimumDuration {
                    // Для другой задачи остаётся достаточно времени
                    viewModel.taskManagement.updateTaskDuration(
                        otherTask, newEndTime: updatedTask.startTime)
                } else {
                    // В этом случае не корректируем другую задачу,
                    // а возвращаем нашу задачу после окончания другой
                    let safeStartTime = otherTask.endTime
                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                        updatedTask, newStartTime: safeStartTime)
                }
            }
        }
    }

    func adjustTaskEndTimesForOverlap(_ currentTask: TaskOnRing, newEndTime: Date) {
        // Обновляем задачу с новым временем окончания
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime
            {
                // Проверяем, не нарушит ли это минимальную длительность для другой задачи
                let minimumDuration: TimeInterval = 20 * 60
                if otherTask.endTime.timeIntervalSince(updatedTask.endTime) >= minimumDuration {
                    // Для другой задачи остаётся достаточно времени
                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(
                        otherTask, newStartTime: updatedTask.endTime)
                } else {
                    // В этом случае не корректируем другую задачу,
                    // а возвращаем нашу задачу перед началом другой
                    let safeEndTime = otherTask.startTime
                    viewModel.taskManagement.updateTaskDuration(
                        updatedTask, newEndTime: safeEndTime)
                }
            }
        }
    }

    // Проверяет, находится ли угол в левой половине циферблата
    private func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        // Преобразуем угол в градусы в диапазоне 0-360
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        // Левая половина циферблата: 90-270 градусов
        return degrees > 90 && degrees < 270
    }
}
