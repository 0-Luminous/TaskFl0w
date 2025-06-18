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
final class CoreDataTaskRepository {
    
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
        return context.hasChanges
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
} 