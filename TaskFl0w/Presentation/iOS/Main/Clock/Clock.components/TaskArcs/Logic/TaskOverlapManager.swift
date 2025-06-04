//
//  TaskOverlapManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskOverlapManager {
    static func adjustTaskStartTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date) {
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.startTime = newStartTime
        
        // Обновляем задачу в базе данных
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(currentTask, newStartTime: newStartTime)

        // Создаем массив задач для обновления, чтобы избежать множественных изменений
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.startTime >= otherTask.startTime && updatedTask.startTime < otherTask.endTime {
                // Вместо уменьшения времени другой задачи, сдвигаем её целиком
                let taskDuration = otherTask.duration
                let newOtherEndTime = updatedTask.startTime
                let newOtherStartTime = newOtherEndTime.addingTimeInterval(-taskDuration)
                
                // Проверяем, что новое время не выходит за границы дня
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
                
                if newOtherStartTime >= startOfDay {
                    // Добавляем в список для обновления
                    tasksToUpdate.append((otherTask, newOtherStartTime, newOtherEndTime))
                } else {
                    // Если не можем сдвинуть назад, находим свободное место
                    let freePlacement = findFreeTimeSlot(
                        viewModel: viewModel,
                        currentTask: otherTask,
                        preferredStartTime: otherTask.startTime,
                        taskDuration: taskDuration
                    )
                    
                    // Добавляем в список для обновления
                    tasksToUpdate.append((otherTask, freePlacement.startTime, freePlacement.endTime))
                }
            }
        }
        
        // Обновляем все найденные задачи через taskManagement
        for (task, newStart, newEnd) in tasksToUpdate {
            // Обновляем только через taskManagement для сохранения в базе данных
            viewModel.taskManagement.updateWholeTask(task, newStartTime: newStart, newEndTime: newEnd)
        }
        
        // Принудительно обновляем UI с небольшой задержкой для синхронизации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.objectWillChange.send()
        }
    }

    static func adjustTaskEndTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newEndTime: Date) {
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.endTime = newEndTime
        
        // Обновляем задачу в базе данных
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        // Создаем массив задач для обновления, чтобы избежать множественных изменений
        var tasksToUpdate: [(TaskOnRing, Date, Date)] = []

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime {
                // Вместо уменьшения времени другой задачи, сдвигаем её целиком
                let taskDuration = otherTask.duration
                let newOtherStartTime = updatedTask.endTime
                let newOtherEndTime = newOtherStartTime.addingTimeInterval(taskDuration)
                
                // Проверяем, что новое время не выходит за границы дня
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60) // 23:59
                
                if newOtherEndTime <= endOfDay {
                    // Добавляем в список для обновления
                    tasksToUpdate.append((otherTask, newOtherStartTime, newOtherEndTime))
                } else {
                    // Если не можем сдвинуть вперед, находим свободное место
                    let freePlacement = findFreeTimeSlot(
                        viewModel: viewModel,
                        currentTask: otherTask,
                        preferredStartTime: otherTask.startTime,
                        taskDuration: taskDuration
                    )
                    
                    // Добавляем в список для обновления
                    tasksToUpdate.append((otherTask, freePlacement.startTime, freePlacement.endTime))
                }
            }
        }
        
        // Обновляем все найденные задачи через taskManagement
        for (task, newStart, newEnd) in tasksToUpdate {
            // Обновляем только через taskManagement для сохранения в базе данных
            viewModel.taskManagement.updateWholeTask(task, newStartTime: newStart, newEndTime: newEnd)
        }
        
        // Принудительно обновляем UI с небольшой задержкой для синхронизации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.objectWillChange.send()
        }
    }

    // Новый метод для обработки перекрытий при перемещении всей дуги
    static func adjustTaskTimesForWholeArcMove(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date, newEndTime: Date) {
        // Находим ближайшее свободное место для задачи
        let freePlacement = findFreeTimeSlot(
            viewModel: viewModel,
            currentTask: currentTask,
            preferredStartTime: newStartTime,
            taskDuration: currentTask.duration
        )
        
        // Обновляем задачу в свободном месте
        viewModel.taskManagement.updateWholeTask(
            currentTask,
            newStartTime: freePlacement.startTime,
            newEndTime: freePlacement.endTime
        )
    }
    
    // Публичный метод для поиска свободного временного слота при завершении перетаскивания
    static func findFreeTimeSlotForWholeArc(
        viewModel: ClockViewModel,
        currentTask: TaskOnRing,
        preferredStartTime: Date,
        taskDuration: TimeInterval
    ) -> (startTime: Date, endTime: Date) {
        
        return findFreeTimeSlot(
            viewModel: viewModel,
            currentTask: currentTask,
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration
        )
    }
    
    // Делаем приватный метод публичным (убираем private)
    static func findFreeTimeSlot(
        viewModel: ClockViewModel,
        currentTask: TaskOnRing,
        preferredStartTime: Date,
        taskDuration: TimeInterval
    ) -> (startTime: Date, endTime: Date) {
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: viewModel.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-60) // 23:59
        
        // Получаем все задачи кроме текущей, отсортированные по времени начала
        let otherTasks = viewModel.tasks
            .filter { $0.id != currentTask.id }
            .sorted { $0.startTime < $1.startTime }
        
        // Функция проверки свободности временного слота
        func isTimeSlotFree(startTime: Date, endTime: Date) -> Bool {
            // Проверяем границы дня
            guard startTime >= startOfDay && endTime <= endOfDay else { return false }
            
            // Проверяем пересечения с другими задачами
            for task in otherTasks {
                if startTime < task.endTime && endTime > task.startTime {
                    return false
                }
            }
            return true
        }
        
        let preferredEndTime = preferredStartTime.addingTimeInterval(taskDuration)
        
        // Сначала проверяем предпочтительное время
        if isTimeSlotFree(startTime: preferredStartTime, endTime: preferredEndTime) {
            return (startTime: preferredStartTime, endTime: preferredEndTime)
        }
        
        // Если предпочтительное время занято, ищем ближайшее свободное место
        
        // Проверяем места слева и справа от предпочтительного времени
        let searchStep: TimeInterval = 15 * 60 // 15 минут
        let maxSearchRadius: TimeInterval = 12 * 60 * 60 // 12 часов
        
        for offset in stride(from: searchStep, to: maxSearchRadius, by: searchStep) {
            // Проверяем справа от предпочтительного времени
            let rightStartTime = preferredStartTime.addingTimeInterval(offset)
            let rightEndTime = rightStartTime.addingTimeInterval(taskDuration)
            
            if isTimeSlotFree(startTime: rightStartTime, endTime: rightEndTime) {
                return (startTime: rightStartTime, endTime: rightEndTime)
            }
            
            // Проверяем слева от предпочтительного времени
            let leftStartTime = preferredStartTime.addingTimeInterval(-offset)
            let leftEndTime = leftStartTime.addingTimeInterval(taskDuration)
            
            if isTimeSlotFree(startTime: leftStartTime, endTime: leftEndTime) {
                return (startTime: leftStartTime, endTime: leftEndTime)
            }
        }
        
        // Если не нашли свободное место в радиусе поиска, находим первое доступное место
        if otherTasks.isEmpty {
            // Если нет других задач, размещаем в начале дня
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
        
        // В крайнем случае возвращаем оригинальное время (не должно произойти)
        return (startTime: preferredStartTime, endTime: preferredEndTime)
    }
} 