//
//  TaskOverlapConstants.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

enum TaskOverlapConstants {
    static let minimumDuration: TimeInterval = 15 * 60 // 15 минут
    static let searchStep: TimeInterval = 15 * 60 // 15 минут
    static let maxSearchRadius: TimeInterval = 12 * 60 * 60 // 12 часов
    static let uiUpdateDelay: TimeInterval = 0.1
    static let batchProcessingThreshold = 3 // Уменьшено для более быстрой обработки небольших групп
    static let maxIterationsPerChain = 15 // Уменьшено для улучшения производительности
    static let maxCacheSize = 200 // Размер кэша для оптимизации
} 