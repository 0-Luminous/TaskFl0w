//
//  ListViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import Combine
import OSLog

// MARK: - Todo View State
struct TodoListViewState {
    var items: [ToDoItem] = []
    var filteredItems: [ToDoItem] = []
    var selectedCategory: TaskCategoryModel?
    var searchText = ""
    var selectedDate = Date()
    var isLoading = false
    var error: String?
    
    // UI State
    var showingAddTaskForm = false
    var editingItem: ToDoItem?
    var showCompletedTasksOnly = false
    var selectedTasks: Set<UUID> = []
    var isSelectionMode = false
}

// MARK: - Todo View Actions
enum TodoListAction {
    case loadTasks(Date)
    case searchTasks(String)
    case filterByCategory(TaskCategoryModel?)
    case addTask(title: String, category: TaskCategoryModel?, priority: TaskPriority, date: Date)
    case updateTask(ToDoItem)
    case deleteTask(UUID)
    case toggleTaskCompletion(UUID)
    case changePriority(UUID, TaskPriority)
    case updateTaskDate(UUID, Date)
    case setDeadline(UUID, Date?)
    case archiveCompletedTasks
    
    // UI Actions
    case showAddTaskForm
    case hideAddTaskForm
    case editTask(ToDoItem?)
    case toggleSelectionMode
    case selectTask(UUID)
    case deselectTask(UUID)
    case clearSelection
    case showCompletedTasks(Bool)
    case clearError
}

/// Современный ViewModel для управления списком ToDo задач
@MainActor
final class ListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state = TodoListViewState()
    
    // MARK: - Computed Properties
    var items: [ToDoItem] { 
        // Исправлено: если есть активные фильтры, всегда показываем filteredItems
        // даже если он пустой (нет задач в категории)
        if !state.searchText.isEmpty || state.selectedCategory != nil {
            return state.filteredItems
        }
        // Возвращаем все задачи только если нет активных фильтров
        return state.items
    }
    
    var selectedCategory: TaskCategoryModel? { 
        get { state.selectedCategory }
        set { handle(.filterByCategory(newValue)) }
    }
    
    var searchText: String {
        get { state.searchText }
        set { handle(.searchTasks(newValue)) }
    }
    
    var selectedDate: Date {
        get { state.selectedDate }
        set { handle(.loadTasks(newValue)) }
    }
    
    var isLoading: Bool { state.isLoading }
    var error: String? { state.error }
    var showingAddTaskForm: Bool { state.showingAddTaskForm }
    var editingItem: ToDoItem? { state.editingItem }
    var showCompletedTasksOnly: Bool { state.showCompletedTasksOnly }
    var selectedTasks: Set<UUID> { state.selectedTasks }
    var isSelectionMode: Bool { state.isSelectionMode }
    
    // MARK: - Private Properties
    private let todoDataService: TodoDataService
    private let sharedStateService: SharedStateService
    private let logger = Logger(subsystem: "TaskFl0w", category: "ListViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        todoDataService: TodoDataService,
        sharedStateService: SharedStateService,
        selectedCategory: TaskCategoryModel? = nil
    ) {
        self.todoDataService = todoDataService
        self.sharedStateService = sharedStateService
        self.state.selectedCategory = selectedCategory
        
        setupBindings()
        
        // Загружаем начальные данные
        handle(.loadTasks(Date()))
    }
    
    // MARK: - Action Handler
    func handle(_ action: TodoListAction) {
        switch action {
        case .loadTasks(let date):
            loadTasks(for: date)
        case .searchTasks(let query):
            searchTasks(with: query)
        case .filterByCategory(let category):
            filterByCategory(category)
        case .addTask(let title, let category, let priority, let date):
            addTask(title: title, category: category, priority: priority, date: date)
        case .updateTask(let item):
            updateTask(item)
        case .deleteTask(let id):
            deleteTask(with: id)
        case .toggleTaskCompletion(let id):
            toggleTaskCompletion(id: id)
        case .changePriority(let id, let priority):
            changePriority(id: id, priority: priority)
        case .updateTaskDate(let id, let date):
            updateTaskDate(id: id, newDate: date)
        case .setDeadline(let id, let deadline):
            setDeadline(id: id, deadline: deadline)
        case .archiveCompletedTasks:
            archiveCompletedTasks()
        case .showAddTaskForm:
            state.showingAddTaskForm = true
        case .hideAddTaskForm:
            state.showingAddTaskForm = false
        case .editTask(let item):
            state.editingItem = item
        case .toggleSelectionMode:
            state.isSelectionMode.toggle()
            if !state.isSelectionMode {
                state.selectedTasks.removeAll()
            }
        case .selectTask(let id):
            state.selectedTasks.insert(id)
        case .deselectTask(let id):
            state.selectedTasks.remove(id)
        case .clearSelection:
            state.selectedTasks.removeAll()
        case .showCompletedTasks(let show):
            state.showCompletedTasksOnly = show
        case .clearError:
            state.error = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Подписываемся на изменения в SharedStateService для синхронизации
        sharedStateService.$tasks
            .sink { [weak self] taskOnRings in
                self?.syncWithSharedState(taskOnRings)
            }
            .store(in: &cancellables)
    }
    
    private func syncWithSharedState(_ taskOnRings: [TaskOnRing]) {
        // Синхронизируем TaskOnRing с ToDoItem через конвертер
        // Это необходимо для интеграции с часами
        logger.debug("Синхронизация с SharedState: \(taskOnRings.count) задач")
    }
    
    private func loadTasks(for date: Date) {
        state.isLoading = true
        state.error = nil
        state.selectedDate = date
        
        Task {
            do {
                let tasks = try await todoDataService.loadTasks(for: date)
                await MainActor.run {
                    self.state.items = tasks
                    self.applyCurrentFilters()
                    self.state.isLoading = false
                    self.logger.info("Загружено \(tasks.count) задач для даты \(date)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.state.isLoading = false
                    self.logger.error("Ошибка загрузки задач: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func searchTasks(with query: String) {
        state.searchText = query
        applyCurrentFilters()
    }
    
    private func filterByCategory(_ category: TaskCategoryModel?) {
        state.selectedCategory = category
        applyCurrentFilters()
    }
    
    private func applyCurrentFilters() {
        var filteredItems = state.items
        
        // Фильтр по дате
        filteredItems = filteredItems.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: state.selectedDate)
        }
        
        // Фильтр по категории
        if let category = state.selectedCategory {
            filteredItems = filteredItems.filter { $0.categoryID == category.id }
        }
        
        // Фильтр по состоянию (завершенные/незавершенные)
        if state.showCompletedTasksOnly {
            filteredItems = filteredItems.filter { $0.isCompleted }
        }
        
        // Поиск по тексту
        if !state.searchText.isEmpty {
            filteredItems = filteredItems.filter { item in
                item.title.localizedCaseInsensitiveContains(state.searchText) ||
                (item.categoryName?.localizedCaseInsensitiveContains(state.searchText) ?? false)
            }
        }
        
        // Сортировка
        filteredItems = filteredItems.sorted { (item1, item2) -> Bool in
            if state.showCompletedTasksOnly {
                // Сортировка для архива
                if item1.priority != item2.priority {
                    return item1.priority.rawValue > item2.priority.rawValue
                }
                return item1.date > item2.date
            } else {
                // Стандартная сортировка
                if item1.isCompleted != item2.isCompleted {
                    return !item1.isCompleted
                }
                return item1.priority.rawValue > item2.priority.rawValue
            }
        }
        
        state.filteredItems = filteredItems
    }
    
    private func addTask(title: String, category: TaskCategoryModel?, priority: TaskPriority, date: Date) {
        guard !title.isEmpty else { return }
        
        Task {
            do {
                try await todoDataService.addTask(
                    title: title,
                    category: category,
                    priority: priority,
                    date: date
                )
                
                await MainActor.run {
                    self.state.showingAddTaskForm = false
                    self.handle(.loadTasks(self.state.selectedDate))
                    self.logger.info("Добавлена новая задача: \(title)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка добавления задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateTask(_ item: ToDoItem) {
        Task {
            do {
                logger.info("🔄 Обновляем задачу: \(item.id) с deadline: \(item.deadline?.description ?? "nil")")
                
                try await todoDataService.updateTask(item)
                
                await MainActor.run {
                    // 🔧 ИСПРАВЛЕНИЕ: Обновляем локальное состояние сразу
                    if let index = self.state.items.firstIndex(where: { $0.id == item.id }) {
                        self.state.items[index] = item
                        logger.info("✅ Локальное состояние обновлено для задачи: \(item.id)")
                    }
                    
                    // Применяем фильтры для обновления UI
                    self.applyCurrentFilters()
                    
                    self.state.editingItem = nil
                    self.logger.info("✅ Задача обновлена: \(item.id) с deadline: \(item.deadline?.description ?? "nil")")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("❌ Ошибка обновления задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteTask(with id: UUID) {
        Task {
            do {
                try await todoDataService.deleteTask(with: id)
                await MainActor.run {
                    self.handle(.loadTasks(self.state.selectedDate))
                    self.logger.info("Удалена задача: \(id)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка удаления задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleTaskCompletion(id: UUID) {
        guard let task = state.items.first(where: { $0.id == id }) else {
            logger.warning("Задача с ID \(id) не найдена для переключения статуса")
            return
        }
        
        let updatedTask = ToDoItem(
            id: task.id,
            title: task.title,
            date: task.date,
            isCompleted: !task.isCompleted,
            categoryID: task.categoryID,
            categoryName: task.categoryName,
            priority: task.priority,
            deadline: task.deadline
        )
        
        handle(.updateTask(updatedTask))
    }
    
    private func changePriority(id: UUID, priority: TaskPriority) {
        guard let task = state.items.first(where: { $0.id == id }) else {
            logger.warning("Задача с ID \(id) не найдена для изменения приоритета")
            return
        }
        
        let updatedTask = ToDoItem(
            id: task.id,
            title: task.title,
            date: task.date,
            isCompleted: task.isCompleted,
            categoryID: task.categoryID,
            categoryName: task.categoryName,
            priority: priority,
            deadline: task.deadline
        )
        
        handle(.updateTask(updatedTask))
    }
    
    private func updateTaskDate(id: UUID, newDate: Date) {
        guard let task = state.items.first(where: { $0.id == id }) else {
            logger.warning("Задача с ID \(id) не найдена для изменения даты")
            return
        }
        
        let updatedTask = ToDoItem(
            id: task.id,
            title: task.title,
            date: newDate,
            isCompleted: task.isCompleted,
            categoryID: task.categoryID,
            categoryName: task.categoryName,
            priority: task.priority,
            deadline: task.deadline
        )
        
        handle(.updateTask(updatedTask))
    }
    
    private func setDeadline(id: UUID, deadline: Date?) {
        guard let task = state.items.first(where: { $0.id == id }) else {
            logger.warning("Задача с ID \(id) не найдена для установки deadline")
            return
        }
        
        let updatedTask = ToDoItem(
            id: task.id,
            title: task.title,
            date: task.date,
            isCompleted: task.isCompleted,
            categoryID: task.categoryID,
            categoryName: task.categoryName,
            priority: task.priority,
            deadline: deadline
        )
        
        handle(.updateTask(updatedTask))
    }
    
    private func archiveCompletedTasks() {
        let completedTasks = state.items.filter { $0.isCompleted }
        
        Task {
            do {
                for task in completedTasks {
                    try await todoDataService.deleteTask(with: task.id)
                }
                
                await MainActor.run {
                    self.handle(.loadTasks(self.state.selectedDate))
                    self.logger.info("Архивировано \(completedTasks.count) завершенных задач")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка архивации задач: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func setDeadlineForSelectedTasks(_ deadline: Date?) {
        let deadlineDescription = deadline?.description ?? "nil (сброс)"
        logger.info("🎯 Устанавливаем deadline для \(self.state.selectedTasks.count) задач: \(deadlineDescription)")
        
        let selectedTaskIds = Array(self.state.selectedTasks) // Копируем чтобы не потерять после clearSelection
        
        Task {
            var successCount = 0
            var errorCount = 0
            
            // Обновляем каждую задачу последовательно
            for taskId in selectedTaskIds {
                logger.info("📝 Устанавливаем deadline для задачи: \(taskId)")
                
                guard let task = self.state.items.first(where: { $0.id == taskId }) else {
                    logger.warning("❌ Задача с ID \(taskId) не найдена для установки deadline")
                    errorCount += 1
                    continue
                }
                
                let updatedTask = ToDoItem(
                    id: task.id,
                    title: task.title,
                    date: task.date,
                    isCompleted: task.isCompleted,
                    categoryID: task.categoryID,
                    categoryName: task.categoryName,
                    priority: task.priority,
                    deadline: deadline
                )
                
                do {
                    logger.info("💾 Сохраняем задачу \(taskId) с deadline: \(deadlineDescription)")
                    try await todoDataService.updateTask(updatedTask)
                    
                    await MainActor.run {
                        // Обновляем локальное состояние сразу
                        if let index = self.state.items.firstIndex(where: { $0.id == taskId }) {
                            self.state.items[index] = updatedTask
                            logger.info("✅ Локально обновлена задача \(taskId)")
                        }
                    }
                    
                    successCount += 1
                    logger.info("✅ Успешно установлен deadline для задачи: \(taskId)")
                } catch {
                    errorCount += 1
                    logger.error("❌ Ошибка установки deadline для задачи \(taskId): \(error)")
                }
            }
            
            // После завершения всех операций обновляем UI
            await MainActor.run {
                logger.info("🎉 Завершено: успешно \(successCount), ошибок \(errorCount)")
                
                // Принудительно применяем фильтры для обновления UI
                self.applyCurrentFilters()
                
                // Принудительно обновляем данные из базы
                self.handle(.loadTasks(self.state.selectedDate))
                
                // Очищаем выделение только после успешного сохранения
                if successCount > 0 {
                    self.state.selectedTasks.removeAll()
                    self.state.isSelectionMode = false
                }
                
                if deadline == nil {
                    logger.info("🗑️ Завершен сброс deadline для всех выбранных задач")
                } else {
                    logger.info("✅ Завершена установка deadline для всех выбранных задач")
                }
            }
        }
    }
}

// MARK: - Convenience Methods
extension ListViewModel {
    
    /// Получает задачи для сегодняшнего дня
    func loadTodayTasks() {
        handle(.loadTasks(Date()))
    }
    
    /// Очищает все фильтры
    func clearFilters() {
        handle(.searchTasks(""))
        handle(.filterByCategory(nil as TaskCategoryModel?))
    }
    
    /// Получает отфильтрованные задачи для UI
    func getFilteredItems() -> [ToDoItem] {
        return items
    }
    
    /// Получает архивные задачи
    func getAllArchivedItems() -> [ToDoItem] {
        return state.items.filter { $0.isCompleted }
    }
    
    /// Получает количество завершенных задач
    var completedTasksCount: Int {
        items.filter { $0.isCompleted }.count
    }
    
    /// Получает количество активных задач
    var activeTasksCount: Int {
        items.filter { !$0.isCompleted }.count
    }
    
    /// Проверяет, есть ли задачи для отображения
    var hasTasks: Bool {
        !items.isEmpty
    }
    
    /// Получает статистику выполнения задач
    var completionPercentage: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(items.count) * 100
    }
    
    // MARK: - Helper Methods для UI
    
    func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high: return Color.red
        case .medium: return Color.orange
        case .low: return Color.green
        @unknown default: return Color.gray
        }
    }
    
    func priorityIcon(for priority: TaskPriority) -> String {
        switch priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .low: return "arrow.up.circle.fill"
        @unknown default: return "list.bullet"
        }
    }
    
    func getPriorityText(for priority: TaskPriority) -> String {
        switch priority {
        case .high: return "Высокий приоритет"
        case .medium: return "Средний приоритет"
        case .low: return "Низкий приоритет"
        @unknown default: return "Без приоритета"
        }
    }
    
    // MARK: - Batch Operations для выбранных задач
    
    func deleteSelectedTasks() {
        for taskId in self.state.selectedTasks {
            handle(.deleteTask(taskId))
        }
        handle(.clearSelection)
    }
    
    func unarchiveSelectedTasks() {
        for taskId in self.state.selectedTasks {
            handle(.toggleTaskCompletion(taskId))
        }
        handle(.clearSelection)
    }
    
    func setPriorityForSelectedTasks(_ priority: TaskPriority) {
        for taskId in self.state.selectedTasks {
            handle(.changePriority(taskId, priority))
        }
        handle(.clearSelection)
        handle(.toggleSelectionMode)
    }
    
    func moveSelectedTasksToDate(_ targetDate: Date) {
        for taskId in self.state.selectedTasks {
            handle(.updateTaskDate(taskId, targetDate))
        }
        handle(.clearSelection)
        handle(.toggleSelectionMode)
    }
    
    func toggleTaskSelection(taskId: UUID) {
        if self.state.selectedTasks.contains(taskId) {
            handle(.deselectTask(taskId))
        } else {
            handle(.selectTask(taskId))
        }
    }
    
    /// Сохраняет новую задачу с приоритетом (совместимость с старым API)
    func saveNewTask(title: String, priority: TaskPriority) {
        handle(.addTask(
            title: title,
            category: self.state.selectedCategory,
            priority: priority,
            date: self.state.selectedDate
        ))
    }
} 