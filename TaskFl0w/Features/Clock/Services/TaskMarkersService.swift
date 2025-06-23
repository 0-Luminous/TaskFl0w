//
//  TaskMarkersService.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import Foundation
import SwiftUI

/// Сервис для управления маркерами задач - устраняет дублирование кода
final class TaskMarkersService {
    
    // MARK: - Constants
    
    /// Минимальная близость между задачами для показа тонких маркеров (15 минут)
    static let proximityThreshold: TimeInterval = 15 * 60
    
    /// Минимальная длительность задачи для показа маркеров времени (20 минут)
    static let minDurationForTimeMarkers: TimeInterval = 20 * 60
    
    /// Порог для классификации задачи как "средней длительности" (40 минут)
    static let mediumTaskThreshold: TimeInterval = 40 * 60
    
    // MARK: - Public Methods
    
    /// Определяет, должна ли задача иметь тонкие маркеры
    /// - Parameters:
    ///   - task: Проверяемая задача
    ///   - allTasks: Все задачи для анализа близости
    ///   - proximityThreshold: Пороговое значение близости (по умолчанию 15 минут)
    /// - Returns: true, если задача должна иметь тонкие маркеры
    static func shouldTaskHaveThinMarkers(
        _ task: TaskOnRing,
        allTasks: [TaskOnRing],
        proximityThreshold: TimeInterval = TaskMarkersService.proximityThreshold
    ) -> Bool {
        let durationMinutes = task.duration / 60
        
        // Задачи средней длительности (20-40 минут) всегда имеют тонкие маркеры
        if durationMinutes >= 20 && durationMinutes < 40 {
            return true
        }
        
        // Длинные задачи (40+ минут) имеют тонкие маркеры только если рядом есть средние задачи
        if durationMinutes >= 40 {
            return hasNearbyMediumDurationTasks(task, allTasks: allTasks, proximityThreshold: proximityThreshold)
        }
        
        return false
    }
    
    /// Проверяет, есть ли рядом с указанной задачей другие задачи с тонкими маркерами
    /// - Parameters:
    ///   - markerTime: Время маркера для проверки
    ///   - excludingTask: Задача, которую нужно исключить из проверки
    ///   - allTasks: Все задачи для анализа
    ///   - proximityThreshold: Пороговое значение близости
    /// - Returns: true, если есть близкие задачи с тонкими маркерами
    static func hasNearbyTasksWithThinMarkers(
        for markerTime: Date,
        excludingTask: TaskOnRing,
        allTasks: [TaskOnRing],
        proximityThreshold: TimeInterval = TaskMarkersService.proximityThreshold
    ) -> Bool {
        let otherTasks = allTasks.filter { $0.id != excludingTask.id }
        
        for otherTask in otherTasks {
            // Проверяем, имеет ли другая задача тонкие маркеры
            if shouldTaskHaveThinMarkers(otherTask, allTasks: allTasks, proximityThreshold: proximityThreshold) {
                // Проверяем близость к началу или концу другой задачи
                let proximityToStart = abs(markerTime.timeIntervalSince(otherTask.startTime))
                let proximityToEnd = abs(markerTime.timeIntervalSince(otherTask.endTime))
                
                if proximityToStart <= proximityThreshold || proximityToEnd <= proximityThreshold {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Фильтрует задачи для выбранной даты
    /// - Parameters:
    ///   - selectedDate: Выбранная дата
    ///   - allTasks: Все доступные задачи
    /// - Returns: Задачи для указанной даты
    static func getTasksForDate(_ selectedDate: Date, from allTasks: [TaskOnRing]) -> [TaskOnRing] {
        return allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
    }
    
    // MARK: - Private Methods
    
    /// Проверяет, есть ли рядом с длинной задачей задачи средней длительности
    /// - Parameters:
    ///   - task: Проверяемая длинная задача
    ///   - allTasks: Все задачи для анализа
    ///   - proximityThreshold: Пороговое значение близости
    /// - Returns: true, если рядом есть задачи средней длительности
    private static func hasNearbyMediumDurationTasks(
        _ task: TaskOnRing,
        allTasks: [TaskOnRing],
        proximityThreshold: TimeInterval
    ) -> Bool {
        let otherTasks = allTasks.filter { $0.id != task.id }
        
        for otherTask in otherTasks {
            let otherTaskDuration = otherTask.duration / 60
            
            // Проверяем, является ли другая задача средней длительности
            if otherTaskDuration >= 20 && otherTaskDuration < 40 {
                // Проверяем все возможные варианты близости
                let proximities = [
                    abs(task.startTime.timeIntervalSince(otherTask.startTime)),
                    abs(task.endTime.timeIntervalSince(otherTask.endTime)),
                    abs(task.startTime.timeIntervalSince(otherTask.endTime)),
                    abs(task.endTime.timeIntervalSince(otherTask.startTime))
                ]
                
                if proximities.contains(where: { $0 <= proximityThreshold }) {
                    return true
                }
            }
        }
        
        return false
    }
}

 