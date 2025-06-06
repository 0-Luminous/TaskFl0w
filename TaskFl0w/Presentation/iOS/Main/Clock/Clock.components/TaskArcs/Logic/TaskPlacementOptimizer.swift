//
//  TaskPlacementOptimizer.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskPlacementOptimizer {
    
    // MARK: - Кэш для улучшения производительности
    private static var placementCache: [String: (startTime: Date, endTime: Date)] = [:]
    private static let maxCacheSize = 100
    
    static func findOptimalTaskPlacement(
        tasks: [TaskOnRing],
        currentTask: TaskOnRing,
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        selectedDate: Date
    ) -> (startTime: Date, endTime: Date) {
        
        // Создаем ключ для кэша
        let cacheKey = createCacheKey(
            currentTaskId: currentTask.id,
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            tasksHash: tasks.hashValue
        )
        
        // Проверяем кэш
        if let cachedResult = placementCache[cacheKey] {
            return cachedResult
        }
        
        let dayBounds = TaskTimeValidator.getDayBounds(for: selectedDate)
        let otherTasks = tasks.filter { $0.id != currentTask.id }.sorted { $0.startTime < $1.startTime }
        
        let result = calculateOptimalPlacement(
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            otherTasks: otherTasks,
            dayBounds: dayBounds,
            currentTask: currentTask
        )
        
        // Кэшируем результат
        updateCache(cacheKey: cacheKey, result: result)
        
        return result
    }
    
    private static func calculateOptimalPlacement(
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        otherTasks: [TaskOnRing],
        dayBounds: (start: Date, end: Date),
        currentTask: TaskOnRing
    ) -> (startTime: Date, endTime: Date) {
        
        let preferredEndTime = preferredStartTime.addingTimeInterval(taskDuration)
        
        // Проверяем предпочтительное время
        if TaskTimeValidator.isTimeSlotFree(
            startTime: preferredStartTime,
            endTime: preferredEndTime,
            excludingTask: currentTask,
            tasks: otherTasks,
            dayBounds: dayBounds
        ) {
            return (startTime: preferredStartTime, endTime: preferredEndTime)
        }
        
        // Используем оптимизированный поиск
        return findNearestFreeSlotOptimized(
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            otherTasks: otherTasks,
            dayBounds: dayBounds,
            currentTask: currentTask
        )
    }
    
    private static func findNearestFreeSlotOptimized(
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        otherTasks: [TaskOnRing],
        dayBounds: (start: Date, end: Date),
        currentTask: TaskOnRing
    ) -> (startTime: Date, endTime: Date) {
        
        // Создаем список временных интервалов для более эффективного поиска
        let timeIntervals = createTimeIntervalsList(from: otherTasks)
        
        // Бинарный поиск ближайшего свободного слота
        if let nearbySlot = findSlotUsingBinarySearch(
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            timeIntervals: timeIntervals,
            dayBounds: dayBounds
        ) {
            return nearbySlot
        }
        
        // Fallback: традиционный поиск
        return findFirstAvailableSlotOptimized(
            taskDuration: taskDuration,
            otherTasks: otherTasks,
            dayBounds: dayBounds,
            preferredStartTime: preferredStartTime
        )
    }
    
    private static func createTimeIntervalsList(from tasks: [TaskOnRing]) -> [(start: Date, end: Date)] {
        return tasks.map { (start: $0.startTime, end: $0.endTime) }
            .sorted { $0.start < $1.start }
    }
    
    private static func findSlotUsingBinarySearch(
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        timeIntervals: [(start: Date, end: Date)],
        dayBounds: (start: Date, end: Date)
    ) -> (startTime: Date, endTime: Date)? {
        
        // Поиск подходящего промежутка между задачами
        for i in 0..<timeIntervals.count - 1 {
            let gapStart = timeIntervals[i].end
            let gapEnd = timeIntervals[i + 1].start
            let gapDuration = gapEnd.timeIntervalSince(gapStart)
            
            if gapDuration >= taskDuration {
                let optimalStart = max(gapStart, min(preferredStartTime, gapEnd.addingTimeInterval(-taskDuration)))
                let optimalEnd = optimalStart.addingTimeInterval(taskDuration)
                
                if optimalStart >= dayBounds.start && optimalEnd <= dayBounds.end {
                    return (startTime: optimalStart, endTime: optimalEnd)
                }
            }
        }
        
        return nil
    }
    
    private static func findFirstAvailableSlotOptimized(
        taskDuration: TimeInterval,
        otherTasks: [TaskOnRing],
        dayBounds: (start: Date, end: Date),
        preferredStartTime: Date
    ) -> (startTime: Date, endTime: Date) {
        
        if otherTasks.isEmpty {
            let startTime = max(dayBounds.start, preferredStartTime)
            let endTime = startTime.addingTimeInterval(taskDuration)
            return (startTime: startTime, endTime: min(endTime, dayBounds.end))
        }
        
        // Проверяем место перед первой задачей
        if let firstTask = otherTasks.first,
           firstTask.startTime.timeIntervalSince(dayBounds.start) >= taskDuration {
            let endTime = firstTask.startTime
            let startTime = endTime.addingTimeInterval(-taskDuration)
            if startTime >= dayBounds.start {
                return (startTime: startTime, endTime: endTime)
            }
        }
        
        // Ищем промежутки между задачами (оптимизированный поиск)
        for i in 0..<(otherTasks.count - 1) {
            let currentTaskEnd = otherTasks[i].endTime
            let nextTaskStart = otherTasks[i + 1].startTime
            let availableTime = nextTaskStart.timeIntervalSince(currentTaskEnd)
            
            if availableTime >= taskDuration {
                return (startTime: currentTaskEnd, endTime: currentTaskEnd.addingTimeInterval(taskDuration))
            }
        }
        
        // Проверяем место после последней задачи
        if let lastTask = otherTasks.last {
            let availableTime = dayBounds.end.timeIntervalSince(lastTask.endTime)
            if availableTime >= taskDuration {
                return (startTime: lastTask.endTime, endTime: lastTask.endTime.addingTimeInterval(taskDuration))
            }
        }
        
        return (startTime: preferredStartTime, endTime: preferredStartTime.addingTimeInterval(taskDuration))
    }
    
    // MARK: - Кэширование
    private static func createCacheKey(
        currentTaskId: UUID,
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        tasksHash: Int
    ) -> String {
        return "\(currentTaskId)_\(preferredStartTime.timeIntervalSince1970)_\(taskDuration)_\(tasksHash)"
    }
    
    private static func updateCache(cacheKey: String, result: (startTime: Date, endTime: Date)) {
        if placementCache.count >= maxCacheSize {
            // Удаляем старые записи
            let keysToRemove = Array(placementCache.keys.prefix(maxCacheSize / 2))
            for key in keysToRemove {
                placementCache.removeValue(forKey: key)
            }
        }
        placementCache[cacheKey] = result
    }
    
    static func clearCache() {
        placementCache.removeAll()
    }
} 