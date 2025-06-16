//
//  ArchitectureTypes.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI

// MARK: - Type Aliases for Architecture

/// Псевдонимы типов для использования в архитектурных компонентах
/// Эти типы уже определены в проекте, здесь мы их экспортируем

// TaskOnRing уже определен в TaskFl0w/Infrastructure/Models/Entities/TaskOnRing.swift
// TaskCategoryModel уже определен в TaskFl0w/Infrastructure/Models/Entities/TaskCategoryModel.swift

// MARK: - Additional Architecture Types

/// Протокол для TaskEntity (Core Data)
protocol TaskEntityProtocol {
    var id: UUID? { get set }
    var startTime: Date? { get set }
    var endTime: Date? { get set }
    var isCompleted: Bool { get set }
}

/// Протокол для CategoryEntity (Core Data)
protocol CategoryEntityProtocol {
    var id: UUID? { get set }
    var name: String? { get set }
    var iconName: String? { get set }
    var isHidden: Bool { get set }
}

// MARK: - Task Service Types

/// Результат операции с задачами
enum TaskOperationResult {
    case success
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}

/// Статус синхронизации данных
enum SyncStatus {
    case idle
    case syncing
    case synced
    case error(Error)
}

// MARK: - UI State Types

/// Состояние пользовательского интерфейса
struct UIState {
    var isLoading = false
    var error: String?
    var isRefreshing = false
    
    mutating func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            error = nil
        }
    }
    
    mutating func setError(_ error: Error) {
        self.error = error.localizedDescription
        isLoading = false
    }
    
    mutating func clearError() {
        error = nil
    }
} 