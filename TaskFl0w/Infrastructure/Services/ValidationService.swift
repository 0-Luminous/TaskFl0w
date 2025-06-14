//
//  ValidationService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI

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

// MARK: - Validation Service
struct ValidationService {
    
    // MARK: - Task Validation
    static func validateTaskName(_ name: String) -> ValidationResult {
        let nonEmptyValidator = NonEmptyStringValidator(fieldName: "Название задачи")
        let lengthValidator = StringLengthValidator(fieldName: "Название задачи", minLength: 1, maxLength: 100)
        
        return combine(
            nonEmptyValidator.validate(name),
            lengthValidator.validate(name)
        )
    }
    
    static func validateTimeRange(start: Date, end: Date) -> ValidationResult {
        let timeRangeValidator = TimeRangeValidator()
        return timeRangeValidator.validate((start: start, end: end))
    }
    
    static func validateTaskDuration(start: Date, end: Date, minMinutes: Int = 1, maxHours: Int = 24) -> ValidationResult {
        let duration = end.timeIntervalSince(start)
        let durationMinutes = Int(duration / 60)
        let durationHours = Int(duration / 3600)
        
        var errors: [ValidationError] = []
        
        // Проверка времен последовательности
        let timeRangeResult = validateTimeRange(start: start, end: end)
        errors.append(contentsOf: timeRangeResult.errors)
        
        // Проверка минимальной длительности
        if durationMinutes < minMinutes {
            errors.append(.outOfRange(field: "Продолжительность задачи", min: "\(minMinutes) мин", max: "\(maxHours) ч"))
        }
        
        // Проверка максимальной длительности
        if durationHours > maxHours {
            errors.append(.outOfRange(field: "Продолжительность задачи", min: "\(minMinutes) мин", max: "\(maxHours) ч"))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
    
    // MARK: - Category Validation
    static func validateCategoryName(_ name: String, existingNames: [String] = []) -> ValidationResult {
        let nonEmptyValidator = NonEmptyStringValidator(fieldName: "Название категории")
        let lengthValidator = StringLengthValidator(fieldName: "Название категории", minLength: 1, maxLength: 50)
        
        var results = [
            nonEmptyValidator.validate(name),
            lengthValidator.validate(name)
        ]
        
        // Проверка на дубликаты
        if existingNames.contains(name.trimmingCharacters(in: .whitespacesAndNewlines)) {
            results.append(.invalid([.duplicateValue(field: "Название категории", value: name)]))
        }
        
        return combine(results)
    }
    
    static func validateColor(_ color: Color?) -> ValidationResult {
        guard color != nil else {
            return .invalid([.requiredField(field: "Цвет категории")])
        }
        return .valid
    }
    
    // MARK: - Settings Validation
    static func validateZeroPosition(_ position: Double) -> ValidationResult {
        let validator = NumberRangeValidator<Double>(fieldName: "Позиция нуля", min: 0.0, max: 360.0)
        return validator.validate(position)
    }
    
    static func validateLineWidth(_ width: Double) -> ValidationResult {
        let validator = NumberRangeValidator<Double>(fieldName: "Ширина линии", min: 0.5, max: 50.0)
        return validator.validate(width)
    }
    
    static func validateFontSize(_ size: Double) -> ValidationResult {
        let validator = NumberRangeValidator<Double>(fieldName: "Размер шрифта", min: 8.0, max: 72.0)
        return validator.validate(size)
    }
    
    static func validateReminderTime(_ minutes: Int) -> ValidationResult {
        let validator = NumberRangeValidator<Int>(fieldName: "Время напоминания", min: 1, max: 60)
        return validator.validate(minutes)
    }
    
    // MARK: - Helper Methods
    private static func combine(_ results: ValidationResult...) -> ValidationResult {
        return combine(Array(results))
    }
    
    private static func combine(_ results: [ValidationResult]) -> ValidationResult {
        let allErrors = results.flatMap { $0.errors }
        return allErrors.isEmpty ? .valid : .invalid(allErrors)
    }
}

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