//
//  CoreDataTaskRepository.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import CoreData
import SwiftUI
import OSLog

/// Упрощенная реализация TaskRepository для компиляции
final class CoreDataTaskRepository: TaskRepositoryProtocol {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "TaskFl0w", category: "CoreDataTaskRepository")
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // MARK: - Helper Methods
    
    /// Проверяет наличие несохраненных изменений
    func hasUnsavedChanges() -> Bool {
        context.hasChanges
    }
    
    /// Сохраняет контекст Core Data
    private func saveContext() async throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
            logger.debug("Контекст Core Data сохранен (задачи)")
        } catch {
            logger.error("Ошибка сохранения контекста: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Fetch Helpers
    private func fetchRequest(from startDate: Date, to endDate: Date) -> NSFetchRequest<TaskEntity> {
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

    private func entity(for id: UUID) throws -> TaskEntity? {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Basic CRUD
    func fetch(for date: Date) async throws -> [TaskOnRing] {
        try await context.perform {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? date
            let request = self.fetchRequest(from: start, to: end)
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    func fetchAll() async throws -> [TaskOnRing] {
        try await context.perform {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)
            ]
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    func save(_ task: TaskOnRing) async throws {
        try await context.perform {
            _ = TaskEntity.from(task, context: self.context)
            try self.saveContext()
        }
    }

    func update(_ task: TaskOnRing) async throws {
        try await context.perform {
            guard let entity = try self.entity(for: task.id) else { return }
            entity.startTime = task.startTime
            entity.endTime = task.endTime
            entity.isCompleted = task.isCompleted

            if let categoryEntity = try self.fetchCategory(task.category.id) {
                entity.category = categoryEntity
            }

            try self.saveContext()
        }
    }

    func delete(id: UUID) async throws {
        try await context.perform {
            if let entity = try self.entity(for: id) {
                self.context.delete(entity)
                try self.saveContext()
            }
        }
    }

    // MARK: - Query Operations
    func fetchTasks(in dateRange: ClosedRange<Date>) async throws -> [TaskOnRing] {
        try await context.perform {
            let request = self.fetchRequest(from: dateRange.lowerBound, to: dateRange.upperBound)
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    func fetchTasks(for category: TaskCategoryModel) async throws -> [TaskOnRing] {
        try await context.perform {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(format: "category.id == %@", category.id as CVarArg)
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TaskEntity.startTime, ascending: true)
            ]
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    func fetchActiveTasks(at date: Date) async throws -> [TaskOnRing] {
        try await context.perform {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(
                format: "startTime <= %@ AND endTime > %@",
                date as NSDate,
                date as NSDate
            )
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    func fetchCompletedTasks(for date: Date) async throws -> [TaskOnRing] {
        let tasksForDay = try await fetch(for: date)
        return tasksForDay.filter(\.isCompleted)
    }

    // MARK: - Batch Operations
    func saveBatch(_ tasks: [TaskOnRing]) async throws {
        guard !tasks.isEmpty else { return }
        try await context.perform {
            for task in tasks {
                _ = TaskEntity.from(task, context: self.context)
            }
            try self.saveContext()
        }
    }

    func deleteBatch(ids: [UUID]) async throws {
        guard !ids.isEmpty else { return }
        try await context.perform {
            for id in ids {
                if let entity = try self.entity(for: id) {
                    self.context.delete(entity)
                }
            }
            try self.saveContext()
        }
    }

    // MARK: - Validation
    func findOverlappingTasks(for task: TaskOnRing) async throws -> [TaskOnRing] {
        try await context.perform {
            let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
            request.predicate = NSPredicate(
                format: "startTime < %@ AND endTime > %@ AND id != %@",
                task.endTime as NSDate,
                task.startTime as NSDate,
                task.id as CVarArg
            )
            let entities = try self.context.fetch(request)
            return entities.map { $0.taskModel }
        }
    }

    // MARK: - Category Helper
    private func fetchCategory(_ id: UUID) throws -> CategoryEntity? {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
} 