//
//  ClockViewModelCoordinator.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Combine
import CoreData
import OSLog

// MARK: - Clock Coordinator State
struct ClockCoordinatorState {
    var currentDate = Date()
    var selectedDate = Date()
    var isLoading = false
    var error: String?
    var isDarkMode = false
    var zeroPosition: Double = 0.0
    
    // Modal states
    var showingAddTask = false
    var showingSettings = false
    var showingCalendar = false
    var showingStatistics = false
    var showingCategoryEditor = false
}

// MARK: - Clock Actions
enum ClockAction {
    case updateTime
    case selectDate(Date)
    case toggleTheme
    case showModal(ClockModal)
    case hideModal(ClockModal)
    case hideAllModals
    case setZeroPosition(Double)
    case clearError
}

enum ClockModal {
    case addTask
    case settings
    case calendar
    case statistics
    case categoryEditor
}

/// Координатор ClockViewModel - упрощенная версия для компиляции
@MainActor
final class ClockViewModelCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state = ClockCoordinatorState()
    
    private let logger = Logger(subsystem: "TaskFl0w", category: "ClockViewModelCoordinator")
    
    // MARK: - Computed Properties
    
    var currentDate: Date { state.currentDate }
    var selectedDate: Date { 
        get { state.selectedDate }
        set { handle(.selectDate(newValue)) }
    }
    var isDarkMode: Bool {
        get { state.isDarkMode }
        set { 
            state.isDarkMode = newValue
        }
    }
    var zeroPosition: Double {
        get { state.zeroPosition }
        set { handle(.setZeroPosition(newValue)) }
    }
    
    // Modal states
    var showingAddTask: Bool { state.showingAddTask }
    var showingSettings: Bool { state.showingSettings }
    var showingCalendar: Bool { state.showingCalendar }
    var showingStatistics: Bool { state.showingStatistics }
    var showingCategoryEditor: Bool { state.showingCategoryEditor }
    
    // MARK: - Initialization
    init() {
        initializeState()
    }
    
    // MARK: - Action Handler
    func handle(_ action: ClockAction) {
        switch action {
        case .updateTime:
            updateCurrentTime()
        case .selectDate(let date):
            selectDate(date)
        case .toggleTheme:
            state.isDarkMode.toggle()
        case .showModal(let modal):
            showModal(modal)
        case .hideModal(let modal):
            hideModal(modal)
        case .hideAllModals:
            hideAllModals()
        case .setZeroPosition(let position):
            state.zeroPosition = position
        case .clearError:
            state.error = nil
        }
    }
    
    // MARK: - Public Methods (Legacy compatibility)
    
    func updateCurrentTimeIfNeeded() {
        handle(.updateTime)
    }
    
    func showAddTaskModal() {
        handle(.showModal(.addTask))
    }
    
    func showSettingsModal() {
        handle(.showModal(.settings))
    }
    
    func showCalendarModal() {
        handle(.showModal(.calendar))
    }
    
    func hideAllModalsAction() {
        handle(.hideAllModals)
    }
    
    // MARK: - Private Methods
    
    private func initializeState() {
        state.currentDate = Date()
        state.selectedDate = Date()
        logger.info("ClockViewModelCoordinator инициализирован")
    }
    
    private func updateCurrentTime() {
        state.currentDate = Date()
    }
    
    private func selectDate(_ date: Date) {
        state.selectedDate = date
        logger.debug("Выбрана дата: \(date)")
    }
    
    private func showModal(_ modal: ClockModal) {
        hideAllModals() // Сначала скрываем все модальные окна
        
        switch modal {
        case .addTask:
            state.showingAddTask = true
        case .settings:
            state.showingSettings = true
        case .calendar:
            state.showingCalendar = true
        case .statistics:
            state.showingStatistics = true
        case .categoryEditor:
            state.showingCategoryEditor = true
        }
        
        logger.debug("Показано модальное окно: \(String(describing: modal))")
    }
    
    private func hideModal(_ modal: ClockModal) {
        switch modal {
        case .addTask:
            state.showingAddTask = false
        case .settings:
            state.showingSettings = false
        case .calendar:
            state.showingCalendar = false
        case .statistics:
            state.showingStatistics = false
        case .categoryEditor:
            state.showingCategoryEditor = false
        }
        
        logger.debug("Скрыто модальное окно: \(String(describing: modal))")
    }
    
    private func hideAllModals() {
        state.showingAddTask = false
        state.showingSettings = false
        state.showingCalendar = false
        state.showingStatistics = false
        state.showingCategoryEditor = false
    }
} 