//
//  TaskOverlapConstants.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

struct TaskOverlapConstants {
    static let batchProcessingThreshold = 5
    static let minimumTaskDuration: TimeInterval = 15 * 60 // 15 минут
    static let maxTasksPerDay = 50
    static let searchStep: TimeInterval = 15 * 60 // 15 минут
    static let maxSearchRadius: TimeInterval = 12 * 60 * 60 // 12 часов
    static let uiUpdateDelay: TimeInterval = 0.1
    static let maxIterationsPerChain = 15 // Уменьшено для улучшения производительности
    static let maxCacheSize = 200 // Размер кэша для оптимизации
} 