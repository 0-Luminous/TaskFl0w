//
//  ValidationServiceProtocol.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

/// Протокол для сервиса валидации
protocol ValidationServiceProtocol: AnyObject {
    func validateTask(_ task: TaskOnRing) -> ValidationResult
    func validateTimeOverlap(_ task: TaskOnRing, with tasks: [TaskOnRing]) -> Bool
} 