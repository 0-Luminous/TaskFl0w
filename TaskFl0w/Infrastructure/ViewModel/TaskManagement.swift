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
    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws
    func updateTask(_ task: Task, newStartTime: Date?, newEndTime: Date?) async throws
}

class TaskManagement: TaskManagementProtocol {
    private let context: NSManagedObjectContext
    private let sharedState: SharedStateService
    
    // Делаем selectedDate изменяемым свойством
    var selectedDate: Date {
        didSet {
            // При необходимости можно добавить дополнительную логику при изменении даты
        }
    }
    
    init(sharedState: SharedStateService, selectedDate: Date) {
        self.sharedState = sharedState
        self.context = sharedState.context
        self.selectedDate = selectedDate
        fetchTasks()
    }
    
    func fetchTasks() {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let taskEntities = try context.fetch(request)
            sharedState.tasks = taskEntities.map { $0.taskModel }
        } catch {
            print("Ошибка при загрузке задач: \(error)")
        }
    }
    
    func addTask(_ task: Task) {
        guard validateTask(task) else { return }
        
        // Нужно убедиться, что сохраняем правильную дату
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.startTime)
        let normalizedDate = calendar.date(from: components) ?? task.startTime
        
        var normalizedTask = task
        normalizedTask.startTime = normalizedDate
        
        let _ = TaskEntity.from(normalizedTask, context: context)
        sharedState.tasks.append(normalizedTask)
        
        saveContext()
    }
    
    func updateTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                let calendar = Calendar.current
                
                // Нормализуем время начала
                let startComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: task.startTime
                )
                
                var normalizedStartComponents = DateComponents()
                normalizedStartComponents.year = startComponents.year
                normalizedStartComponents.month = startComponents.month
                normalizedStartComponents.day = startComponents.day
                normalizedStartComponents.hour = startComponents.hour
                normalizedStartComponents.minute = startComponents.minute
                normalizedStartComponents.timeZone = TimeZone.current
                
                // Нормализуем время окончания
                let endComponents = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: task.endTime
                )
                
                var normalizedEndComponents = DateComponents()
                normalizedEndComponents.year = endComponents.year
                normalizedEndComponents.month = endComponents.month
                normalizedEndComponents.day = endComponents.day
                normalizedEndComponents.hour = endComponents.hour
                normalizedEndComponents.minute = endComponents.minute
                normalizedEndComponents.timeZone = TimeZone.current
                
                if let normalizedStartTime = calendar.date(from: normalizedStartComponents),
                   let normalizedEndTime = calendar.date(from: normalizedEndComponents) {
                    existingTask.startTime = normalizedStartTime
                    existingTask.endTime = normalizedEndTime
                }
                
                existingTask.title = task.title
                existingTask.isCompleted = task.isCompleted
                
                // Обновляем категорию
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", task.category.id as CVarArg)
                if let category = try context.fetch(categoryRequest).first {
                    existingTask.category = category
                }
                
                if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                    sharedState.tasks[index] = task
                }
                
                saveContext()
            }
        } catch {
            print("Ошибка при обновлении задачи: \(error)")
        }
    }
    
    func removeTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let taskToDelete = try context.fetch(request).first {
                context.delete(taskToDelete)
                saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при удалении задачи: \(error)")
        }
    }
    
    func updateTaskStartTimeKeepingEnd(_ task: Task, newStartTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        
        // Создаем компоненты для новой даты, сохраняя день из selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current
        
        guard let newStart = calendar.date(from: components) else { return }
        
        // Обновляем задачу с новым временем начала, сохраняя время окончания
        var updatedTask = task
        updatedTask.startTime = newStart
        
        // Обновляем в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                existingTask.startTime = newStart
                
                // Обновляем в памяти
                sharedState.tasks[index] = updatedTask
                
                // Сохраняем изменения
                saveContext()
            }
        } catch {
            print("Ошибка при обновлении времени начала задачи: \(error)")
        }
    }
    
    func updateTaskStartTime(_ task: Task, newStartTime: Date) {
        let calendar = Calendar.current
        
        // Извлекаем компоненты нового времени
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        
        // Используем selectedDate для даты
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Создаем нормализованные компоненты
        var normalizedComponents = DateComponents()
        normalizedComponents.year = selectedComponents.year
        normalizedComponents.month = selectedComponents.month
        normalizedComponents.day = selectedComponents.day
        normalizedComponents.hour = timeComponents.hour
        normalizedComponents.minute = timeComponents.minute
        normalizedComponents.timeZone = TimeZone.current
        
        if let normalizedStartTime = calendar.date(from: normalizedComponents) {
            // Сначала найдем существующую задачу в CoreData
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
            
            do {
                if let existingTask = try context.fetch(request).first {
                    // Обновляем существующую задачу вместо создания новой
                    existingTask.startTime = normalizedStartTime
                    
                    // Обновляем задачу в памяти
                    if let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) {
                        var updatedTask = task
                        updatedTask.startTime = normalizedStartTime
                        sharedState.tasks[index] = updatedTask
                    }
                    
                    // Сохраняем изменения
                    saveContext()
                }
            } catch {
                print("Ошибка при обновлении времени начала задачи: \(error)")
            }
        }
    }
    
    func updateTaskDuration(_ task: Task, newEndTime: Date) {
        guard let index = sharedState.tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        
        // Создаем компоненты для новой даты окончания, используя selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        components.timeZone = TimeZone.current
        
        guard let newEnd = calendar.date(from: components) else { return }
        
        // Обновляем задачу с новым временем окончания
        var updatedTask = task
        updatedTask.endTime = newEnd
        
        // Обновляем в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                existingTask.endTime = newEnd
                
                // Обновляем в памяти
                sharedState.tasks[index] = updatedTask
                
                // Сохраняем изменения
                saveContext()
            }
        } catch {
            print("Ошибка при обновлении времени окончания задачи: \(error)")
        }
    }
    
    private func validateTimeInterval(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return max(0, min(interval, 24 * 60 * 60)) // Максимум 24 часа
    }
    
    private func validateTask(_ task: Task) -> Bool {
        // Обновленная валидация
        return !task.title.isEmpty && task.endTime.timeIntervalSince(task.startTime) > 0
    }

    func createTask(startTime: Date, endTime: Date, category: TaskCategoryModel) async throws {
        guard startTime < endTime else {
            throw NSError(domain: "TaskErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Время начала должно быть раньше времени окончания"])
        }
        
        let calendar = Calendar.current
        
        // Нормализуем время начала
        let startComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: startTime
        )
        
        var normalizedStartComponents = DateComponents()
        normalizedStartComponents.year = startComponents.year
        normalizedStartComponents.month = startComponents.month
        normalizedStartComponents.day = startComponents.day
        normalizedStartComponents.hour = startComponents.hour
        normalizedStartComponents.minute = startComponents.minute
        normalizedStartComponents.timeZone = TimeZone.current
        
        // Нормализуем время окончания
        let endComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: endTime
        )
        
        var normalizedEndComponents = DateComponents()
        normalizedEndComponents.year = endComponents.year
        normalizedEndComponents.month = endComponents.month
        normalizedEndComponents.day = endComponents.day
        normalizedEndComponents.hour = endComponents.hour
        normalizedEndComponents.minute = endComponents.minute
        normalizedEndComponents.timeZone = TimeZone.current
        
        guard let normalizedStartTime = calendar.date(from: normalizedStartComponents),
              let normalizedEndTime = calendar.date(from: normalizedEndComponents) else {
            throw NSError(domain: "TaskErrorDomain", code: 2, userInfo: [NSLocalizedDescriptionKey: "Ошибка нормализации времени"])
        }
        
        let newTask = Task(
            id: UUID(),
            title: "Новая задача",
            startTime: normalizedStartTime,
            endTime: normalizedEndTime,
            color: category.color,
            icon: category.iconName,
            category: category,
            isCompleted: false
        )
        
        addTask(newTask)
    }

    func updateTask(_ task: Task, newStartTime: Date?, newEndTime: Date?) async throws {
        let calendar = Calendar.current
        var updatedTask = task
        
        if let newStartTime = newStartTime {
            // Нормализуем новое время начала
            var startComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: newStartTime)
            startComponents.timeZone = TimeZone.current
            
            if let normalizedStartTime = calendar.date(from: startComponents) {
                updatedTask.startTime = normalizedStartTime
            }
        }
        
        if let newEndTime = newEndTime {
            // Нормализуем новое время окончания
            var endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: newEndTime)
            endComponents.timeZone = TimeZone.current
            
            if let normalizedEndTime = calendar.date(from: endComponents) {
                updatedTask.endTime = normalizedEndTime
            }
        }
        
        // Проверяем валидность времени
        if updatedTask.endTime.timeIntervalSince(updatedTask.startTime) <= 0 {
            throw NSError(domain: "TaskErrorDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Некорректный интервал времени"])
        }
        
        // Обновляем задачу в CoreData
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", updatedTask.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                existingTask.startTime = updatedTask.startTime
                existingTask.endTime = updatedTask.endTime
                existingTask.title = updatedTask.title
                existingTask.isCompleted = updatedTask.isCompleted
                
                // Обновляем категорию если необходимо
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", updatedTask.category.id as CVarArg)
                if let category = try context.fetch(categoryRequest).first {
                    existingTask.category = category
                }
                
                // Обновляем задачу в sharedState
                if let index = sharedState.tasks.firstIndex(where: { $0.id == updatedTask.id }) {
                    sharedState.tasks[index] = updatedTask
                }
                
                saveContext()
            }
        } catch {
            throw NSError(domain: "TaskErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "Ошибка обновления задачи: \(error.localizedDescription)"])
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error)")
            }
        }
    }
} 