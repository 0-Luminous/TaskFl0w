//
//  CategoryRepositoryProtocol.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI

/// Протокол для работы с данными категорий
protocol CategoryRepositoryProtocol: AnyObject {
    
    // MARK: - Basic CRUD Operations
    func fetchAll() async throws -> [TaskCategoryModel]
    func save(_ category: TaskCategoryModel) async throws
    func update(_ category: TaskCategoryModel) async throws
    func delete(id: UUID) async throws
    
    // MARK: - Query Operations
    func fetchCategory(by id: UUID) async throws -> TaskCategoryModel?
    func fetchVisibleCategories() async throws -> [TaskCategoryModel]
    func fetchHiddenCategories() async throws -> [TaskCategoryModel]
    
    // MARK: - State
    func hasUnsavedChanges() -> Bool
} 