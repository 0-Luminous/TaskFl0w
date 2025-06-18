//
//  TaskChainAnalyzer.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskChainAnalyzer {
    
    // MARK: - Кэш для улучшения производительности
    private static let calendar = Calendar.current
    private static var hourComponentCache: [Date: Int] = [:]
    private static let maxCacheSize = 200
    
    // MARK: - Оптимизированный анализ цепочки для времени начала
    static func findCompleteTaskChainForStartTime(
        tasks: [TaskOnRing],
        initiatingTask: TaskOnRing,
        dayBounds: (start: Date, end: Date)
    ) -> (affectedTasks: [(TaskOnRing, Date, Date)], canMove: Bool) {
        
        var affectedTasks: [(TaskOnRing, Date, Date)] = []
        var canMove = true
        
        // Найти задачи, которые пересекаются с обновленной задачей
        let conflictingTasks = tasks.filter { task in
            task.id != initiatingTask.id &&
            task.startTime < initiatingTask.endTime &&
            task.endTime > initiatingTask.startTime
        }
        
        // Попробовать переместить конфликтующие задачи
        for task in conflictingTasks {
            let newStartTime = initiatingTask.endTime
            let newEndTime = newStartTime.addingTimeInterval(task.duration)
            
            if newEndTime <= dayBounds.end {
                affectedTasks.append((task, newStartTime, newEndTime))
            } else {
                canMove = false
                break
            }
        }
        
        return (affectedTasks, canMove)
    }
    
    // MARK: - Оптимизированный анализ цепочки для времени окончания
    static func findCompleteTaskChainForEndTime(
        tasks: [TaskOnRing],
        initiatingTask: TaskOnRing,
        dayBounds: (start: Date, end: Date)
    ) -> (affectedTasks: [(TaskOnRing, Date, Date)], canMove: Bool) {
        
        var affectedTasks: [(TaskOnRing, Date, Date)] = []
        var canMove = true
        
        // Найти задачи, которые пересекаются с обновленной задачей
        let conflictingTasks = tasks.filter { task in
            task.id != initiatingTask.id &&
            task.startTime < initiatingTask.endTime &&
            task.endTime > initiatingTask.startTime
        }
        
        // Попробовать переместить конфликтующие задачи
        for task in conflictingTasks {
            let newEndTime = initiatingTask.startTime
            let newStartTime = newEndTime.addingTimeInterval(-task.duration)
            
            if newStartTime >= dayBounds.start {
                affectedTasks.append((task, newStartTime, newEndTime))
            } else {
                canMove = false
                break
            }
        }
        
        return (affectedTasks, canMove)
    }
    
    // MARK: - Производительные индексы (ОПТИМИЗИРОВАНО)
    private static func createTaskTimeIndex(tasks: [TaskOnRing], excluding excludedId: UUID) -> [Int: [TaskOnRing]] {
        var index: [Int: [TaskOnRing]] = [:]
        
        for task in tasks where task.id != excludedId {
            let startHour = getCachedHourComponent(for: task.startTime)
            let endHour = getCachedHourComponent(for: task.endTime)
            
            // ОПТИМИЗАЦИЯ: Использование оптимизированного метода генерации часов
            let hoursToIndex = getHoursForTaskOptimized(startHour: startHour, endHour: endHour)
            
            for hour in hoursToIndex {
                if index[hour] == nil {
                    index[hour] = []
                }
                index[hour]!.append(task)
            }
        }
        
        return index
    }
    
    // ОПТИМИЗАЦИЯ: Кэширование компонентов часов
    private static func getCachedHourComponent(for date: Date) -> Int {
        if let cachedHour = hourComponentCache[date] {
            return cachedHour
        }
        
        let hour = calendar.component(.hour, from: date)
        
        // Управление размером кэша
        if hourComponentCache.count >= maxCacheSize {
            hourComponentCache.removeAll(keepingCapacity: true)
        }
        
        hourComponentCache[date] = hour
        return hour
    }
    
    // ОПТИМИЗАЦИЯ: Более эффективная генерация массива часов
    private static func getHoursForTaskOptimized(startHour: Int, endHour: Int) -> [Int] {
        if startHour <= endHour {
            // Обычный случай: создаем массив одним вызовом
            return Array(startHour...endHour)
        } else {
            // Задача переходит через полночь
            // Предварительно выделяем память для массива
            var hours: [Int] = []
            hours.reserveCapacity((24 - startHour) + (endHour + 1))
            
            // Добавляем часы от startHour до 23
            hours.append(contentsOf: startHour...23)
            // Добавляем часы от 0 до endHour
            hours.append(contentsOf: 0...endHour)
            
            return hours
        }
    }
    
    private static func findOverlappingTasks(
        timeRange: (start: Date, end: Date),
        taskIndex: [Int: [TaskOnRing]],
        processedTasks: Set<UUID>
    ) -> [TaskOnRing] {
        
        let startHour = getCachedHourComponent(for: timeRange.start)
        let endHour = getCachedHourComponent(for: timeRange.end)
        
        // ОПТИМИЗАЦИЯ: Используем Set для автоматического удаления дубликатов
        // и избегаем промежуточного массива
        var overlappingTasks: Set<TaskOnRing> = Set()
        
        // ОПТИМИЗАЦИЯ: Безопасное получение часов для поиска
        let hoursToCheck = getHoursForTaskOptimized(startHour: startHour, endHour: endHour)
        
        // Проверяем только релевантные часы
        for hour in hoursToCheck {
            guard let tasksInHour = taskIndex[hour] else { continue }
            
            for task in tasksInHour {
                guard !processedTasks.contains(task.id) else { continue }
                
                // Точная проверка пересечения
                if timeRange.start < task.endTime && timeRange.end > task.startTime {
                    overlappingTasks.insert(task)
                }
            }
        }
        
        return Array(overlappingTasks)
    }
    
    // MARK: - Очистка кэша
    static func clearCache() {
        hourComponentCache.removeAll()
    }
} 