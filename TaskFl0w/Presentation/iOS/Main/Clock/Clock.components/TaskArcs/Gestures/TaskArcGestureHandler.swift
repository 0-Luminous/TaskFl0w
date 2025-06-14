//
//  TaskArcGestureHandler.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

@MainActor
class TaskArcGestureHandler: ObservableObject {
    private let viewModel: ClockViewModel
    private let taskId: UUID  // ✅ Храним только ID вместо копии задачи
    private let hapticsManager = TaskArcHapticsManager()
    
    // Change from @StateObject to regular property
    private let highFrequencyManager: HighFrequencyUpdateManager
    
    @Published var lastHourComponent: Int = -1
    @Published var isDraggingWholeArc: Bool = false
    
    // Переменные для корректного отслеживания смещения
    private var initialDragLocation: CGPoint = .zero
    private var initialTaskStartTime: Date = Date()
    
    // ✅ Computed property для получения актуальной задачи
    private var currentTask: TaskOnRing? {
        return viewModel.tasks.first { $0.id == taskId }
    }
    
    init(viewModel: ClockViewModel, task: TaskOnRing) {
        self.viewModel = viewModel
        self.taskId = task.id  // ✅ Сохраняем только ID
        // Initialize highFrequencyManager directly
        self.highFrequencyManager = HighFrequencyUpdateManager(viewModel: viewModel)
    }
    
    func handleDragGesture(value: DragGesture.Value, center: CGPoint, isDraggingStart: Bool) {
        // Запускаем высокочастотное обновление при начале перетаскивания
        if !highFrequencyManager.isHighFrequencyMode {
            highFrequencyManager.startHighFrequencyUpdates()
        }
        
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
    
    func startWholeArcDrag(at location: CGPoint, center: CGPoint, indicatorPosition: CGPoint) {
        guard let task = currentTask else { return }  // ✅ Получаем актуальную задачу
        
        // Запускаем высокочастотное обновление
        highFrequencyManager.startHighFrequencyUpdates()
        
        // Запоминаем начальную позицию пальца и время задачи
        initialDragLocation = location
        initialTaskStartTime = task.startTime
        isDraggingWholeArc = true
    }
    
    func handleWholeArcDrag(value: DragGesture.Value, center: CGPoint) {
        // Убеждаемся что высокочастотное обновление активно
        if !highFrequencyManager.isHighFrequencyMode {
            highFrequencyManager.startHighFrequencyUpdates()
        }
        
        guard let task = currentTask else { return }
        
        // Конвертируем смещение пальца в смещение угла
        let currentFingerAngle = atan2(value.location.y - center.y, value.location.x - center.x)
        let initialFingerAngle = atan2(initialDragLocation.y - center.y, initialDragLocation.x - center.x)
        let angleDifference = currentFingerAngle - initialFingerAngle
        
        // Конвертируем разность углов в градусы
        var angleDifferenceInDegrees = angleDifference * 180 / .pi
        
        // Нормализуем угол (обрабатываем переход через 0/360)
        if angleDifferenceInDegrees > 180 {
            angleDifferenceInDegrees -= 360
        } else if angleDifferenceInDegrees < -180 {
            angleDifferenceInDegrees += 360
        }
        
        // Вычисляем новое время задачи на основе начального времени и смещения угла
        let timeOffsetInMinutes = angleDifferenceInDegrees * 4 // 1 градус = 4 минуты
        let potentialNewStartTime = initialTaskStartTime.addingTimeInterval(timeOffsetInMinutes * 60)
        
        // Получаем границы дня для текущей выбранной даты
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60) // 23:59
        
        // Вычисляем продолжительность задачи
        let taskDuration = task.duration
        let potentialNewEndTime = potentialNewStartTime.addingTimeInterval(taskDuration)
        
        // Проверяем границы: начало не раньше 00:00, конец не позже 23:59
        var newStartTime = potentialNewStartTime
        
        if potentialNewStartTime < startOfDay {
            // Если начало задачи пытается уйти раньше 00:00, фиксируем на 00:00
            newStartTime = startOfDay
        } else if potentialNewEndTime > endOfDay {
            // Если конец задачи пытается уйти позже 23:59, фиксируем начало так, чтобы конец был в 23:59
            newStartTime = endOfDay.addingTimeInterval(-taskDuration)
        }
        
        // Извлекаем компоненты времени из скорректированного времени
        let components = calendar.dateComponents([.hour, .minute], from: newStartTime)
        let hourComponent = components.hour ?? 0
        let minuteComponent = components.minute ?? 0
        
        handleHourChange(hourComponent)
        handleMinuteChange(minuteComponent)
        // Обновляем время без проверки столкновений
        updateWholeTaskTimeWithoutCollisionCheck(hourComponent: hourComponent, minuteComponent: minuteComponent)
    }
    
    // Новый метод обновления времени без проверки столкновений
    private func updateWholeTaskTimeWithoutCollisionCheck(hourComponent: Int, minuteComponent: Int) {
        guard var task = currentTask else { return }  // ✅ Получаем актуальную задачу
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current
        
        guard let newStartTime = Calendar.current.date(from: components) else { return }
        
        let duration = task.duration
        let newEndTime = newStartTime.addingTimeInterval(duration)
        
        viewModel.previewTime = newStartTime
        task.startTime = newStartTime
        task.endTime = newEndTime
        
        // Обновляем только саму задачу, без обработки столкновений
        viewModel.taskManagement.updateWholeTask(task, newStartTime: newStartTime, newEndTime: newEndTime)
    }
    
    func handleWholeArcDragWithLocation(location: CGPoint, center: CGPoint) {
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let degrees = (angle * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        let adjustedDegrees = (degrees - 270 - viewModel.zeroPosition + 360).truncatingRemainder(dividingBy: 360)
        
        let hours = adjustedDegrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)
        
        handleHourChange(hourComponent)
        handleMinuteChange(minuteComponent)
        updateWholeTaskTime(hourComponent: hourComponent, minuteComponent: minuteComponent)
    }
    
    private func handleHourChange(_ hourComponent: Int) {
        if hourComponent != lastHourComponent {
            if lastHourComponent != -1 {
                hapticsManager.triggerSelectionFeedback()
            }
            lastHourComponent = hourComponent
        }
    }
    
    private func handleMinuteChange(_ minuteComponent: Int) {
        let currentMinuteBucket = minuteComponent / 5
        if currentMinuteBucket != (minuteComponent - 1) / 5 && lastHourComponent != -1 {
            hapticsManager.triggerDragFeedback()
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
        guard let task = currentTask else { return }
        
        // Проверяем минимальную продолжительность задачи  
        guard task.endTime.timeIntervalSince(newTime) >= TaskArcConstants.minimumDuration else { return }
        
        // Проверяем границы дня
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        // Ограничиваем время границами дня
        let constrainedTime = max(startOfDay, min(newTime, endOfDay))
        
        // ✅ ПРОВЕРЯЕМ, МОЖНО ЛИ ПЕРЕМЕСТИТЬ ДРУГИЕ ЗАДАЧИ БЕЗ СЖАТИЯ
        let canMoveOtherTasks = TaskOverlapManager.adjustTaskStartTimesForOverlap(
            viewModel: viewModel, 
            currentTask: task, 
            newStartTime: constrainedTime
        )
        
        // Если другие задачи упираются в границы и не помещаются - БЛОКИРУЕМ маркер
        if !canMoveOtherTasks {
            hapticsManager.triggerHardFeedback() // Тактильная обратная связь о блокировке
            return // НЕ ОБНОВЛЯЕМ позицию маркера
        }
        
        viewModel.previewTime = constrainedTime
        // Обновление уже произошло в adjustTaskStartTimesForOverlap
    }
    
    private func handleEndTimeUpdate(_ newTime: Date, hourComponent: Int, minuteComponent: Int) {
        guard let task = currentTask else { return }
        
        // Проверяем минимальную продолжительность задачи
        guard newTime.timeIntervalSince(task.startTime) >= TaskArcConstants.minimumDuration else { return }
        
        // Проверяем границы дня  
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        // Ограничиваем время границами дня
        let constrainedTime = max(startOfDay, min(newTime, endOfDay))
        
        // ✅ ПРОВЕРЯЕМ, МОЖНО ЛИ ПЕРЕМЕСТИТЬ ДРУГИЕ ЗАДАЧИ БЕЗ СЖАТИЯ
        let canMoveOtherTasks = TaskOverlapManager.adjustTaskEndTimesForOverlap(
            viewModel: viewModel, 
            currentTask: task, 
            newEndTime: constrainedTime
        )
        
        // Если другие задачи упираются в границы и не помещаются - БЛОКИРУЕМ маркер
        if !canMoveOtherTasks {
            hapticsManager.triggerHardFeedback() // Тактильная обратная связь о блокировке
            return // НЕ ОБНОВЛЯЕМ позицию маркера
        }
        
        viewModel.previewTime = constrainedTime
        // Обновление уже произошло в adjustTaskEndTimesForOverlap
    }
    
    private func updateWholeTaskTime(hourComponent: Int, minuteComponent: Int) {
        guard let task = currentTask else { return }  // ✅ Получаем актуальную задачу
        
        var components = Calendar.current.dateComponents([.year, .month, .day], from: viewModel.selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current
        
        guard let newStartTime = Calendar.current.date(from: components) else { return }
        
        let duration = task.duration
        let newEndTime = newStartTime.addingTimeInterval(duration)
        
        viewModel.previewTime = newStartTime
        // ✅ Больше не изменяем локальную копию задачи
        
        viewModel.taskManagement.updateWholeTask(task, newStartTime: newStartTime, newEndTime: newEndTime)
        
        TaskOverlapManager.adjustTaskTimesForWholeArcMove(viewModel: viewModel, currentTask: task, newStartTime: newStartTime, newEndTime: newEndTime)
    }
    
    func resetLastHourComponent() {
        lastHourComponent = -1
        // Сбрасываем переменные смещения
        initialDragLocation = .zero
        initialTaskStartTime = Date()
        
        // Останавливаем высокочастотное обновление
        highFrequencyManager.stopHighFrequencyUpdates()
    }
    
    // Метод для завершения перетаскивания всей дуги с проверкой столкновений
    func finalizeWholeArcDrag() {
        guard let task = currentTask else { return }  // ✅ Получаем актуальную задачу
        
        // Останавливаем высокочастотное обновление
        highFrequencyManager.stopHighFrequencyUpdates()
        
        // Проверяем, есть ли столкновения с другими задачами
        let hasCollisions = checkForCollisions()
        
        if hasCollisions {
            // Если есть столкновения, находим ближайшее свободное место
            let freePlacement = TaskOverlapManager.findFreeTimeSlotForWholeArc(
                viewModel: viewModel,
                currentTask: task,
                preferredStartTime: task.startTime,
                taskDuration: task.duration
            )
            
            // Перемещаем задачу в свободное место
            viewModel.taskManagement.updateWholeTask(task, newStartTime: freePlacement.startTime, newEndTime: freePlacement.endTime)
            
            // Дополнительная тактильная обратная связь для обозначения перепрыгивания
            hapticsManager.triggerHardFeedback()
        }
    }
    
    // Проверка столкновений с другими задачами
    private func checkForCollisions() -> Bool {
        guard let task = currentTask else { return false }  // ✅ Получаем актуальную задачу
        
        for otherTask in viewModel.tasks where otherTask.id != task.id {
            // Проверяем пересечение временных интервалов
            if task.startTime < otherTask.endTime && task.endTime > otherTask.startTime {
                return true
            }
        }
        return false
    }
} 