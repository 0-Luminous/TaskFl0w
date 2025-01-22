import Foundation
import CoreData
import SwiftUI

protocol TaskManagementProtocol {
    func addTask(_ task: Task)
    func updateTask(_ task: Task)
    func removeTask(_ task: Task)
    func updateTaskStartTimeKeepingEnd(_ task: Task, newStartTime: Date)
    func updateTaskStartTime(_ task: Task, newStartTime: Date)
    func updateTaskDuration(_ task: Task, newEndTime: Date)
    func fetchTasks()
}

class TaskManagement: TaskManagementProtocol {
    private let sharedState: SharedStateService
    private let selectedDate: Date
    
    init(sharedState: SharedStateService = .shared, selectedDate: Date) {
        self.sharedState = sharedState
        self.selectedDate = selectedDate
        fetchTasks()
    }
    
    func fetchTasks() {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let taskEntities = try sharedState.context.fetch(request)
            sharedState.tasks = taskEntities.map { $0.taskModel }
        } catch {
            print("Ошибка при загрузке задач: \(error)")
        }
    }
    
    func addTask(_ task: Task) {
        // Убедимся, что время задачи соответствует выбранной дате
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: task.startTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        if let correctedDate = calendar.date(from: components) {
            var newTask = task
            newTask.startTime = correctedDate
            sharedState.tasks.append(newTask)
        }
    }
    
    func updateTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try sharedState.context.fetch(request).first {
                existingTask.title = task.title
                existingTask.startTime = task.startTime
                existingTask.duration = task.duration
                existingTask.isCompleted = task.isCompleted
                
                // Обновляем категорию
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", task.category.id as CVarArg)
                if let category = try sharedState.context.fetch(categoryRequest).first {
                    existingTask.category = category
                }
                
                sharedState.saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при обновлении задачи: \(error)")
        }
    }
    
    func removeTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let taskToDelete = try sharedState.context.fetch(request).first {
                sharedState.context.delete(taskToDelete)
                sharedState.saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при удалении задачи: \(error)")
        }
    }
    
    func updateTaskStartTimeKeepingEnd(_ task: Task, newStartTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        let oldEndTime = task.startTime.addingTimeInterval(task.duration)
        
        // Создаем компоненты для новой даты, сохраняя день из selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let newStart = calendar.date(from: components) else { return }
        
        // Вычисляем новую продолжительность
        let newDuration = oldEndTime.timeIntervalSince(newStart)
        
        // Обновляем только конкретную задачу
        var updatedTask = task
        updatedTask.startTime = newStart
        updatedTask.duration = max(0, newDuration)
        
        sharedState.tasks[index] = updatedTask
    }
    
    func updateTaskStartTime(_ task: Task, newStartTime: Date) {
        if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.startTime = newStartTime
            sharedState.tasks[index] = updatedTask
            updateTask(updatedTask)
        }
    }
    
    func updateTaskDuration(_ task: Task, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        
        // Создаем компоненты для новой даты окончания
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let newEnd = calendar.date(from: components) else { return }
        
        // Вычисляем новую продолжительность
        let newDuration = newEnd.timeIntervalSince(task.startTime)
        
        // Обновляем только конкретную задачу
        var updatedTask = task
        updatedTask.duration = max(0, newDuration)
        
        sharedState.tasks[index] = updatedTask
    }
    
    private func validateTimeInterval(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return max(0, min(interval, 24 * 60 * 60)) // Максимум 24 часа
    }
} 