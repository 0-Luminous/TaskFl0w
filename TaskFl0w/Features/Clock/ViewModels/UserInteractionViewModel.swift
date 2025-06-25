//
//  UserInteractionViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import CoreGraphics

/// ViewModel для управления пользовательскими взаимодействиями
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
    
    // MARK: - Initialization
    
    init(dragAndDropManager: DragAndDropManager) {
        self.dragAndDropManager = dragAndDropManager
    }
    
    convenience init(taskManagement: TaskManagementProtocol) {
        let dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        self.init(dragAndDropManager: dragAndDropManager)
    }
    
    // MARK: - Drag & Drop Methods
    
    /// Начинает перетаскивание задачи
    func startDragging(_ task: TaskOnRing) {
        draggedTask = task
        dragAndDropManager.startDragging(task)
        objectWillChange.send()
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
        
        objectWillChange.send()
    }
    
    /// Обновляет позицию перетаскивания
    func updateDragPosition(isOutsideClock: Bool, location: CGPoint? = nil) {
        isDraggingOutside = isOutsideClock
        dropLocation = location
        
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
        objectWillChange.send()
    }
    
    /// Начинает перетаскивание начала задачи
    func startDraggingTaskStart(_ task: TaskOnRing) {
        draggedTask = task
        isDraggingStart = true
        isDraggingEnd = false
    }
    
    /// Начинает перетаскивание конца задачи
    func startDraggingTaskEnd(_ task: TaskOnRing) {
        draggedTask = task
        isDraggingEnd = true
        isDraggingStart = false
    }
    
    /// Обновляет время превью при перетаскивании
    func updatePreviewTime(_ time: Date?) {
        previewTime = time
        objectWillChange.send()
    }
    
    // MARK: - Task Selection Methods
    
    /// Выбирает задачу
    func selectTask(_ task: TaskOnRing?) {
        selectedTask = task
        
        // Если задача выбрана, выходим из режима редактирования
        if task != nil {
            isEditingMode = false
        }
        
        objectWillChange.send()
    }
    
    /// Начинает редактирование задачи
    func startEditingTask(_ task: TaskOnRing) {
        editingTask = task
        isEditingMode = true
        selectedTask = task
        objectWillChange.send()
    }
    
    /// Завершает редактирование задачи
    func finishEditingTask() {
        editingTask = nil
        isEditingMode = false
        objectWillChange.send()
    }
    
    /// Показывает детали задачи
    func showTaskDetail(for task: TaskOnRing) {
        selectedTask = task
        showingTaskDetail = true
    }
    
    /// Скрывает детали задачи
    func hideTaskDetail() {
        showingTaskDetail = false
        selectedTask = nil
    }
    
    // MARK: - Category Selection Methods
    
    /// Выбирает категорию
    func selectCategory(_ category: TaskCategoryModel?) {
        selectedCategory = category
        objectWillChange.send()
    }
    
    /// Начинает перетаскивание категории
    func startDraggingCategory(_ category: TaskCategoryModel) {
        draggedCategory = category
        objectWillChange.send()
    }
    
    /// Останавливает перетаскивание категории
    func stopDraggingCategory() {
        draggedCategory = nil
        objectWillChange.send()
    }
    
    // MARK: - Modal Management Methods
    
    /// Показывает модальное окно добавления задачи
    func showAddTask() {
        showingAddTask = true
    }
    
    /// Скрывает модальное окно добавления задачи
    func hideAddTask() {
        showingAddTask = false
    }
    
    /// Показывает настройки
    func showSettings() {
        showingSettings = true
    }
    
    /// Скрывает настройки
    func hideSettings() {
        showingSettings = false
    }
    
    /// Показывает календарь
    func showCalendar() {
        showingCalendar = true
    }
    
    /// Скрывает календарь
    func hideCalendar() {
        showingCalendar = false
    }
    
    /// Показывает статистику
    func showStatistics() {
        showingStatistics = true
    }
    
    /// Скрывает статистику
    func hideStatistics() {
        showingStatistics = false
    }
    
    /// Показывает список задач на сегодня
    func showTodayTasksList() {
        showingTodayTasks = true
    }
    
    /// Скрывает список задач на сегодня
    func hideTodayTasksList() {
        showingTodayTasks = false
    }
    
    /// Показывает редактор категорий
    func showCategoryEditor() {
        showingCategoryEditor = true
    }
    
    /// Скрывает редактор категорий
    func hideCategoryEditor() {
        showingCategoryEditor = false
    }
    
    // MARK: - Edit Mode Methods
    
    /// Включает режим редактирования
    func enableEditMode() {
        isEditingMode = true
        objectWillChange.send()
    }
    
    /// Выключает режим редактирования
    func disableEditMode() {
        isEditingMode = false
        editingTask = nil
        selectedTask = nil
        objectWillChange.send()
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
        objectWillChange.send()
    }
    
    /// Выключает редактирование dock bar
    func disableDockBarEditing() {
        isDockBarEditingEnabled = false
        objectWillChange.send()
    }
    
    // MARK: - State Reset Methods
    
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
        
        objectWillChange.send()
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