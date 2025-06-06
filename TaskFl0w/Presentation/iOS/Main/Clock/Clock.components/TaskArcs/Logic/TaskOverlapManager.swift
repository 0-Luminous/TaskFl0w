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
    static func adjustTaskStartTimesForOverlap(
        viewModel: ClockViewModel, 
        currentTask: TaskOnRing, 
        newStartTime: Date
    ) -> Bool {
        
        guard TaskTimeValidator.validateTimeChange(viewModel: viewModel, newTime: newStartTime) else {
            return false
        }
        
        var updatedTask = currentTask
        updatedTask.startTime = newStartTime
        
        let dayBounds = TaskTimeValidator.getDayBounds(for: viewModel.selectedDate)
        let (affectedTasks, canMove) = TaskChainAnalyzer.findCompleteTaskChainForStartTime(
            tasks: viewModel.tasks,
            initiatingTask: updatedTask,
            dayBounds: dayBounds
        )
        
        guard canMove else { return false }
        
        // Батчевое обновление для улучшения производительности
        batchUpdateTasks(viewModel: viewModel, taskUpdates: [(currentTask, newStartTime, currentTask.endTime)] + affectedTasks)
        
        notifyTaskArcsAboutOverlapChanges(viewModel: viewModel, changedTasks: affectedTasks)
        scheduleUIUpdate(viewModel: viewModel)
        return true
    }

    // MARK: - End Time Adjustment
    static func adjustTaskEndTimesForOverlap(
        viewModel: ClockViewModel, 
        currentTask: TaskOnRing, 
        newEndTime: Date
    ) -> Bool {
        
        guard TaskTimeValidator.validateTimeChange(viewModel: viewModel, newTime: newEndTime) else {
            return false
        }
        
        var updatedTask = currentTask
        updatedTask.endTime = newEndTime
        
        let dayBounds = TaskTimeValidator.getDayBounds(for: viewModel.selectedDate)
        let (affectedTasks, canMove) = TaskChainAnalyzer.findCompleteTaskChainForEndTime(
            tasks: viewModel.tasks,
            initiatingTask: updatedTask,
            dayBounds: dayBounds
        )
        
        guard canMove else { return false }
        
        batchUpdateTasks(viewModel: viewModel, taskUpdates: [(currentTask, currentTask.startTime, newEndTime)] + affectedTasks)
        
        notifyTaskArcsAboutOverlapChanges(viewModel: viewModel, changedTasks: affectedTasks)
        scheduleUIUpdate(viewModel: viewModel)
        return true
    }

    // MARK: - Whole Arc Movement
    static func adjustTaskTimesForWholeArcMove(
        viewModel: ClockViewModel, 
        currentTask: TaskOnRing, 
        newStartTime: Date, 
        newEndTime: Date
    ) {
        
        guard TaskTimeValidator.validateTimeChange(viewModel: viewModel, newTime: newStartTime),
              TaskTimeValidator.validateTimeChange(viewModel: viewModel, newTime: newEndTime) else {
            return
        }
        
        let optimalPlacement = TaskPlacementOptimizer.findOptimalTaskPlacement(
            tasks: viewModel.tasks,
            currentTask: currentTask,
            preferredStartTime: newStartTime,
            taskDuration: currentTask.duration,
            selectedDate: viewModel.selectedDate
        )
        
        viewModel.taskManagement.updateWholeTask(
            currentTask,
            newStartTime: optimalPlacement.startTime,
            newEndTime: optimalPlacement.endTime
        )
        
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
        
        return TaskPlacementOptimizer.findOptimalTaskPlacement(
            tasks: viewModel.tasks,
            currentTask: currentTask,
            preferredStartTime: preferredStartTime,
            taskDuration: taskDuration,
            selectedDate: viewModel.selectedDate
        )
    }
    
    // MARK: - Smart Conflict Resolution
    static func resolveTaskConflicts(viewModel: ClockViewModel, conflictingGroups: [[TaskOnRing]]) {
        for group in conflictingGroups {
            guard group.count > 1 else { continue }
            
            let sortedTasks = prioritizeTasks(group)
            redistributeTasksInGroup(viewModel: viewModel, tasks: sortedTasks)
        }
        
        scheduleUIUpdate(viewModel: viewModel)
    }
    
    // MARK: - Private Helper Methods
    
    private static func batchUpdateTasks(
        viewModel: ClockViewModel, 
        taskUpdates: [(TaskOnRing, Date, Date)]
    ) {
        // Группируем обновления для улучшения производительности
        if taskUpdates.count >= TaskOverlapConstants.batchProcessingThreshold {
            // Батчевое обновление
            DispatchQueue.global(qos: .userInitiated).async {
                for (task, newStart, newEnd) in taskUpdates {
                    viewModel.taskManagement.updateWholeTask(task, newStartTime: newStart, newEndTime: newEnd)
                }
            }
        } else {
            // Обычное обновление для небольшого количества задач
            for (task, newStart, newEnd) in taskUpdates {
                viewModel.taskManagement.updateWholeTask(task, newStartTime: newStart, newEndTime: newEnd)
            }
        }
    }
    
    private static func prioritizeTasks(_ tasks: [TaskOnRing]) -> [TaskOnRing] {
        return tasks.sorted { task1, task2 in
            if task1.startTime != task2.startTime {
                return task1.startTime < task2.startTime
            }
            return task1.duration < task2.duration
        }
    }
    
    private static func redistributeTasksInGroup(viewModel: ClockViewModel, tasks: [TaskOnRing]) {
        guard tasks.count > 1 else { return }
        
        var currentTime = tasks.first!.startTime
        var taskUpdates: [(TaskOnRing, Date, Date)] = []
        
        for task in tasks {
            let optimalPlacement = TaskPlacementOptimizer.findOptimalTaskPlacement(
                tasks: viewModel.tasks,
                currentTask: task,
                preferredStartTime: currentTime,
                taskDuration: task.duration,
                selectedDate: viewModel.selectedDate
            )
            
            taskUpdates.append((task, optimalPlacement.startTime, optimalPlacement.endTime))
            currentTime = optimalPlacement.endTime.addingTimeInterval(Constants.minimumDuration)
        }
        
        batchUpdateTasks(viewModel: viewModel, taskUpdates: taskUpdates)
    }
    
    private static func notifyTaskArcsAboutOverlapChanges(
        viewModel: ClockViewModel, 
        changedTasks: [(TaskOnRing, Date, Date)]
    ) {
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