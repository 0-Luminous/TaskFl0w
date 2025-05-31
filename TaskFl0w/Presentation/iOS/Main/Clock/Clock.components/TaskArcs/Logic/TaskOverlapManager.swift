//
//  TaskOverlapManager.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskOverlapManager {
    static func adjustTaskStartTimesForOverlap(viewModel: ClockViewModel, currentTask: TaskOnRing, newStartTime: Date) {
        // Обновляем задачу с новым временем начала
        viewModel.taskManagement.updateTaskStartTimeKeepingEnd(currentTask, newStartTime: newStartTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

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
        // Обновляем задачу с новым временем окончания
        viewModel.taskManagement.updateTaskDuration(currentTask, newEndTime: newEndTime)

        guard let updatedTask = viewModel.tasks.first(where: { $0.id == currentTask.id }) else {
            return
        }

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
} 