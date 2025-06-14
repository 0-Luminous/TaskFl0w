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
        
        let dayBounds = TaskTimeValidator.getDayBounds(for: selectedDate)
        let otherTasks = tasks.filter { $0.id != currentTask.id }
        
        // Сначала пробуем предпочтительное время
        let preferredEndTime = preferredStartTime.addingTimeInterval(taskDuration)
        
        if canPlaceTask(
            startTime: preferredStartTime,
            endTime: preferredEndTime,
            againstTasks: otherTasks,
            withinBounds: dayBounds
        ) {
            return (preferredStartTime, preferredEndTime)
        }
        
        // Ищем ближайшее свободное место
        let searchStep: TimeInterval = 15 * 60 // 15 минут
        let maxSearchTime: TimeInterval = 12 * 60 * 60 // 12 часов
        
        for offset in stride(from: searchStep, through: maxSearchTime, by: searchStep) {
            // Пробуем позже
            let laterStart = preferredStartTime.addingTimeInterval(offset)
            let laterEnd = laterStart.addingTimeInterval(taskDuration)
            
            if canPlaceTask(
                startTime: laterStart,
                endTime: laterEnd,
                againstTasks: otherTasks,
                withinBounds: dayBounds
            ) {
                return (laterStart, laterEnd)
            }
            
            // Пробуем раньше
            let earlierStart = preferredStartTime.addingTimeInterval(-offset)
            let earlierEnd = earlierStart.addingTimeInterval(taskDuration)
            
            if canPlaceTask(
                startTime: earlierStart,
                endTime: earlierEnd,
                againstTasks: otherTasks,
                withinBounds: dayBounds
            ) {
                return (earlierStart, earlierEnd)
            }
        }
        
        // Если не нашли место, возвращаем предпочтительное время
        return (preferredStartTime, preferredEndTime)
    }
    
    private static func canPlaceTask(
        startTime: Date,
        endTime: Date,
        againstTasks: [TaskOnRing],
        withinBounds: (start: Date, end: Date)
    ) -> Bool {
        
        // Проверяем границы дня
        guard startTime >= withinBounds.start && endTime <= withinBounds.end else {
            return false
        }
        
        // Проверяем пересечения с другими задачами
        for task in againstTasks {
            if startTime < task.endTime && endTime > task.startTime {
                return false
            }
        }
        
        return true
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