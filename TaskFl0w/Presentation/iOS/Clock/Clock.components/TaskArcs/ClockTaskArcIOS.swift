import SwiftUI
import UIKit

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
    @State private var lastHourComponent: Int = -1
    
    // Кэшируем форматтер, чтобы не создавать его каждый раз
    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    // Вынесите константы на уровень структуры, а не внутрь body
    private let minOuterRingWidth: CGFloat = 20
    private let maxOuterRingWidth: CGFloat = 38
    private let minArcWidth: CGFloat = 20
    private let maxArcWidth: CGFloat = 32
    private let minOffset: CGFloat = 10
    private let maxOffset: CGFloat = 0
    private let minIconOffset: CGFloat = 0
    private let minAnalogIconOffset: CGFloat = -16
    private let maxAnalogIconOffset: CGFloat = -4
    private let baseIconSize: CGFloat = 20
    private let minIconFontSize: CGFloat = 10
    private let maxIconFontSize: CGFloat = 19
    private let timeFontSize: CGFloat = 10
    private let timeTextOffset: CGFloat = -8
    
    // Предварительные вычисления для избежания их повторения внутри body
    private var isAnalog: Bool { viewModel.isAnalogArcStyle }
    
    // Подготовка параметров для визуализации задачи - вынесено за пределы body
    private func prepareTaskVisualization(taskDurationMinutes: Double) -> (shortTaskScale: CGFloat, tArcOffset: CGFloat, tRing: CGFloat, tIconOffset: CGFloat) {
        // Коэффициент масштаба для коротких задач (менее часа)
        let isShortTask = taskDurationMinutes < 60
        let shortTaskScale: CGFloat = isShortTask ? max(0.6, taskDurationMinutes / 60) : 1.0
        
        // Расчеты для отступов
        let tArcOffset = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        let tRing = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        let tIconOffset = (arcLineWidth - minArcWidth) / (maxArcWidth - minArcWidth)
        
        return (shortTaskScale, tArcOffset, tRing, tIconOffset)
    }

    // Функция для выполнения виброотдачи
    private func triggerHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    // Функция для выполнения сильной виброотдачи для часовых делений
    private func triggerSelectionHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    // Функция для выполнения мягкой виброотдачи при перетаскивании
    private func triggerDragHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred(intensity: 0.5)
    }

    var body: some View {
        if !isVisible {
            EmptyView()
        } else {
            GeometryReader { geometry in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let (startAngle, endAngle) = RingTimeCalculator.calculateAngles(for: task)
                let midAngle = RingTimeCalculator.calculateMidAngle(start: startAngle, end: endAngle)
                
                let taskDurationMinutes = task.duration / 60
                let (shortTaskScale, tArcOffset, tRing, tIconOffset) = prepareTaskVisualization(taskDurationMinutes: taskDurationMinutes)
                
                // Размеры иконки с учетом масштаба для коротких задач
                let iconSize: CGFloat = baseIconSize * shortTaskScale
                
                // Отступы для аналогового режима
                let analogOffset = minOffset + (maxOffset - minOffset) * tArcOffset
                
                // Радиус дуги
                let arcRadius: CGFloat = isAnalog
                    ? radius + (viewModel.outerRingLineWidth / 2) + analogOffset
                    : radius + arcLineWidth / 2
                
                // Расчет смещения иконки
                let analogIconOffset = minAnalogIconOffset + (maxAnalogIconOffset - minAnalogIconOffset) * tRing
                let maxIconOffset: CGFloat = isAnalog ? analogIconOffset : 6
                let iconOffset = minIconOffset + (maxIconOffset - minIconOffset) * tIconOffset
                
                // Расчет радиуса для размещения иконки
                let iconRadius: CGFloat = isAnalog
                    ? arcRadius
                    : arcRadius + iconSize / 2 + iconOffset
                
                // Размер шрифта иконки с учетом короткой задачи
                let baseIconFontSize: CGFloat = isAnalog
                    ? minIconFontSize + (maxIconFontSize - minIconFontSize) * tRing
                    : minIconFontSize
                let iconFontSize: CGFloat = baseIconFontSize * shortTaskScale
                
                // Создаем только один Path для дуги задачи, используемый и для отрисовки, и для распознавания жестов
                let taskArcPath = Path { path in
                    path.addArc(
                        center: center,
                        radius: arcRadius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
                }
                
                // Контент-шейп для распознавания жестов
                let taskTapArea = Path { path in
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
                
                ZStack {
                    // Дуга задачи
                    taskArcPath
                        .stroke(task.category.color, lineWidth: arcLineWidth)
                        .contentShape(taskTapArea)
                        .contentShape(.dragPreview, Circle().scale(1.2))
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    // Добавляем виброотдачу при входе в режим редактирования
                                    triggerHapticFeedback()
                                    
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
                                // Начинаем перетаскивание
                                viewModel.startDragging(task)
                                isDragging = true
                                return NSItemProvider(object: task.id.uuidString as NSString)
                            }
                            return NSItemProvider()
                        } preview: {
                            CategoryDragPreview(task: task)
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
                        .scaleEffect(shortTaskScale)
                        .position(
                            x: center.x + iconRadius * cos(midAngle.radians),
                            y: center.y + iconRadius * sin(midAngle.radians)
                        )
                        .id("task-icon-\(task.id)-\(viewModel.zeroPosition)")
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    // Добавляем виброотдачу и для иконки
                                    triggerHapticFeedback()
                                    
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
                    
                    // Отображение времени (оптимизированное условие)
                    TaskTimeLabels(
                        task: task,
                        isAnalog: isAnalog, 
                        viewModel: viewModel,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        center: center,
                        arcRadius: arcRadius,
                        timeTextOffset: timeTextOffset,
                        shortTaskScale: shortTaskScale,
                        timeFormatter: timeFormatter
                    )
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
                        
                        // Виброотдача при начале перетаскивания
                        if lastHourComponent == -1 {
                            triggerDragHapticFeedback()
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
                        
                        // Проверяем, пересекли ли мы новое часовое деление
                        if hourComponent != lastHourComponent {
                            // Если это не первый вызов (-1) и если значение изменилось - делаем виброотдачу
                            if lastHourComponent != -1 {
                                triggerSelectionHapticFeedback()
                            }
                            lastHourComponent = hourComponent
                        }
                        
                        // Мягкая виброотдача при каждом значительном изменении минут (каждые 5 минут)
                        let currentMinuteBucket = minuteComponent / 5
                        if currentMinuteBucket != (minuteComponent - 1) / 5 && lastHourComponent != -1 {
                            triggerDragHapticFeedback()
                        }
                        
                        // Используем компоненты из выбранной даты
                        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
                        components.hour = hourComponent
                        components.minute = minuteComponent
                        components.timeZone = TimeZone.current
                        
                        if let newTime = Calendar.current.date(from: components) {
                            // Получаем текущие время начала и окончания задачи
                            let startCalendarComponents = Calendar.current.dateComponents([.hour, .minute], from: task.startTime)
                            let endCalendarComponents = Calendar.current.dateComponents([.hour, .minute], from: task.endTime)
                            
                            // Проверка минимальной длительности (20 минут)
                            let minimumDuration: TimeInterval = 20 * 60
                            
                            if isDraggingStart {
                                // Проверяем, не является ли новое время начала равным 0 часов 0 минут
                                if hourComponent == 0 && minuteComponent == 0 {
                                    // Блокируем маркер на отметке 0 - не делаем ничего
                                    return
                                }
                                
                                // Проверяем, не приведет ли изменение к нарушению минимальной длительности
                                if task.endTime.timeIntervalSince(newTime) >= minimumDuration {
                                    viewModel.previewTime = newTime
                                    adjustTask(task, newTime)
                                } else {
                                    // Блокируем маркер на минимальной длительности без его перемещения
                                    return
                                }
                            } else { // Маркер конца
                                // Проверяем, не является ли новое время окончания равным 0 часов 0 минут
                                if hourComponent == 0 && minuteComponent == 0 {
                                    // Блокируем маркер на отметке 0 - не делаем ничего
                                    return
                                }
                                
                                // Проверяем, не приведет ли изменение к нарушению минимальной длительности
                                if newTime.timeIntervalSince(task.startTime) >= minimumDuration {
                                    viewModel.previewTime = newTime
                                    adjustTask(task, newTime)
                                } else {
                                    // Блокируем маркер на минимальной длительности без его перемещения
                                    return
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
                        
                        // Сбрасываем последний часовой компонент
                        lastHourComponent = -1
                        
                        // Виброотдача при завершении перетаскивания
                        triggerHapticFeedback()
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
}

// Выносим отображение времени в отдельный компонент
struct TaskTimeLabels: View {
    let task: TaskOnRing
    let isAnalog: Bool
    let viewModel: ClockViewModel
    let startAngle: Angle
    let endAngle: Angle
    let center: CGPoint
    let arcRadius: CGFloat
    let timeTextOffset: CGFloat
    let shortTaskScale: CGFloat
    let timeFormatter: DateFormatter
    
    // Добавляем доступ к толщине дуги
    var arcLineWidth: CGFloat {
        return isAnalog ? viewModel.outerRingLineWidth : viewModel.taskArcLineWidth
    }
    
    // Вынесено в отдельные методы для улучшения читаемости и оптимизации
    private func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return degrees > 90 && degrees < 270
    }
    
    // Проверка активности задачи
    private var isActiveTask: Bool {
        let now = Date()
        return (task.startTime <= now && task.endTime > now) || viewModel.editingTask?.id == task.id
    }
    
    // Проверка условий для отображения времени
    private var shouldShowTime: Bool {
        !isAnalog && 
        !(viewModel.isEditingMode && task.id == viewModel.editingTask?.id) && 
        (!viewModel.showTimeOnlyForActiveTask || (viewModel.showTimeOnlyForActiveTask && isActiveTask))
    }
    
    var body: some View {
        if shouldShowTime {
            // Текст времени начала задачи
            let startTimeText = timeFormatter.string(from: task.startTime)
            let endTimeText = timeFormatter.string(from: task.endTime)
            let isStartInLeftHalf = isAngleInLeftHalf(startAngle)
            let isEndInLeftHalf = isAngleInLeftHalf(endAngle)
            
            // Расчет масштаба для меток времени в зависимости от толщины дуги
            let minArcWidth: CGFloat = 20
            let maxArcWidth: CGFloat = 32
            let arcWidthScale = 1.0 + ((arcLineWidth - minArcWidth) / (maxArcWidth - minArcWidth)) * 0.5
            
            // Отображаем метку времени начала
            TimeLabel(
                timeText: startTimeText,
                angle: startAngle,
                isLeftHalf: isStartInLeftHalf,
                color: task.category.color,
                center: center,
                radius: arcRadius,
                offset: timeTextOffset,
                scale: shortTaskScale * arcWidthScale
            )
            
            // Отображаем метку времени окончания
            TimeLabel(
                timeText: endTimeText,
                angle: endAngle,
                isLeftHalf: isEndInLeftHalf,
                color: task.category.color,
                center: center,
                radius: arcRadius,
                offset: timeTextOffset,
                scale: shortTaskScale * arcWidthScale
            )
        }
    }
}

// Модифицируем структуру TimeLabel, убирая зависимость от Environment
struct TimeLabel: View {
    let timeText: String
    let angle: Angle
    let isLeftHalf: Bool
    let color: Color
    let center: CGPoint
    let radius: CGFloat
    let offset: CGFloat
    let scale: CGFloat
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(color)
                .frame(width: (CGFloat(timeText.count) * 6 + 6) * scale, height: 16 * scale)
            
            Text(timeText)
                .font(.system(size: 10 * scale))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1)
        }
        .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
        .position(
            x: center.x + (radius + offset) * cos(angle.radians),
            y: center.y + (radius + offset) * sin(angle.radians)
        )
    }
}
