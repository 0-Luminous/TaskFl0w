//
//  TaskOverlapManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskOverlapManager {
    
    // MARK: - Constants
    private enum Constants {
        static let minimumDuration: TimeInterval = 15 * 60 // 15 минут
        static let searchStep: TimeInterval = 15 * 60 // 15 минут
        static let maxSearchRadius: TimeInterval = 12 * 60 * 60 // 12 часов
        static let uiUpdateDelay: TimeInterval = 0.1
    }
    
    // MARK: - Start Time Adjustment
    static func adjustTaskStartTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date) {
        // Проверяем валидность времени
        guard validateTimeChange(viewModel: viewModel, newTime: newStartTime) else {
            return
        }
        
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.startTime = newStartTime
        
        // Обновляем задачу в базе данных
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(currentTask, newStartTime: newStartTime)

        // Обрабатываем перекрытия
        let affectedTasks = findAffectedTasksForStartTimeChange(
            viewModel: viewModel,
            updatedTask: updatedTask
        )
        
        processTaskOverlaps(viewModel: viewModel, affectedTasks: affectedTasks)
        
        // Уведомляем об изменениях
        notifyTaskArcsAboutOverlapChanges(viewModel: viewModel, changedTasks: affectedTasks)
        
        scheduleUIUpdate(viewModel: viewModel)
    }

    // MARK: - End Time Adjustment
    static func adjustTaskEndTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newEndTime: Date) {
        // Проверяем валидность времени
        guard validateTimeChange(viewModel: viewModel, newTime: newEndTime) else {
            return
        }
        
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.endTime = newEndTime
        
        // Обновляем задачу в базе данных
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        // Обрабатываем перекрытия
        let affectedTasks = findAffectedTasksForEndTimeChange(
            viewModel: viewModel,
            updatedTask: updatedTask
        )
        
        processTaskOverlaps(viewModel: viewModel, affectedTasks: affectedTasks)
        
        // Уведомляем об изменениях
        notifyTaskArcsAboutOverlapChanges(viewModel: viewModel, changedTasks: affectedTasks)
        
        scheduleUIUpdate(viewModel: viewModel)
    }

    // MARK: - Whole Arc Movement
    static func adjustTaskTimesForWholeArcMove(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date, newEndTime: Date) {
        // Проверяем валидность времени
        guard validateTimeChange(viewModel: viewModel, newTime: newStartTime),
              validateTimeChange(viewModel: viewModel, newTime: newEndTime) else {
            return
        }
        
        // Находим оптимальное место для задачи
        let optimalPlacement = findOptimalTaskPlacement(
            viewModel: viewModel,
            currentTask: currentTask,
            preferredStartTime: newStartTime,
            taskDuration: currentTask.duration
        )
        
        // Обновляем задачу в оптимальном месте
        viewModel.taskManagement.updateWholeTask(
            currentTask,
            newStartTime: optimalPlacement.startTime,
            newEndTime: optimalPlacement.endTime
        )
        
        // Уведомляем об изменениях
        NotificationCenter.default.post(
            name: .taskArcsTaskMoved,
            object: viewModel,
            userInfo: [
                "movedTask": currentTask,
                "newStartTime": optimalPlacement.startTime,
                "newEndTime": optimalPlacement.endTime
            ]
        )
        
        scheduleUIUpdate(viewModel: viewModel)
    }
    
    // MARK: - Free Time Slot Finding
    static func findFreeTimeSlotForWholeArc(
        viewModel: ClockViewModel,
        currentTask: TaskOnRing,
        preferredStartTime: Date,
        taskDuration: TimeInterval
    ) -> (startTime: Date, endTime: Date) {
        
        return findOptimalTaskPlacement(
            viewModel: viewModel,
            currentTask: currentTask,
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration
        )
    }
    
    // MARK: - Smart Conflict Resolution
    static func resolveTaskConflicts(viewModel: ClockViewModel, conflictingGroups: [[TaskOnRing]]) {
        for group in conflictingGroups {
            guard group.count > 1 else { continue }
            
            // Сортируем задачи по приоритету (например, по времени создания или важности)
            let sortedTasks = prioritizeTasks(group)
            
            // Размещаем задачи без перекрытий
            redistributeTasksInGroup(viewModel: viewModel, tasks: sortedTasks)
        }
        
        scheduleUIUpdate(viewModel: viewModel)
    }
    
    // MARK: - Private Helper Methods
    
    private static func validateTimeChange(viewModel: ClockViewModel, newTime: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        return newTime >= startOfDay && newTime <= endOfDay
    }
    
    private static func findAffectedTasksForStartTimeChange(
        viewModel: ClockViewModel,
        updatedTask: TaskOnRing
    ) -> [(TaskOnRing, Date, Date)] {
        
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.startTime >= otherTask.startTime && updatedTask.startTime < otherTask.endTime {
                let taskDuration = otherTask.duration
                let idealNewEndTime = updatedTask.startTime
                let idealNewStartTime = idealNewEndTime.addingTimeInterval(-taskDuration)
                
                if idealNewStartTime >= startOfDay {
                    tasksToUpdate.append((otherTask, idealNewStartTime, idealNewEndTime))
                } else {
                    let availableStartTime = startOfDay
                    let availableEndTime = idealNewEndTime
                    let availableTimeInterval = availableEndTime.timeIntervalSince(availableStartTime)
                    
                    if availableTimeInterval >= Constants.minimumDuration {
                        tasksToUpdate.append((otherTask, availableStartTime, availableEndTime))
                    } else {
                        let freePlacement = findOptimalTaskPlacement(
                            viewModel: viewModel,
                            currentTask: otherTask,
                            preferredStartTime: idealNewEndTime.addingTimeInterval(Constants.minimumDuration),
                            taskDuration: taskDuration
                        )
                        tasksToUpdate.append((otherTask, freePlacement.startTime, freePlacement.endTime))
                    }
                }
            }
        }
        
        return tasksToUpdate
    }
    
    private static func findAffectedTasksForEndTimeChange(
        viewModel: ClockViewModel,
        updatedTask: TaskOnRing
    ) -> [(TaskOnRing, Date, Date)] {
        
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime {
                let taskDuration = otherTask.duration
                let idealNewStartTime = updatedTask.endTime
                let idealNewEndTime = idealNewStartTime.addingTimeInterval(taskDuration)
                
                if idealNewEndTime <= endOfDay {
                    tasksToUpdate.append((otherTask, idealNewStartTime, idealNewEndTime))
                } else {
                    let availableStartTime = idealNewStartTime
                    let availableEndTime = endOfDay
                    let availableTimeInterval = availableEndTime.timeIntervalSince(availableStartTime)
                    
                    if availableTimeInterval >= Constants.minimumDuration {
                        tasksToUpdate.append((otherTask, availableStartTime, availableEndTime))
                    } else {
                        let freePlacement = findOptimalTaskPlacement(
                            viewModel: viewModel,
                            currentTask: otherTask,
                            preferredStartTime: updatedTask.endTime.addingTimeInterval(-taskDuration - Constants.minimumDuration),
                            taskDuration: taskDuration
                        )
                        tasksToUpdate.append((otherTask, freePlacement.startTime, freePlacement.endTime))
                    }
                }
            }
        }
        
        return tasksToUpdate
    }
    
    private static func processTaskOverlaps(viewModel: ClockViewModel, affectedTasks: [(TaskOnRing, Date, Date)]) {
        for (task, newStart, newEnd) in affectedTasks {
            viewModel.taskManagement.updateWholeTask(task, newStartTime: newStart, newEndTime: newEnd)
        }
    }
    
    private static func findOptimalTaskPlacement(
        viewModel: ClockViewModel,
        currentTask: TaskOnRing,
        preferredStartTime: Date,
        taskDuration: TimeInterval
    ) -> (startTime: Date, endTime: Date) {
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60)
        
        // Получаем все задачи кроме текущей, отсортированные по времени начала
        let otherTasks = viewModel.tasks
            .filter { $0.id != currentTask.id }
            .sorted { $0.startTime < $1.startTime }
        
        // Функция проверки свободности временного слота
        func isTimeSlotFree(startTime: Date, endTime: Date) -> Bool {
            guard startTime >= startOfDay && endTime <= endOfDay else { return false }
            
            for task in otherTasks {
                if startTime < task.endTime && endTime > task.startTime {
                    return false
                }
            }
            return true
        }
        
        let preferredEndTime = preferredStartTime.addingTimeInterval(taskDuration)
        
        // Проверяем предпочтительное время
        if isTimeSlotFree(startTime: preferredStartTime, endTime: preferredEndTime) {
            return (startTime: preferredStartTime, endTime: preferredEndTime)
        }
        
        // Используем умный поиск ближайшего свободного места
        return findNearestFreeSlot(
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            otherTasks: otherTasks,
            startOfDay: startOfDay,
            endOfDay: endOfDay,
            isTimeSlotFree: isTimeSlotFree
        )
    }
    
    private static func findNearestFreeSlot(
        preferredStartTime: Date,
        taskDuration: TimeInterval,
        otherTasks: [TaskOnRing],
        startOfDay: Date,
        endOfDay: Date,
        isTimeSlotFree: (Date, Date) -> Bool
    ) -> (startTime: Date, endTime: Date) {
        
        // Поиск в радиусе предпочтительного времени
        for offset in stride(from: Constants.searchStep, to: Constants.maxSearchRadius, by: Constants.searchStep) {
            // Справа от предпочтительного времени
            let rightStartTime = preferredStartTime.addingTimeInterval(offset)
            let rightEndTime = rightStartTime.addingTimeInterval(taskDuration)
            
            if isTimeSlotFree(rightStartTime, rightEndTime) {
                return (startTime: rightStartTime, endTime: rightEndTime)
            }
            
            // Слева от предпочтительного времени
            let leftStartTime = preferredStartTime.addingTimeInterval(-offset)
            let leftEndTime = leftStartTime.addingTimeInterval(taskDuration)
            
            if isTimeSlotFree(leftStartTime, leftEndTime) {
                return (startTime: leftStartTime, endTime: leftEndTime)
            }
        }
        
        // Если не найдено в радиусе, ищем первое доступное место
        return findFirstAvailableSlot(
            taskDuration: taskDuration,
            otherTasks: otherTasks,
            startOfDay: startOfDay,
            endOfDay: endOfDay,
            preferredStartTime: preferredStartTime
        )
    }
    
    private static func findFirstAvailableSlot(
        taskDuration: TimeInterval,
        otherTasks: [TaskOnRing],
        startOfDay: Date,
        endOfDay: Date,
        preferredStartTime: Date
    ) -> (startTime: Date, endTime: Date) {
        
        if otherTasks.isEmpty {
            let startTime = max(startOfDay, preferredStartTime)
            let endTime = startTime.addingTimeInterval(taskDuration)
            return (startTime: startTime, endTime: min(endTime, endOfDay))
        }
        
        // Проверяем место перед первой задачей
        if otherTasks.first!.startTime.timeIntervalSince(startOfDay) >= taskDuration {
            let endTime = otherTasks.first!.startTime
            let startTime = endTime.addingTimeInterval(-taskDuration)
            if startTime >= startOfDay {
                return (startTime: startTime, endTime: endTime)
            }
        }
        
        // Ищем промежутки между задачами
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
            let availableTime = endOfDay.timeIntervalSince(lastTask.endTime)
            if availableTime >= taskDuration {
                return (startTime: lastTask.endTime, endTime: lastTask.endTime.addingTimeInterval(taskDuration))
            }
        }
        
        // В крайнем случае возвращаем оригинальное время
        return (startTime: preferredStartTime, endTime: preferredStartTime.addingTimeInterval(taskDuration))
    }
    
    private static func prioritizeTasks(_ tasks: [TaskOnRing]) -> [TaskOnRing] {
        return tasks.sorted { task1, task2 in
            // Приоритет по времени начала (более ранние задачи имеют приоритет)
            if task1.startTime != task2.startTime {
                return task1.startTime < task2.startTime
            }
            
            // Если время начала одинаковое, приоритет по длительности (более короткие задачи имеют приоритет)
            return task1.duration < task2.duration
        }
    }
    
    private static func redistributeTasksInGroup(viewModel: ClockViewModel, tasks: [TaskOnRing]) {
        guard tasks.count > 1 else { return }
        
        var currentTime = tasks.first!.startTime
        
        for task in tasks {
            let optimalPlacement = findOptimalTaskPlacement(
                viewModel: viewModel,
                currentTask: task,
                preferredStartTime: currentTime,
                taskDuration: task.duration
            )
            
            viewModel.taskManagement.updateWholeTask(
                task,
                newStartTime: optimalPlacement.startTime,
                newEndTime: optimalPlacement.endTime
            )
            
            currentTime = optimalPlacement.endTime.addingTimeInterval(Constants.minimumDuration)
        }
    }
    
    private static func notifyTaskArcsAboutOverlapChanges(viewModel: ClockViewModel, changedTasks: [(TaskOnRing, Date, Date)]) {
        let modifiedTasks = changedTasks.map { $0.0 }
        
        if !modifiedTasks.isEmpty {
            NotificationCenter.default.post(
                name: .taskArcsOverlapResolved,
                object: viewModel,
                userInfo: ["resolvedTasks": modifiedTasks]
            )
        }
    }
    
    private static func scheduleUIUpdate(viewModel: ClockViewModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.uiUpdateDelay) {
            viewModel.objectWillChange.send()
        }
    }
}

// MARK: - TaskOverlapManager Notification Extensions
extension Notification.Name {
    static let taskArcsTaskMoved = Notification.Name("TaskArcsTaskMoved")
    static let taskArcsOverlapResolved = Notification.Name("TaskArcsOverlapResolved")
} 