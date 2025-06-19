//
//  TaskService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import CoreData
import Combine
import SwiftUI
import OSLog

// MARK: - Task Service Protocol
@MainActor
protocol TaskServiceProtocol: AnyObject {
    func loadTasks(for date: Date) async throws -> [TaskItem]
    func saveTasks(_ tasks: [TaskItem]) async throws
    func deleteTask(with id: UUID) async throws
    func updateTask(_ task: TaskItem) async throws
    func createTask(_ task: TaskItem) async throws
}

// MARK: - Task Item Model
struct TaskItem {
    let id: UUID
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool
    var categoryName: String
    
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        isCompleted: Bool = false,
        categoryName: String
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.categoryName = categoryName
    }
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)ч \(minutes)м"
        } else {
            return "\(minutes)м"
        }
    }
}

// MARK: - Task Service Implementation
@MainActor
final class TaskService: TaskServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "TaskFl0w", category: "TaskService")
    private let errorHandler = ErrorHandler.shared
    
    @Published private(set) var tasks: [TaskItem] = []
    @Published private(set) var isLoading = false
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Protocol Implementation
    func loadTasks(for date: Date) async throws -> [TaskItem] {
        isLoading = true
        defer { isLoading = false }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        do {
            let request = createFetchRequest(from: startOfDay, to: endOfDay)
            let results = try context.fetch(request)
            
            let taskItems = results.compactMap { entity -> TaskItem? in
                guard let id = entity.id,
                      let startTime = entity.startTime,
                      let endTime = entity.endTime else {
                    logger.warning("Задача с некорректными данными пропущена")
                    return nil
                }
                
                return TaskItem(
                    id: id,
                    startTime: startTime,
                    endTime: endTime,
                    isCompleted: entity.isCompleted,
                    categoryName: entity.category?.name ?? "Без категории"
                )
            }
            
            self.tasks = taskItems
            logger.info("Загружено \(taskItems.count) задач для даты \(date)")
            return taskItems
            
        } catch {
            errorHandler.handleDataError(error, in: "TaskService", operation: "loadTasks")
            throw error
        }
    }
    
    func saveTasks(_ tasks: [TaskItem]) async throws {
        guard !tasks.isEmpty else { return }
        
        do {
            // Сохраняем каждую задачу
            for task in tasks {
                try await updateOrCreateTaskEntity(from: task)
            }
            
            // Сохраняем контекст
            if context.hasChanges {
                try context.save()
                logger.info("Сохранено \(tasks.count) задач")
            }
            
        } catch {
            errorHandler.handleDataError(error, in: "TaskService", operation: "saveTasks")
            throw error
        }
    }
    
    func deleteTask(with id: UUID) async throws {
        do {
            let request: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
            
            if context.hasChanges {
                try context.save()
            }
            
            // Обновляем локальный массив
            tasks.removeAll { $0.id == id }
            
            logger.info("Задача удалена: \(id)")
            
        } catch {
            errorHandler.handleDataError(error, in: "TaskService", operation: "deleteTask")
            throw error
        }
    }
    
    func updateTask(_ task: TaskItem) async throws {
        do {
            try await updateOrCreateTaskEntity(from: task)
            
            if context.hasChanges {
                try context.save()
            }
            
            // Обновляем локальный массив
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
            
            logger.info("Задача обновлена: \(task.id)")
            
        } catch {
            errorHandler.handleDataError(error, in: "TaskService", operation: "updateTask")
            throw error
        }
    }
    
    func createTask(_ task: TaskItem) async throws {
        do {
            try await updateOrCreateTaskEntity(from: task)
            
            if context.hasChanges {
                try context.save()
            }
            
            // Добавляем в локальный массив
            tasks.append(task)
            
            logger.info("Задача создана: \(task.id)")
            
        } catch {
            errorHandler.handleDataError(error, in: "TaskService", operation: "createTask")
            throw error
        }
    }
    
    // MARK: - Private Methods
    private func createFetchRequest(from startDate: Date, to endDate: Date) -> NSFetchRequest<TaskEntity> {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(
            format: "startTime >= %@ AND startTime < %@",
            startDate as NSDate,
            endDate as NSDate
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)
        ]
        return request
    }
    
    private func updateOrCreateTaskEntity(from task: TaskItem) async throws {
        // Ищем существующую задачу
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        request.fetchLimit = 1
        
        let results = try context.fetch(request)
        let entity = results.first ?? TaskEntity(context: context)
        
        // Обновляем данные (только те свойства, которые есть в TaskEntity)
        entity.id = task.id
        entity.startTime = task.startTime
        entity.endTime = task.endTime
        entity.isCompleted = task.isCompleted
        
        // Поиск и установка категории
        if !task.categoryName.isEmpty {
            let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            categoryRequest.predicate = NSPredicate(format: "name == %@", task.categoryName)
            categoryRequest.fetchLimit = 1
            
            if let categoryEntity = try context.fetch(categoryRequest).first {
                entity.category = categoryEntity
            }
        }
    }
    
    // MARK: - Convenience Methods
    func getTasksForToday() async throws -> [TaskItem] {
        return try await loadTasks(for: Date())
    }
    
    func getCompletedTasks(for date: Date) async throws -> [TaskItem] {
        let allTasks = try await loadTasks(for: date)
        return allTasks.filter { $0.isCompleted }
    }
    
    func getTotalDuration(for tasks: [TaskItem]) -> TimeInterval {
        return tasks.reduce(0) { $0 + $1.duration }
    }
    
    func getTasksByCategory(from tasks: [TaskItem]) -> [String: [TaskItem]] {
        return Dictionary(grouping: tasks) { $0.categoryName }
    }
} 