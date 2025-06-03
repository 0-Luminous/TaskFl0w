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

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.startTime >= otherTask.startTime && updatedTask.startTime < otherTask.endTime {
                if updatedTask.startTime.timeIntervalSince(otherTask.startTime) >= TaskArcConstants.minimumDuration {
                    viewModel.taskManagement.updateTaskDuration(otherTask, newEndTime: updatedTask.startTime)
                } else {
                    let safeStartTime = otherTask.endTime
                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(updatedTask, newStartTime: safeStartTime)
                }
            }
        }
    }

    static func adjustTaskEndTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newEndTime: Date) {
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.endTime = newEndTime
        
        // Обновляем задачу в базе данных
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime {
                if otherTask.endTime.timeIntervalSince(updatedTask.endTime) >= TaskArcConstants.minimumDuration {
                    viewModel.taskManagement.updateTaskStartTimeKeepingEnd(otherTask, newStartTime: updatedTask.endTime)
                } else {
                    let safeEndTime = otherTask.startTime
                    viewModel.taskManagement.updateTaskDuration(updatedTask, newEndTime: safeEndTime)
                }
            }
        }
    }

    // Новый метод для обработки перекрытий при перемещении всей дуги
    static func adjustTaskTimesForWholeArcMove(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date, newEndTime: Date) {
        // Создаем обновленную версию задачи
        var updatedTask = currentTask
        updatedTask.startTime = newStartTime
        updatedTask.endTime = newEndTime
        
        // Обрабатываем перекрытия с другими задачами
        for otherTask in viewModel.tasks where otherTask.id != updatedTask.id {
            // Проверяем пересечение с началом перемещаемой задачи
            if updatedTask.startTime >= otherTask.startTime && updatedTask.startTime < otherTask.endTime {
                // Сдвигаем другую задачу назад
                viewModel.taskManagement.updateTaskDuration(otherTask, newEndTime: updatedTask.startTime)
            }
            
            // Проверяем пересечение с концом перемещаемой задачи
            if updatedTask.endTime > otherTask.startTime && updatedTask.endTime <= otherTask.endTime {
                // Сдвигаем другую задачу вперед
                viewModel.taskManagement.updateTaskStartTimeKeepingEnd(otherTask, newStartTime: updatedTask.endTime)
            }
            
            // Проверяем полное перекрытие
            if updatedTask.startTime <= otherTask.startTime && updatedTask.endTime >= otherTask.endTime {
                // Перемещаемая задача полностью покрывает другую - сдвигаем другую за конец перемещаемой
                let duration = otherTask.duration
                let newOtherStartTime = updatedTask.endTime
                let newOtherEndTime = newOtherStartTime.addingTimeInterval(duration)
                viewModel.taskManagement.updateWholeTask(otherTask, newStartTime: newOtherStartTime, newEndTime: newOtherEndTime)
            }
        }
    }
} 