import Combine
import CoreData
//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

final class ClockViewModel: ObservableObject {
    // MARK: - Services
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol

    // MARK: - Published properties
    @Published var tasks: [TaskOnRing] = []

    // Доступ к категориям только для чтения
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }

    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date() {
        didSet {
            // Обновляем selectedDate в TaskManagement при изменении
            (taskManagement as? TaskManagement)?.selectedDate = selectedDate
        }
    }

    // Текущее время для реального обновления
    @Published var currentDate: Date = Date()

    // В этот флаг можно прокидывать логику тёмной/светлой темы, если нужно
    @AppStorage("isDarkMode") var isDarkMode = false

    // Пример использования AppStorage для цвета циферблата
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()

    @Published var isDockBarEditingEnabled: Bool = false

    // Перетаскивание задачи
    @Published var draggedTask: TaskOnRing?
    @Published var isDraggingOutside: Bool = false

    // Состояния представлений
    @Published var showingAddTask: Bool = false
    @Published var showingSettings: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var showingTodayTasks: Bool = false
    @Published var showingCategoryEditor: Bool = false
    @Published var selectedCategory: TaskCategoryModel?

    // Drag & Drop
    @Published var draggedCategory: TaskCategoryModel?

    // Режим редактирования
    @Published var isEditingMode: Bool = false
    @Published var editingTask: TaskOnRing?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTask: TaskOnRing?
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""

    // MARK: - Инициализация
    init(sharedState: SharedStateService = .shared) {
        self.sharedState = sharedState

        // Сначала инициализируем selectedDate
        let initialDate = Date()
        self.selectedDate = initialDate

        // Теперь можем безопасно использовать selectedDate
        let taskManagement = TaskManagement(sharedState: sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement
        self.categoryManagement = CategoryManagement(
            context: sharedState.context, sharedState: sharedState)

        // Подписываемся на обновления задач
        sharedState.subscribeToTasksUpdates { [weak self] in
            self?.tasks = sharedState.tasks
        }

        self.tasks = sharedState.tasks
    }

    func startDragging(_ task: TaskOnRing) {
        draggedTask = task
    }

    func stopDragging(didReturnToClock: Bool) {
        if let task = draggedTask {
            if !didReturnToClock {
                taskManagement.removeTask(task)
            }
        }
        draggedTask = nil
        isDraggingOutside = false
    }

    func updateDragPosition(isOutsideClock: Bool) {
        isDraggingOutside = isOutsideClock
    }
}
