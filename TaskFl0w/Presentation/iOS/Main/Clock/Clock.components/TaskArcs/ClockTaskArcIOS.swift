//
//  ClockTaskArcIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import UIKit

struct ClockTaskArcIOS: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: ClockViewModel
    let arcLineWidth: CGFloat

    @State private var isDragging: Bool = false
    @State private var isVisible: Bool = true
    @State private var lastHourComponent: Int = -1
    
    // Добавляем состояния для анимации появления
    @State private var appearanceScale: CGFloat = 0.6
    @State private var appearanceOpacity: Double = 1.0
    @State private var appearanceRotation: Double = 0.0
    @State private var hasAppeared: Bool = false
    
    // Добавляем состояние для эффекта нажатия
    @State private var isPressed: Bool = false
    
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
    private let baseIconSize: CGFloat = 18
    private let minIconFontSize: CGFloat = 10
    private let maxIconFontSize: CGFloat = 17
    private let timeFontSize: CGFloat = 10
    private let timeTextOffset: CGFloat = -8
    
    // Добавляем константу для минимальной длительности
    private let minimumDuration: TimeInterval = 20 * 60
    
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

    // Вынесите функцию isAngleInLeftHalf выше, чтобы она была доступна
    private func isAngleInLeftHalf(_ angle: Angle) -> Bool {
        let degrees = (angle.degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return degrees > 90 && degrees < 270
    }

    // Выносим геометрические вычисления в отдельные методы
    private func calculateArcRadius(radius: CGFloat, analogOffset: CGFloat) -> CGFloat {
        isAnalog ? radius + (viewModel.outerRingLineWidth / 2) + analogOffset : radius + arcLineWidth / 2
    }
    
    private func calculateIconRadius(arcRadius: CGFloat, iconSize: CGFloat, iconOffset: CGFloat) -> CGFloat {
        isAnalog ? arcRadius : arcRadius + iconSize / 2 + iconOffset
    }
    
    private func calculateIconFontSize(tRing: CGFloat) -> CGFloat {
        isAnalog ? minIconFontSize + (maxIconFontSize - minIconFontSize) * tRing : minIconFontSize
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
                
                // Размеры иконки — всегда одинаковые, не зависят от shortTaskScale
                let iconSize: CGFloat = baseIconSize
                
                // Отступы для аналогового режима
                let analogOffset = minOffset + (maxOffset - minOffset) * tArcOffset
                
                // Радиус дуги
                let arcRadius: CGFloat = calculateArcRadius(radius: radius, analogOffset: analogOffset)
                
                // Расчет смещения иконки - минимальный отступ
                let analogIconOffset = minAnalogIconOffset + (maxAnalogIconOffset - minAnalogIconOffset) * tRing
                let maxIconOffset: CGFloat = isAnalog ? analogIconOffset : 0  // Убираем отступ совсем
                let iconOffset = minIconOffset + (maxIconOffset - minIconOffset) * tIconOffset
                
                // Расчет радиуса для размещения иконки - ближе к дуге
                let baseIconRadius: CGFloat = isAnalog ? arcRadius : arcRadius - 4  // Сдвигаем иконку ближе к центру на 8 пикселей
                
                // Добавляем дополнительное смещение для режима редактирования
                let editingOffset: CGFloat = (viewModel.isEditingMode && task.id == viewModel.editingTask?.id) ? 25 : 0
                let iconRadius: CGFloat = baseIconRadius + editingOffset
                
                // Размер шрифта иконки — всегда одинаковый
                let iconFontSize: CGFloat = calculateIconFontSize(tRing: tRing)
                
                // Создаем только один Path для дуги задачи, используемый и для отрисовки, и для распознавания жестов
                let taskArcPath = Path { path in
                    path.addArc(
                        center: center,
                        radius: arcRadius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false)
                }
                
                // Контент-шейп для распознавания жестов (увеличенная область для удобства)
                let taskGestureArea = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius + 70, // Увеличиваем область для удобства касания
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    path.addArc(
                        center: center,
                        radius: radius - 10, // Немного заходим внутрь
                        startAngle: endAngle,
                        endAngle: startAngle,
                        clockwise: true
                    )
                    path.closeSubpath()
                }
                
                // Контент-шейп для drag preview (точно соответствует визуальной дуге)
                let taskDragPreviewArea = Path { path in
                    path.addArc(
                        center: center,
                        radius: arcRadius + arcLineWidth/2,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        clockwise: false
                    )
                    path.addArc(
                        center: center,
                        radius: arcRadius - arcLineWidth/2,
                        startAngle: endAngle,
                        endAngle: startAngle,
                        clockwise: true
                    )
                    path.closeSubpath()
                }
                
                ZStack {
                    // Оборачиваем дугу и маркеры в общий контейнер для анимации
                    ZStack {
                        // Дуга задачи
                        taskArcPath
                            .stroke(task.category.color, lineWidth: arcLineWidth)
                            .contentShape(.interaction, taskGestureArea) // Для жестов используем увеличенную область
                            .contentShape(.dragPreview, taskDragPreviewArea) // Для drag preview используем точную форму
                            .gesture(
                                TapGesture()
                                    .onEnded {
                                        // Добавляем виброотдачу при входе в режим редактирования
                                        triggerHapticFeedback()
                                        
                                        // Эффект нажатия
                                        withAnimation(.easeOut(duration: 0.1)) {
                                            isPressed = true
                                        }
                                        
                                        withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                                            if viewModel.isEditingMode, viewModel.editingTask?.id == task.id
                                            {
                                                viewModel.isEditingMode = false
                                                viewModel.editingTask = nil
                                            } else {
                                                viewModel.isEditingMode = true
                                                viewModel.editingTask = task
                                            }
                                        }
                                        
                                        // Возвращаем обратно после анимации
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            withAnimation(.easeIn(duration: 0.1)) {
                                                isPressed = false
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
                    }
                    // Применяем анимационные эффекты ко всему контейнеру (дуга + маркеры)
                    .scaleEffect(appearanceScale * (isPressed ? 1.05 : 1.0))
                    .opacity(appearanceOpacity)
                    .rotationEffect(.degrees(appearanceRotation))

                    // Заменяем отдельные компоненты на единую структуру
                    TaskOverlayElements(
                        task: task,
                        viewModel: viewModel,
                        isAnalog: isAnalog,
                        center: center,
                        radius: radius,
                        startAngle: startAngle,
                        endAngle: endAngle,
                        arcRadius: arcRadius,
                        arcLineWidth: arcLineWidth,
                        timeTextOffset: timeTextOffset,
                        shortTaskScale: shortTaskScale,
                        timeFormatter: timeFormatter,
                        analogOffset: analogOffset,
                        tRing: tRing,
                        lastHourComponent: $lastHourComponent,
                        isPressed: isPressed,
                        adjustTaskStartTimesForOverlap: adjustTaskStartTimesForOverlap,
                        adjustTaskEndTimesForOverlap: adjustTaskEndTimesForOverlap,
                        triggerHapticFeedback: triggerHapticFeedback,
                        triggerSelectionHapticFeedback: triggerSelectionHapticFeedback,
                        triggerDragHapticFeedback: triggerDragHapticFeedback,
                        handleDragGesture: handleDragGesture
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
                    .scaleEffect(appearanceScale * (isPressed ? 1.05 : 1.0))
                    .opacity(appearanceOpacity)

                    // Иконка категории — тоже отдельно
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
                        // Иконка имеет свою анимацию с небольшим поворотом
                        .scaleEffect(appearanceScale * 1.1 * (isPressed ? 1.05 : 1.0)) // Иконка появляется чуть больше и поднимается при нажатии
                        .opacity(appearanceOpacity)
                        .rotationEffect(.degrees(appearanceRotation * 0.5)) // Меньшее вращение для иконки
                        .animation(.easeInOut(duration: 0.3), value: editingOffset)
                        .id("task-icon-\(task.id)-\(viewModel.zeroPosition)")
                        .gesture(
                            TapGesture()
                                .onEnded {
                                    // Добавляем виброотдачу и для иконки
                                    triggerHapticFeedback()
                                    
                                    // Эффект нажатия для иконки
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        isPressed = true
                                    }
                                    
                                    withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                                        if viewModel.isEditingMode, viewModel.editingTask?.id == task.id
                                        {
                                            viewModel.isEditingMode = false
                                            viewModel.editingTask = nil
                                        } else {
                                            viewModel.isEditingMode = true
                                            viewModel.editingTask = task
                                        }
                                    }
                                    
                                    // Возвращаем обратно после анимации
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        withAnimation(.easeIn(duration: 0.1)) {
                                            isPressed = false
                                        }
                                    }
                                }
                        )
                }
            }
            // Добавляем onAppear для запуска анимации появления
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    startAppearanceAnimation()
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
                            // Анимация исчезновения перед удалением
                            startDisappearanceAnimation {
                                viewModel.taskManagement.removeTask(task)
                                isVisible = false
                            }
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
        let minHandleSize: CGFloat = 20
        let maxHandleSize: CGFloat = 30

        // Интерполяция размера маркера
        let t = (viewModel.outerRingLineWidth - minOuterRingWidth) / (maxOuterRingWidth - minOuterRingWidth)
        // Базовый размер маркера с учетом масштаба для коротких задач
        let baseHandleSize: CGFloat = viewModel.isAnalogArcStyle
            ? minHandleSize + (maxHandleSize - minHandleSize) * t
            : minHandleSize
        let baseHandleWidth: CGFloat = baseHandleSize // ширина всегда постоянная
        let handleHeight: CGFloat = baseHandleSize * pow(shortTaskScale, 2) // уменьшение высоты ускорено

        // Увеличенная область касания - особенно когда высота маркера ещё не уменьшилась
        let touchAreaWidth: CGFloat = max(baseHandleWidth, 35) // минимум 44pt для удобства касания
        let touchAreaHeight: CGFloat = shortTaskScale > 0.8 ? max(handleHeight, 44) : handleHeight * 1.5

        let arcRadius: CGFloat = calculateArcRadius(radius: radius, analogOffset: analogOffset)
 
        // Используем arcRadius вместо handleRadius, так как нам не нужен дополнительный отступ для маркера
        let handleRadius: CGFloat = arcRadius

        let isLeftHalf = isAngleInLeftHalf(angle)

        Capsule()
            .fill(color)
            .frame(width: baseHandleWidth, height: handleHeight)
            .overlay(Capsule().stroke(Color.gray, lineWidth: 2 * shortTaskScale))
            .contentShape(Capsule()
                .size(width: touchAreaWidth, height: touchAreaHeight))
            .rotationEffect(isLeftHalf ? angle + .degrees(180) : angle)
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
                        
                        // Выносим логику обработки жестов в отдельные методы
                        handleDragGesture(value: value, center: center, isDraggingStart: isDraggingStart)
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

    // Выносим логику обработки жестов в отдельные методы
    private func handleDragGesture(value: DragGesture.Value, center: CGPoint, isDraggingStart: Bool) {
        let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        let adjustedDegrees = (degrees - 270 - viewModel.zeroPosition + 360).truncatingRemainder(dividingBy: 360)
        
        let hours = adjustedDegrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        handleHourChange(hourComponent)
        handleMinuteChange(minuteComponent)
        
        updateTaskTime(hourComponent: hourComponent, minuteComponent: minuteComponent, isDraggingStart: isDraggingStart)
    }
    
    private func handleHourChange(_ hourComponent: Int) {
        if hourComponent != lastHourComponent {
            if lastHourComponent != -1 {
                triggerSelectionHapticFeedback()
            }
            lastHourComponent = hourComponent
        }
    }
    
    private func handleMinuteChange(_ minuteComponent: Int) {
        let currentMinuteBucket = minuteComponent / 5
        if currentMinuteBucket != (minuteComponent - 1) / 5 && lastHourComponent != -1 {
            triggerDragHapticFeedback()
        }
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

    private func updateTaskTime(hourComponent: Int, minuteComponent: Int, isDraggingStart: Bool) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current
        
        guard let newTime = Calendar.current.date(from: components) else { return }
        
        if isDraggingStart {
            handleStartTimeUpdate(newTime, hourComponent: hourComponent, minuteComponent: minuteComponent)
        } else {
            handleEndTimeUpdate(newTime, hourComponent: hourComponent, minuteComponent: minuteComponent)
        }
    }
    
    private func handleStartTimeUpdate(_ newTime: Date, hourComponent: Int, minuteComponent: Int) {
        guard hourComponent != 0 || minuteComponent != 0 else { return }
        guard task.endTime.timeIntervalSince(newTime) >= minimumDuration else { return }
        
        viewModel.previewTime = newTime
        adjustTaskStartTimesForOverlap(task, newStartTime: newTime)
    }
    
    private func handleEndTimeUpdate(_ newTime: Date, hourComponent: Int, minuteComponent: Int) {
        guard hourComponent != 0 || minuteComponent != 0 else { return }
        guard newTime.timeIntervalSince(task.startTime) >= minimumDuration else { return }
        
        viewModel.previewTime = newTime
        adjustTaskEndTimesForOverlap(task, newEndTime: newTime)
    }

    // Обновляем функцию для анимации появления
    private func startAppearanceAnimation() {
        // Сначала устанавливаем начальные значения для анимации
        appearanceScale = 0.0
        appearanceOpacity = 0.0
        appearanceRotation = -15.0
        
        // Небольшая задержка для более естественного появления
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                appearanceScale = 1.0
                appearanceOpacity = 1.0
                appearanceRotation = 0.0
            }
        }
    }
    
    // Обновляем функцию для анимации исчезновения
    private func startDisappearanceAnimation(completion: @escaping () -> Void) {
        withAnimation(.easeIn(duration: 0.3)) {
            appearanceScale = 0.0
            appearanceOpacity = 0.0
            appearanceRotation = 15.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }
    }
}
