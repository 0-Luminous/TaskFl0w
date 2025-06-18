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
final class CoreDataCategoryRepository {
    
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
        return context.hasChanges
    }
} 