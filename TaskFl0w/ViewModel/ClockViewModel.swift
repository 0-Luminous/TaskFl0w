//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine
import CoreData

final class ClockViewModel: ObservableObject {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    // MARK: - Published properties
    
    @Published var tasks: [Task] = []
    @Published var categories: [TaskCategoryModel] = [
        TaskCategoryModel(id: UUID(), rawValue: "Работа", iconName: "macbook", color: .blue),
        TaskCategoryModel(id: UUID(), rawValue: "Спорт", iconName: "figure.strengthtraining.traditional", color: .green),
        TaskCategoryModel(id: UUID(), rawValue: "Развлечения", iconName: "gamecontroller", color: .red)
    ]
    
    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date()
    
    // В этот флаг можно прокидывать логику тёмной/светлой темы, если нужно
    @AppStorage("isDarkMode") var isDarkMode = false
    
    // Пример использования AppStorage для цвета циферблата
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()
    
    @Published var isDockBarEditingEnabled: Bool = false
    
    // MARK: - Инициализация
    
    init() {
        container = PersistenceController.shared.container
        context = container.viewContext
        
        fetchCategories()
        fetchTasks()
    }
    
    // MARK: - CoreData методы
    private func fetchCategories() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let categoryEntities = try context.fetch(request)
            categories = categoryEntities.map { $0.categoryModel }
        } catch {
            print("Ошибка при загрузке категорий: \(error)")
        }
    }
    
    private func fetchTasks() {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let taskEntities = try context.fetch(request)
            tasks = taskEntities.map { $0.taskModel }
        } catch {
            print("Ошибка при загрузке задач: \(error)")
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
    
    // MARK: - Методы работы с задачами
    
    func addTask(_ task: Task) {
        let taskEntity = TaskEntity.from(task, context: context)
        context.insert(taskEntity)
        saveContext()
        fetchTasks()
    }
    
    func updateTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                existingTask.title = task.title
                existingTask.startTime = task.startTime
                existingTask.duration = task.duration
                existingTask.isCompleted = task.isCompleted
                
                // Обновляем категорию
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", task.category.id as CVarArg)
                if let category = try context.fetch(categoryRequest).first {
                    existingTask.category = category
                }
                
                saveContext()
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
            if let taskToDelete = try context.fetch(request).first {
                context.delete(taskToDelete)
                saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при удалении задачи: \(error)")
        }
    }
    
    // MARK: - Методы работы с категориями
    
    func addCategory(_ category: TaskCategoryModel) {
        categories.append(category)
    }
    
    func updateCategory(_ category: TaskCategoryModel) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            // Обновляем все задачи, связанные с этой категорией
            tasks = tasks.map { task in
                if task.category.id == category.id {
                    return Task(
                        id: task.id,
                        title: task.title,
                        startTime: task.startTime,
                        duration: task.duration,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: task.isCompleted
                    )
                }
                return task
            }
        }
    }
    
    func removeCategory(_ category: TaskCategoryModel) {
        // Удаляем все задачи, связанные с этой категорией
        tasks.removeAll { task in
            task.category.id == category.id
        }
        
        // Удаляем саму категорию
        categories.removeAll { $0.id == category.id }
    }
    
    func updateTaskStartTimeKeepingEnd(_ task: Task, newStartTime: Date) {
        if let index = tasks.firstIndex(of: task) {
            let endTime = task.startTime.addingTimeInterval(task.duration)
            let newDuration = endTime.timeIntervalSince(newStartTime)
            
            // Минимальная длительность задачи (например, 5 минут)
            let minDuration: TimeInterval = 5 * 60
            
            if newDuration >= minDuration {
                var updatedTask = task
                updatedTask.startTime = newStartTime
                updatedTask.duration = newDuration
                tasks[index] = updatedTask
            }
        }
    }
    
    private func validateTimeInterval(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return max(0, min(interval, 24 * 60 * 60)) // Максимум 24 часа
    }
    
    func updateTaskStartTime(_ task: Task, newStartTime: Date) {
        guard newStartTime.timeIntervalSince1970.isFinite else { return }
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.startTime = newStartTime
            updatedTask.duration = validateTimeInterval(updatedTask.duration)
            tasks[index] = updatedTask
            updateTask(updatedTask)
        }
    }
    
    func updateTaskDuration(_ task: Task, newEndTime: Date) {
        let duration = newEndTime.timeIntervalSince(task.startTime)
        let validDuration = validateTimeInterval(duration)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.duration = validDuration
            tasks[index] = updatedTask
            updateTask(updatedTask)
        }
    }
}
