//
//  CoreDataCategoryRepository.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import CoreData
import SwiftUI
import OSLog

/// Упрощенная реализация CategoryRepository для компиляции
final class CoreDataCategoryRepository: CategoryRepositoryProtocol {
    
    // MARK: - Properties
    private let context: NSManagedObjectContext
    private let logger = Logger(subsystem: "TaskFl0w", category: "CoreDataCategoryRepository")
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    

    
    // MARK: - Helper Methods
    
    /// Проверяет наличие несохраненных изменений
    func hasUnsavedChanges() -> Bool {
        context.hasChanges
    }

    // MARK: - Fetch Helpers
    private func entity(for id: UUID) throws -> CategoryEntity? {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - CRUD
    func fetchAll() async throws -> [TaskCategoryModel] {
        try await context.perform {
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            let entities = try self.context.fetch(request)
            return entities.map { $0.categoryModel }
        }
    }

    func save(_ category: TaskCategoryModel) async throws {
        try await context.perform {
            _ = CategoryEntity.from(category, context: self.context)
            try self.saveContext()
        }
    }

    func update(_ category: TaskCategoryModel) async throws {
        try await context.perform {
            guard let entity = try self.entity(for: category.id) else { return }
            entity.name = category.rawValue
            entity.iconName = category.iconName
            entity.colorHex = category.color.toHex()
            entity.isHidden = category.isHidden
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

    // MARK: - Query
    func fetchCategory(by id: UUID) async throws -> TaskCategoryModel? {
        try await context.perform {
            try self.entity(for: id)?.categoryModel
        }
    }

    func fetchVisibleCategories() async throws -> [TaskCategoryModel] {
        try await context.perform {
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            request.predicate = NSPredicate(format: "isHidden == NO")
            let entities = try self.context.fetch(request)
            return entities.map { $0.categoryModel }
        }
    }

    func fetchHiddenCategories() async throws -> [TaskCategoryModel] {
        try await context.perform {
            let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
            request.predicate = NSPredicate(format: "isHidden == YES")
            let entities = try self.context.fetch(request)
            return entities.map { $0.categoryModel }
        }
    }

    // MARK: - Private
    private func saveContext() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
} 