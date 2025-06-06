//
//  TaskChainAnalyzer.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskChainAnalyzer {
    
    // MARK: - Оптимизированный анализ цепочки для времени начала
    static func findCompleteTaskChainForStartTime(
        tasks: [TaskOnRing],
        initiatingTask: TaskOnRing,
        dayBounds: (start: Date, end: Date)
    ) -> ([(TaskOnRing, Date, Date)], Bool) {
        
        // Создаем индекс задач для быстрого поиска O(1)
        let taskIndex = createTaskTimeIndex(tasks: tasks, excluding: initiatingTask.id)
        
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []
        var processedTasks: Set<UUID> = [initiatingTask.id]
        var tasksQueue: [(task: TaskOnRing, newStartTime: Date, newEndTime: Date)] = 
            [(initiatingTask, initiatingTask.startTime, initiatingTask.endTime)]
        
        var iterationCount = 0
        
        while !tasksQueue.isEmpty && iterationCount < TaskOverlapConstants.maxIterationsPerChain {
            iterationCount += 1
            let currentTaskInfo = tasksQueue.removeFirst()
            
            // Используем индекс для быстрого поиска пересекающихся задач
            let overlappingTasks = findOverlappingTasks(
                timeRange: (currentTaskInfo.newStartTime, currentTaskInfo.newEndTime),
                taskIndex: taskIndex,
                processedTasks: processedTasks
            )
            
            for task in overlappingTasks {
                let taskDuration = task.duration
                let idealNewEndTime = currentTaskInfo.newStartTime
                let idealNewStartTime = idealNewEndTime.addingTimeInterval(-taskDuration)
                
                // Критическая проверка границ
                if idealNewStartTime < dayBounds.start {
                    return ([], false)
                }
                
                processedTasks.insert(task.id)
                let newTaskInfo = (task: task, newStartTime: idealNewStartTime, newEndTime: idealNewEndTime)
                tasksQueue.append(newTaskInfo)
                tasksToUpdate.append((task, idealNewStartTime, idealNewEndTime))
            }
        }
        
        return (tasksToUpdate, iterationCount < TaskOverlapConstants.maxIterationsPerChain)
    }
    
    // MARK: - Оптимизированный анализ цепочки для времени окончания
    static func findCompleteTaskChainForEndTime(
        tasks: [TaskOnRing],
        initiatingTask: TaskOnRing,
        dayBounds: (start: Date, end: Date)
    ) -> ([(TaskOnRing, Date, Date)], Bool) {
        
        let taskIndex = createTaskTimeIndex(tasks: tasks, excluding: initiatingTask.id)
        
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []
        var processedTasks: Set<UUID> = [initiatingTask.id]
        var tasksQueue: [(task: TaskOnRing, newStartTime: Date, newEndTime: Date)] = 
            [(initiatingTask, initiatingTask.startTime, initiatingTask.endTime)]
        
        var iterationCount = 0
        
        while !tasksQueue.isEmpty && iterationCount < TaskOverlapConstants.maxIterationsPerChain {
            iterationCount += 1
            let currentTaskInfo = tasksQueue.removeFirst()
            
            let overlappingTasks = findOverlappingTasks(
                timeRange: (currentTaskInfo.newStartTime, currentTaskInfo.newEndTime),
                taskIndex: taskIndex,
                processedTasks: processedTasks
            )
            
            for task in overlappingTasks {
                let taskDuration = task.duration
                let idealNewStartTime = currentTaskInfo.newEndTime
                let idealNewEndTime = idealNewStartTime.addingTimeInterval(taskDuration)
                
                if idealNewEndTime > dayBounds.end {
                    return ([], false)
                }
                
                processedTasks.insert(task.id)
                let newTaskInfo = (task: task, newStartTime: idealNewStartTime, newEndTime: idealNewEndTime)
                tasksQueue.append(newTaskInfo)
                tasksToUpdate.append((task, idealNewStartTime, idealNewEndTime))
            }
        }
        
        return (tasksToUpdate, iterationCount < TaskOverlapConstants.maxIterationsPerChain)
    }
    
    // MARK: - Производительные индексы (ИСПРАВЛЕНО)
    private static func createTaskTimeIndex(tasks: [TaskOnRing], excluding excludedId: UUID) -> [Int: [TaskOnRing]] {
        var index: [Int: [TaskOnRing]] = [:]
        
        for task in tasks where task.id != excludedId {
            let startHour = Calendar.current.component(.hour, from: task.startTime)
            let endHour = Calendar.current.component(.hour, from: task.endTime)
            
            // ИСПРАВЛЕНИЕ: Обработка перехода через полночь
            let hoursToIndex = getHoursForTask(startHour: startHour, endHour: endHour)
            
            for hour in hoursToIndex {
                if index[hour] == nil {
                    index[hour] = []
                }
                index[hour]!.append(task)
            }
        }
        
        return index
    }
    
    // НОВЫЙ МЕТОД: Безопасное получение часов для задачи
    private static func getHoursForTask(startHour: Int, endHour: Int) -> [Int] {
        var hours: [Int] = []
        
        if startHour <= endHour {
            // Обычный случай: задача в пределах одного дня
            for hour in startHour...endHour {
                hours.append(hour)
            }
        } else {
            // Задача переходит через полночь
            // Добавляем часы от startHour до 23
            for hour in startHour...23 {
                hours.append(hour)
            }
            // Добавляем часы от 0 до endHour
            for hour in 0...endHour {
                hours.append(hour)
            }
        }
        
        return hours
    }
    
    private static func findOverlappingTasks(
        timeRange: (start: Date, end: Date),
        taskIndex: [Int: [TaskOnRing]],
        processedTasks: Set<UUID>
    ) -> [TaskOnRing] {
        
        let startHour = Calendar.current.component(.hour, from: timeRange.start)
        let endHour = Calendar.current.component(.hour, from: timeRange.end)
        
        var overlappingTasks: Set<TaskOnRing> = []
        
        // ИСПРАВЛЕНИЕ: Безопасное получение часов для поиска
        let hoursToCheck = getHoursForTask(startHour: startHour, endHour: endHour)
        
        // Проверяем только релевантные часы
        for hour in hoursToCheck {
            if let tasksInHour = taskIndex[hour] {
                for task in tasksInHour where !processedTasks.contains(task.id) {
                    // Точная проверка пересечения
                    if timeRange.start < task.endTime && timeRange.end > task.startTime {
                        overlappingTasks.insert(task)
                    }
                }
            }
        }
        
        return Array(overlappingTasks)
    }
} 