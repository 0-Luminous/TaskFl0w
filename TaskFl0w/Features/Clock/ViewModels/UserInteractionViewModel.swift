//
//  UserInteractionViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import CoreGraphics

/// Оптимизированный ViewModel для управления пользовательскими взаимодействиями
/// ✅ ПРОИЗВОДИТЕЛЬНОСТЬ: Убраны избыточные objectWillChange.send() (36→4 вызова)
@MainActor
final class UserInteractionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Task Selection & Editing
    @Published var selectedTask: TaskOnRing?
    @Published var editingTask: TaskOnRing?
    @Published var showingTaskDetail = false
    
    // Drag & Drop
    @Published var draggedTask: TaskOnRing?
    @Published var draggedCategory: TaskCategoryModel?
    @Published var selectedCategory: TaskCategoryModel?
    @Published var isDraggingOutside = false
    @Published var isDraggingStart = false
    @Published var isDraggingEnd = false
    @Published var previewTime: Date?
    @Published var previewTask: TaskOnRing?
    @Published var dropLocation: CGPoint?
    
    // Edit Mode
    @Published var isEditingMode = false
    @Published var isDockBarEditingEnabled = false
    
    // Modal States
    @Published var showingAddTask = false
    @Published var showingSettings = false
    @Published var showingCalendar = false
    @Published var showingStatistics = false
    @Published var showingTodayTasks = false
    @Published var showingCategoryEditor = false
    
    // MARK: - Private Properties
    
    private let dragAndDropManager: DragAndDropManager
    
    // ✅ ОПТИМИЗАЦИЯ: Дебаунсинг для частых обновлений
    private var updateDebouncer: Timer?
    private let debounceInterval: TimeInterval = 0.016 // 60 FPS
    
    // MARK: - Initialization
    
    init(dragAndDropManager: DragAndDropManager) {
        self.dragAndDropManager = dragAndDropManager
    }
    
    convenience init(taskManagement: TaskManagementProtocol) {
        let dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        self.init(dragAndDropManager: dragAndDropManager)
    }
    
    // MARK: - Computed Properties for UI Access
    
    /// Проверяет, открыто ли любое модальное окно
    var isAnyModalPresented: Bool {
        showingAddTask || showingSettings || showingCalendar || 
        showingStatistics || showingTodayTasks || showingCategoryEditor || showingTaskDetail
    }
    
    /// Проверяет, происходит ли любое перетаскивание
    var isDraggingAny: Bool {
        draggedTask != nil || draggedCategory != nil || isDraggingStart || isDraggingEnd
    }
    
    // MARK: - Task Editing Convenience Properties
    
    /// Начинает перетаскивание начала задачи для редактируемой задачи
    func startDraggingTaskStart() {
        if let task = editingTask {
            startDraggingTaskStart(task)
        }
    }
    
    /// Начинает перетаскивание конца задачи для редактируемой задачи
    func startDraggingTaskEnd() {
        if let task = editingTask {
            startDraggingTaskEnd(task)
        }
    }
    
    /// Останавливает перетаскивание краев задачи
    func stopDraggingTaskEdges() {
        resetDragStates()
    }
    
    // MARK: - Drag & Drop Methods (Optimized)
    
    /// Начинает перетаскивание задачи
    func startDragging(_ task: TaskOnRing) {
        draggedTask = task
        dragAndDropManager.startDragging(task)
        // ✅ @Published автоматически уведомляет
    }
    
    /// Останавливает перетаскивание задачи
    func stopDragging(didReturnToClock: Bool) {
        dragAndDropManager.stopDragging(didReturnToClock: didReturnToClock)
        
        // Сбрасываем состояние перетаскивания
        draggedTask = nil
        isDraggingOutside = false
        isDraggingStart = false
        isDraggingEnd = false
        previewTime = nil
        dropLocation = nil
        // ✅ @Published автоматически уведомляет
    }
    
    /// Обновляет позицию перетаскивания с дебаунсингом
    func updateDragPosition(isOutsideClock: Bool, location: CGPoint? = nil) {
        isDraggingOutside = isOutsideClock
        dropLocation = location
        
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
        // ✅ @Published автоматически уведомляет
    }
    
    /// Начинает перетаскивание начала задачи
    func startDraggingTaskStart(_ task: TaskOnRing) {
        draggedTask = task
        isDraggingStart = true
        isDraggingEnd = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Начинает перетаскивание конца задачи
    func startDraggingTaskEnd(_ task: TaskOnRing) {
        draggedTask = task
        isDraggingEnd = true
        isDraggingStart = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Обновляет время превью с дебаунсингом для плавности
    func updatePreviewTime(_ time: Date?) {
        // ✅ ОПТИМИЗАЦИЯ: Дебаунсинг для частых обновлений времени
        updateDebouncer?.invalidate()
        updateDebouncer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.previewTime = time
            }
        }
    }
    
    // MARK: - Task Selection Methods (Optimized)
    
    /// Выбирает задачу
    func selectTask(_ task: TaskOnRing?) {
        selectedTask = task
        
        // Если задача выбрана, выходим из режима редактирования
        if task != nil {
            isEditingMode = false
        }
        // ✅ @Published автоматически уведомляет
    }
    
    /// Начинает редактирование задачи
    func startEditingTask(_ task: TaskOnRing) {
        editingTask = task
        isEditingMode = true
        selectedTask = task
        // ✅ @Published автоматически уведомляет
    }
    
    /// Завершает редактирование задачи
    func finishEditingTask() {
        editingTask = nil
        isEditingMode = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает детали задачи
    func showTaskDetail(for task: TaskOnRing) {
        selectedTask = task
        showingTaskDetail = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает детали задачи
    func hideTaskDetail() {
        showingTaskDetail = false
        selectedTask = nil
        // ✅ @Published автоматически уведомляет
    }
    
    // MARK: - Category Selection Methods (Optimized)
    
    /// Выбирает категорию
    func selectCategory(_ category: TaskCategoryModel?) {
        selectedCategory = category
        // ✅ @Published автоматически уведомляет
    }
    
    /// Начинает перетаскивание категории
    func startDraggingCategory(_ category: TaskCategoryModel) {
        draggedCategory = category
        // ✅ @Published автоматически уведомляет
    }
    
    /// Останавливает перетаскивание категории
    func stopDraggingCategory() {
        draggedCategory = nil
        // ✅ @Published автоматически уведомляет
    }
    
    // MARK: - Modal Management Methods (Optimized)
    
    /// Показывает модальное окно добавления задачи
    func showAddTask() {
        showingAddTask = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает модальное окно добавления задачи
    func hideAddTask() {
        showingAddTask = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает настройки
    func showSettings() {
        showingSettings = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает настройки
    func hideSettings() {
        showingSettings = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает календарь
    func showCalendar() {
        showingCalendar = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает календарь
    func hideCalendar() {
        showingCalendar = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает статистику
    func showStatistics() {
        showingStatistics = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает статистику
    func hideStatistics() {
        showingStatistics = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает список задач на сегодня
    func showTodayTasksList() {
        showingTodayTasks = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает список задач на сегодня
    func hideTodayTasksList() {
        showingTodayTasks = false
        // ✅ @Published автоматически уведомляет
    }
    
    /// Показывает редактор категорий
    func showCategoryEditor() {
        showingCategoryEditor = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Скрывает редактор категорий
    func hideCategoryEditor() {
        showingCategoryEditor = false
        // ✅ @Published автоматически уведомляет
    }
    
    // MARK: - Edit Mode Methods (Optimized)
    
    /// Включает режим редактирования
    func enableEditMode() {
        isEditingMode = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Выключает режим редактирования
    func disableEditMode() {
        isEditingMode = false
        editingTask = nil
        selectedTask = nil
        // ✅ @Published автоматически уведомляет
    }
    
    /// Переключает режим редактирования
    func toggleEditMode() {
        if isEditingMode {
            disableEditMode()
        } else {
            enableEditMode()
        }
    }
    
    /// Включает редактирование dock bar
    func enableDockBarEditing() {
        isDockBarEditingEnabled = true
        // ✅ @Published автоматически уведомляет
    }
    
    /// Выключает редактирование dock bar
    func disableDockBarEditing() {
        isDockBarEditingEnabled = false
        // ✅ @Published автоматически уведомляет
    }
    
    // MARK: - State Reset Methods (Optimized)
    
    /// Сбрасывает все состояния взаимодействия
    func resetAllStates() {
        selectedTask = nil
        editingTask = nil
        draggedTask = nil
        draggedCategory = nil
        selectedCategory = nil
        
        isDraggingOutside = false
        isDraggingStart = false
        isDraggingEnd = false
        isEditingMode = false
        isDockBarEditingEnabled = false
        
        previewTime = nil
        dropLocation = nil
        
        // Скрываем все модальные окна
        showingAddTask = false
        showingSettings = false
        showingCalendar = false
        showingStatistics = false
        showingTodayTasks = false
        showingCategoryEditor = false 
        showingTaskDetail = false
        
        // ✅ ОПТИМИЗАЦИЯ: Один вызов для множественных изменений
        objectWillChange.send()
    }
    
    /// Сбрасывает только состояния перетаскивания
    func resetDragStates() {
        draggedTask = nil
        draggedCategory = nil
        isDraggingOutside = false
        isDraggingStart = false
        isDraggingEnd = false
        previewTime = nil
        dropLocation = nil
        
        // ✅ ОПТИМИЗАЦИЯ: Один вызов для множественных изменений
        objectWillChange.send()
    }
    
    /// Сбрасывает только модальные состояния
    func resetModalStates() {
        showingAddTask = false
        showingSettings = false
        showingCalendar = false
        showingStatistics = false
        showingTodayTasks = false
        showingCategoryEditor = false 
        showingTaskDetail = false
        
        // ✅ ОПТИМИЗАЦИЯ: Один вызов для множественных изменений
        objectWillChange.send()
    }
    
    /// Сбрасывает только состояния редактирования
    func resetEditingStates() {
        isEditingMode = false
        editingTask = nil
        isDraggingStart = false
        isDraggingEnd = false
        previewTime = nil
        dropLocation = nil
        selectedTask = nil
        
        // ✅ ОПТИМИЗАЦИЯ: Один вызов для множественных изменений
        objectWillChange.send()
    }
    
    // MARK: - Cleanup
    
    deinit {
        updateDebouncer?.invalidate()
    }
}

// MARK: - UserInteractionProtocol

protocol UserInteractionProtocol: ObservableObject {
    var selectedTask: TaskOnRing? { get set }
    var editingTask: TaskOnRing? { get set }
    var draggedTask: TaskOnRing? { get set }
    var isEditingMode: Bool { get set }
    var isDraggingOutside: Bool { get set }
    
    func startDragging(_ task: TaskOnRing)
    func stopDragging(didReturnToClock: Bool)
    func updateDragPosition(isOutsideClock: Bool, location: CGPoint?)
    func selectTask(_ task: TaskOnRing?)
    func startEditingTask(_ task: TaskOnRing)
    func finishEditingTask()
}

extension UserInteractionViewModel: UserInteractionProtocol {} 