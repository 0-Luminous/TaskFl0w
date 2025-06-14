//
//  ErrorHandler.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import OSLog

// MARK: - App Error Types
enum AppError: Error, LocalizedError {
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case networkError(String)
    case validationError(String)
    case configurationError(String)
    case userPermissionDenied(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let message):
            return "Ошибка загрузки данных: \(message)"
        case .dataSaveFailed(let message):
            return "Ошибка сохранения данных: \(message)"
        case .networkError(let message):
            return "Ошибка сети: \(message)"
        case .validationError(let message):
            return "Ошибка валидации: \(message)"
        case .configurationError(let message):
            return "Ошибка конфигурации: \(message)"
        case .userPermissionDenied(let message):
            return "Отказано в разрешении: \(message)"
        case .unknownError(let message):
            return "Неизвестная ошибка: \(message)"
        }
    }
    
    var recoveryOptions: [String] {
        switch self {
        case .dataLoadFailed, .dataSaveFailed:
            return ["Повторить", "Отмена"]
        case .networkError:
            return ["Повторить", "Работать офлайн", "Отмена"]
        case .validationError:
            return ["Исправить", "Отмена"]
        case .configurationError:
            return ["Сбросить настройки", "Отмена"]
        case .userPermissionDenied:
            return ["Открыть настройки", "Отмена"]
        case .unknownError:
            return ["Перезапустить", "Отмена"]
        }
    }
}

// MARK: - Error Context
struct ErrorContext {
    let source: String
    let operation: String
    let userInfo: [String: Any]
    let timestamp: Date
    
    init(source: String, operation: String, userInfo: [String: Any] = [:]) {
        self.source = source
        self.operation = operation
        self.userInfo = userInfo
        self.timestamp = Date()
    }
}

// MARK: - Error Handler Protocol
protocol ErrorHandlerProtocol {
    func handle(_ error: Error, context: ErrorContext)
    func handle(_ error: AppError, context: ErrorContext)
    func logError(_ error: Error, context: ErrorContext)
    func showUserError(_ error: Error, context: ErrorContext)
}

// MARK: - Error Handler Implementation
@MainActor
final class ErrorHandler: ErrorHandlerProtocol, ObservableObject {
    
    // MARK: - Singleton
    static let shared = ErrorHandler()
    
    // MARK: - Published Properties
    @Published var currentError: (error: AppError, context: ErrorContext)?
    @Published var isShowingError = false
    
    // MARK: - Private Properties
    private let logger = Logger(subsystem: "TaskFl0w", category: "ErrorHandler")
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Protocol Implementation
    func handle(_ error: Error, context: ErrorContext) {
        logError(error, context: context)
        
        // Конвертируем в AppError если это возможно
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else {
            appError = .unknownError(error.localizedDescription)
        }
        
        handle(appError, context: context)
    }
    
    func handle(_ error: AppError, context: ErrorContext) {
        logError(error, context: context)
        
        // Определяем стратегию обработки на основе типа ошибки
        switch error {
        case .userPermissionDenied, .validationError:
            // Эти ошибки всегда показываем пользователю
            showUserError(error, context: context)
        case .networkError, .dataLoadFailed:
            // Эти ошибки показываем только если это критично для UI
            if shouldShowToUser(context: context) {
                showUserError(error, context: context)
            }
        case .dataSaveFailed, .configurationError:
            // Критические ошибки всегда показываем
            showUserError(error, context: context)
        case .unknownError:
            // Логируем и показываем если это не фоновая операция
            if !context.operation.contains("background") {
                showUserError(error, context: context)
            }
        }
    }
    
    func logError(_ error: Error, context: ErrorContext) {
        let errorMessage = """
        🚨 Error in \(context.source).\(context.operation):
        📝 Message: \(error.localizedDescription)
        ⏰ Time: \(context.timestamp)
        📊 UserInfo: \(context.userInfo)
        """
        
        logger.error("\(errorMessage)")
        
        // В debug mode также печатаем в консоль
        #if DEBUG
        print(errorMessage)
        #endif
    }
    
    func showUserError(_ error: Error, context: ErrorContext) {
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else {
            appError = .unknownError(error.localizedDescription)
        }
        
        currentError = (appError, context)
        isShowingError = true
    }
    
    // MARK: - Private Methods
    private func shouldShowToUser(context: ErrorContext) -> Bool {
        // Определяем, должна ли ошибка быть показана пользователю
        // на основе контекста и важности операции
        let criticalOperations = ["save", "load", "sync", "authenticate"]
        return criticalOperations.contains { context.operation.lowercased().contains($0) }
    }
    
    // MARK: - Public Methods
    func dismissCurrentError() {
        currentError = nil
        isShowingError = false
    }
    
    func executeRecoveryAction(_ action: String, for error: AppError, context: ErrorContext) {
        switch action {
        case "Повторить":
            handleRetryAction(for: error, context: context)
        case "Сбросить настройки":
            handleResetSettingsAction()
        case "Открыть настройки":
            handleOpenSettingsAction()
        case "Перезапустить":
            handleRestartAction()
        default:
            dismissCurrentError()
        }
    }
    
    private func handleRetryAction(for error: AppError, context: ErrorContext) {
        // Здесь можно добавить логику для повторения операции
        logger.info("Пользователь выбрал повторить операцию: \(context.operation)")
        dismissCurrentError()
    }
    
    private func handleResetSettingsAction() {
        // Сброс настроек к значениям по умолчанию
        UserDefaults.standard.removeObject(forKey: "clockStyle")
        UserDefaults.standard.removeObject(forKey: "themeMode")
        logger.info("Настройки сброшены к значениям по умолчанию")
        dismissCurrentError()
    }
    
    private func handleOpenSettingsAction() {
        // Открытие системных настроек
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        dismissCurrentError()
    }
    
    private func handleRestartAction() {
        // В реальном приложении здесь может быть логика перезапуска
        logger.info("Пользователь запросил перезапуск приложения")
        dismissCurrentError()
    }
}

// MARK: - Convenience Extensions
extension ErrorHandler {
    
    func handleDataError(_ error: Error, in source: String, operation: String = "data operation") {
        let context = ErrorContext(source: source, operation: operation)
        let appError = AppError.dataLoadFailed(error.localizedDescription)
        handle(appError, context: context)
    }
    
    func handleNetworkError(_ error: Error, in source: String) {
        let context = ErrorContext(source: source, operation: "network request")
        let appError = AppError.networkError(error.localizedDescription)
        handle(appError, context: context)
    }
    
    func handleValidationError(_ message: String, in source: String) {
        let context = ErrorContext(source: source, operation: "validation")
        let appError = AppError.validationError(message)
        handle(appError, context: context)
    }
} 