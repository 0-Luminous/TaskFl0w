//
//  TaskRepositoryProtocol.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI

/// Протокол для работы с данными задач
protocol TaskRepositoryProtocol: AnyObject {
    
    // MARK: - Basic CRUD Operations
    func fetch(for date: Date) async throws -> [TaskOnRing]
    func fetchAll() async throws -> [TaskOnRing]
    func save(_ task: TaskOnRing) async throws
    func update(_ task: TaskOnRing) async throws
    func delete(id: UUID) async throws
    
    // MARK: - Query Operations
    func fetchTasks(in dateRange: ClosedRange<Date>) async throws -> [TaskOnRing]
    func fetchTasks(for category: TaskCategoryModel) async throws -> [TaskOnRing]
    func fetchActiveTasks(at date: Date) async throws -> [TaskOnRing]
    func fetchCompletedTasks(for date: Date) async throws -> [TaskOnRing]
    
    // MARK: - Batch Operations
    func saveBatch(_ tasks: [TaskOnRing]) async throws
    func deleteBatch(ids: [UUID]) async throws
    
    // MARK: - Validation
    func findOverlappingTasks(for task: TaskOnRing) async throws -> [TaskOnRing]
    func hasUnsavedChanges() -> Bool
} 