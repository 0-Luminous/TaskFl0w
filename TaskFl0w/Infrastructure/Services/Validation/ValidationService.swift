//
//  ValidationService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import OSLog

/// Сервис для валидации задач и бизнес-логики
final class ValidationService: ValidationServiceProtocol {
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "TaskFl0w", category: "ValidationService")
    
    // MARK: - Constants
    private struct Constants {
        static let minimumTaskDuration: TimeInterval = 60 // 1 минута
        static let maximumTaskDuration: TimeInterval = 24 * 60 * 60 // 24 часа
        static let overlapsToleranceSeconds: TimeInterval = 30 // 30 секунд толерантности
    }
    
    // MARK: - ValidationServiceProtocol Implementation
    
    func validateTask(_ task: TaskOnRing) -> ValidationResult {
        var reasons: [String] = []
        
        // Проверка базовой логики времени
        if task.endTime <= task.startTime {
            reasons.append("Время окончания должно быть позже времени начала")
        }
        
        // Проверка минимальной длительности
        let duration = task.duration
        if duration < Constants.minimumTaskDuration {
            reasons.append("Задача слишком короткая. Минимальная длительность: \(Int(Constants.minimumTaskDuration / 60)) минут")
        }
        
        // Проверка максимальной длительности
        if duration > Constants.maximumTaskDuration {
            reasons.append("Задача слишком длинная. Максимальная длительность: \(Int(Constants.maximumTaskDuration / 3600)) часов")
        }
        
        // Проверка разумности времени
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: task.startTime)
        let endHour = calendar.component(.hour, from: task.endTime)
        
        if startHour < 5 {
            reasons.append("Очень раннее время начала (до 5:00)")
        }
        
        if endHour > 23 {
            reasons.append("Очень позднее время окончания (после 23:00)")
        }
        
        // Проверка на будущее время (только предупреждение)
        if task.startTime < Date() && !task.isCompleted {
            reasons.append("Задача запланирована в прошлом")
        }
        
        if reasons.isEmpty {
            logger.debug("Задача \(task.id) прошла валидацию")
            return .valid
        } else {
            logger.info("Задача \(task.id) не прошла валидацию: \(reasons.joined(separator: ", "))")
            return .invalid(reasons.map { ValidationError.custom(message: $0) })
        }
    }
    
    func validateTimeOverlap(_ task: TaskOnRing, with tasks: [TaskOnRing]) -> Bool {
        for existingTask in tasks {
            // Пропускаем ту же задачу
            if existingTask.id == task.id {
                continue
            }
            
            // Проверяем пересечение времени
            if hasTimeOverlap(task1: task, task2: existingTask) {
                logger.info("Обнаружено пересечение задачи \(task.id) с задачей \(existingTask.id)")
                return true
            }
        }
        
        logger.debug("Пересечений для задачи \(task.id) не найдено")
        return false
    }
    
    // MARK: - Additional Validation Methods
    
    /// Валидирует список задач на пересечения
    func validateTaskList(_ tasks: [TaskOnRing]) -> [ValidationResult] {
        return tasks.map { task in
            let basicValidation = validateTask(task)
            
            // Если базовая валидация не прошла, возвращаем её
            guard basicValidation.isValid else { return basicValidation }
            
            // Проверяем на пересечения
            let hasOverlaps = validateTimeOverlap(task, with: tasks)
            
            if hasOverlaps {
                return .invalid([ValidationError.custom(message: "Задача пересекается с другими задачами")])
            }
            
            return .valid
        }
    }
    
    /// Находит все пересекающиеся задачи для данной задачи
    func findOverlappingTasks(for task: TaskOnRing, in tasks: [TaskOnRing]) -> [TaskOnRing] {
        return tasks.filter { existingTask in
            existingTask.id != task.id && hasTimeOverlap(task1: task, task2: existingTask)
        }
    }
    
    /// Предлагает исправления для пересекающихся задач
    func suggestTimeSlotFix(for task: TaskOnRing, avoiding tasks: [TaskOnRing]) -> TaskOnRing? {
        let taskDuration = task.duration
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: task.startTime)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? task.startTime
        
        // Ищем свободный слот в тот же день
        var currentTime = startOfDay
        
        while currentTime.addingTimeInterval(taskDuration) <= endOfDay {
            let proposedTask = TaskOnRing(
                id: task.id,
                startTime: currentTime,
                endTime: currentTime.addingTimeInterval(taskDuration),
                color: task.color,
                icon: task.icon,
                category: task.category,
                isCompleted: task.isCompleted
            )
            
            if !validateTimeOverlap(proposedTask, with: tasks) {
                logger.info("Найден подходящий слот для задачи \(task.id): \(currentTime)")
                return proposedTask
            }
            
            currentTime = currentTime.addingTimeInterval(15 * 60) // Проверяем каждые 15 минут
        }
        
        logger.warning("Не удалось найти подходящий слот для задачи \(task.id)")
        return nil
    }
    
    // MARK: - Private Methods
    
    private func hasTimeOverlap(task1: TaskOnRing, task2: TaskOnRing) -> Bool {
        // Добавляем небольшую толерантность для избежания конфликтов при точном соприкосновении
        let tolerance = Constants.overlapsToleranceSeconds
        
        let task1Start = task1.startTime.addingTimeInterval(-tolerance)
        let task1End = task1.endTime.addingTimeInterval(tolerance)
        let task2Start = task2.startTime.addingTimeInterval(-tolerance)
        let task2End = task2.endTime.addingTimeInterval(tolerance)
        
        return task1Start < task2End && task1End > task2Start
    }
}

// MARK: - Validation Error Types
enum ValidationError: Error, LocalizedError {
    case emptyValue(field: String)
    case invalidFormat(field: String, expected: String)
    case outOfRange(field: String, min: Any?, max: Any?)
    case invalidTimeRange(start: Date, end: Date)
    case duplicateValue(field: String, value: Any)
    case requiredField(field: String)
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .emptyValue(let field):
            return "\(field) не может быть пустым"
        case .invalidFormat(let field, let expected):
            return "\(field) имеет неверный формат. Ожидается: \(expected)"
        case .outOfRange(let field, let min, let max):
            var message = "\(field) вне допустимого диапазона"
            if let min = min, let max = max {
                message += " (\(min) - \(max))"
            }
            return message
        case .invalidTimeRange(let start, let end):
            return "Время окончания (\(end.formatted())) должно быть позже времени начала (\(start.formatted()))"
        case .duplicateValue(let field, let value):
            return "\(field) '\(value)' уже существует"
        case .requiredField(let field):
            return "Поле '\(field)' обязательно для заполнения"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case valid
    case invalid([ValidationError])
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var errors: [ValidationError] {
        switch self {
        case .valid: return []
        case .invalid(let errors): return errors
        }
    }
}

// MARK: - Validator Protocol
protocol Validator {
    associatedtype Value
    func validate(_ value: Value) -> ValidationResult
}

// MARK: - Basic Validators
struct NonEmptyStringValidator: Validator {
    let fieldName: String
    
    func validate(_ value: String) -> ValidationResult {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid([.emptyValue(field: fieldName)])
        }
        return .valid
    }
}

struct StringLengthValidator: Validator {
    let fieldName: String
    let minLength: Int
    let maxLength: Int
    
    func validate(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        var errors: [ValidationError] = []
        
        if trimmed.count < minLength || trimmed.count > maxLength {
            errors.append(.outOfRange(field: fieldName, min: minLength, max: maxLength))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

struct TimeRangeValidator: Validator {
    func validate(_ value: (start: Date, end: Date)) -> ValidationResult {
        if value.end <= value.start {
            return .invalid([.invalidTimeRange(start: value.start, end: value.end)])
        }
        return .valid
    }
}

struct NumberRangeValidator<T: Comparable>: Validator {
    let fieldName: String
    let min: T?
    let max: T?
    
    func validate(_ value: T) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if let min = min, value < min {
            errors.append(.outOfRange(field: fieldName, min: min, max: max))
        }
        
        if let max = max, value > max {
            errors.append(.outOfRange(field: fieldName, min: min, max: max))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Static Validation Helpers (moved to main ValidationService class above)

// MARK: - SwiftUI Extensions
extension ValidationResult {
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let errors):
            return errors.first?.localizedDescription
        }
    }
    
    var allErrorMessages: [String] {
        return errors.compactMap { $0.localizedDescription }
    }
}

// MARK: - Form Validation Helper
@propertyWrapper
final class Validated<T>: ObservableObject {
    private var value: T
    private let validator: (T) -> ValidationResult
    
    @Published var validationResult: ValidationResult = .valid
    
    var wrappedValue: T {
        get { value }
        set {
            value = newValue
            validationResult = validator(newValue)
        }
    }
    
    var projectedValue: Published<ValidationResult>.Publisher {
        $validationResult
    }
    
    init(wrappedValue: T, validator: @escaping (T) -> ValidationResult) {
        self.value = wrappedValue
        self.validator = validator
        self.validationResult = validator(wrappedValue)
    }
}

// MARK: - Usage Examples in Comments
/*
 Примеры использования:
 
 // В ViewModel
 @Validated(validator: ValidationService.validateTaskName)
 var taskName: String = ""
 
 // Проверка результата
 if taskNameValidationResult.isValid {
     // Сохранить задачу
 } else {
     // Показать ошибки
     print(taskNameValidationResult.allErrorMessages)
 }
 
 // Ручная валидация
 let result = ValidationService.validateTimeRange(start: startDate, end: endDate)
 switch result {
 case .valid:
     print("Время валидно")
 case .invalid(let errors):
     errors.forEach { print($0.localizedDescription) }
 }
 */ 