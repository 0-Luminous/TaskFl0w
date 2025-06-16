//
//  SimpleNavigationService.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Foundation

// MARK: - Navigation Service

/// Простой сервис для управления навигацией
@MainActor
final class SimpleNavigationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentScreen: AppScreen = .clock
    @Published var selectedCategory: TaskCategoryModel?
    @Published var showingModal = false
    @Published var showingSettings = false
    @Published var showingTaskTimeline = false
    @Published var showingWeekCalendar = false
    
    // MARK: - Navigation Methods
    
    /// Переходит к основному экрану часов
    func showClock() {
        currentScreen = .clock
        selectedCategory = nil
    }
    
    /// Показывает список задач для категории
    func showTaskList(for category: TaskCategoryModel? = nil) {
        selectedCategory = category
        currentScreen = .taskList
    }
    
    /// Показывает настройки
    func showSettings() {
        showingSettings = true
    }
    
    /// Показывает календарь
    func showCalendar() {
        showingWeekCalendar = true
    }
    
    /// Показывает график задач
    func showTaskTimeline() {
        showingTaskTimeline = true
    }
    
    /// Скрывает календарь
    func hideCalendar() {
        showingWeekCalendar = false
    }
    
    /// Скрывает настройки
    func hideSettings() {
        showingSettings = false
    }
    
    /// Скрывает график задач
    func hideTaskTimeline() {
        showingTaskTimeline = false
    }
    
    /// Возвращается к главному экрану
    func returnToHome() {
        currentScreen = .clock
        selectedCategory = nil
        showingModal = false
        showingSettings = false
        showingTaskTimeline = false
        showingWeekCalendar = false
    }
    
    // MARK: - Helper Properties
    
    /// Проверяет, находимся ли мы на главном экране
    var isOnHomeScreen: Bool {
        currentScreen == .clock && selectedCategory == nil
    }
    
    /// Проверяет, показан ли какой-либо модальный экран
    var hasModalPresented: Bool {
        showingModal || showingSettings || showingTaskTimeline || showingWeekCalendar
    }
}

// MARK: - Screen Types

/// Основные экраны приложения
enum AppScreen: CaseIterable {
    case clock
    case taskList
    
    var title: String {
        switch self {
        case .clock: return "Часы"
        case .taskList: return "Задачи"
        }
    }
} 