//
//  DIContainer.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import CoreData
import SwiftUI

/// Контейнер зависимостей для всего приложения
@MainActor
final class DIContainer: ObservableObject {
    
    // MARK: - Core Dependencies
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    init(persistenceController: PersistenceController? = nil) {
        if let controller = persistenceController {
            self.persistenceController = controller
        } else {
            do {
                self.persistenceController = try PersistenceController()
            } catch {
                // Fallback to in-memory store
                self.persistenceController = try! PersistenceController(inMemory: true)
            }
        }
        self.context = self.persistenceController.container.viewContext
    }
    
    // MARK: - Repositories
    // private lazy var _taskRepository: TaskRepositoryProtocol = CoreDataTaskRepository(context: context) // Временно отключено
    // private lazy var _categoryRepository: CategoryRepositoryProtocol = CoreDataCategoryRepository(context: context) // Временно отключено
    
    // var taskRepository: TaskRepositoryProtocol { _taskRepository } // Временно отключено
    // var categoryRepository: CategoryRepositoryProtocol { _categoryRepository } // Временно отключено
    
    // MARK: - Services
    private lazy var _sharedStateService: SharedStateService = SharedStateService(context: context)
    
    private lazy var _taskService: TaskServiceProtocol = TaskService(context: context)
    
    private lazy var _validationService: ValidationServiceProtocol = ValidationService()
    private lazy var _errorHandler: ErrorHandlerProtocol = ErrorHandler.shared
    private lazy var _notificationService: NotificationServiceProtocol = NotificationService.shared
    
    var sharedStateService: SharedStateService { _sharedStateService }
    var taskService: TaskServiceProtocol { _taskService }
    var validationService: ValidationServiceProtocol { _validationService }
    var errorHandler: ErrorHandlerProtocol { _errorHandler }
    var notificationService: NotificationServiceProtocol { _notificationService }
    
    // MARK: - Navigation
    private lazy var _navigationViewModel: NavigationViewModel = NavigationViewModel()
    var navigationViewModel: NavigationViewModel { _navigationViewModel }
    
    // MARK: - ViewModels Factory
    func makeClockViewModel() -> ClockViewModel {
        // ClockViewModel() // Упрощенная инициализация до готовности всех зависимостей
        return ClockViewModel()
    }
    
    func makeTaskListViewModel() -> TaskListViewModel {
        // TaskListViewModel() // Упрощенная инициализация до готовности всех зависимостей
        return TaskListViewModel(appState: _sharedStateService)
    }
    
    func makeTaskRenderingViewModel() -> TaskRenderingViewModel {
        // TaskRenderingViewModel() // Упрощенная инициализация
        return TaskRenderingViewModel(sharedState: _sharedStateService)
    }
    
    func makeTimeManagementViewModel() -> TimeManagementViewModel {
        // TimeManagementViewModel() // Упрощенная инициализация
        return TimeManagementViewModel()
    }
    
    func makeUserInteractionViewModel() -> UserInteractionViewModel {
        // UserInteractionViewModel() // Упрощенная инициализация
        // Create a basic TaskManagement instance for UserInteractionViewModel
        let basicTaskManagement = TaskManagement(sharedState: _sharedStateService, selectedDate: Date())
        return UserInteractionViewModel(taskManagement: basicTaskManagement)
    }
    
    func makeThemeConfigurationViewModel() -> ThemeConfigurationViewModel {
        ThemeConfigurationViewModel()
    }
    
    // MARK: - Coordinator Factory
    // func makeAppCoordinator() -> AppCoordinator { // Временно отключено
    //     AppCoordinator(container: self)
    // }
}

// MARK: - Protocols Extensions
extension DIContainer {
    func resolve<T>(_ type: T.Type) -> T {
        switch type {
        // case is TaskRepositoryProtocol.Type:
        //     return taskRepository as! T // Временно отключено
        // case is CategoryRepositoryProtocol.Type:
        //     return categoryRepository as! T // Временно отключено
        case is SharedStateService.Type:
            return sharedStateService as! T
        case is TaskServiceProtocol.Type:
            return taskService as! T
        case is ValidationServiceProtocol.Type:
            return validationService as! T
        case is ErrorHandlerProtocol.Type:
            return errorHandler as! T
        case is NotificationServiceProtocol.Type:
            return notificationService as! T
        default:
            fatalError("Cannot resolve type \(type)")
        }
    }
} 