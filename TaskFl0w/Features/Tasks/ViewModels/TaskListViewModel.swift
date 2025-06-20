//
//  TaskListViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import Combine
import CoreData
import OSLog

// MARK: - View State
struct TaskListViewState {
    var tasks: [TaskOnRing] = []
    var filteredTasks: [TaskOnRing] = []
    var selectedCategory: TaskCategoryModel?
    var searchText = ""
    var isLoading = false
    var error: String?
    var showingAddTaskForm = false
    var editingTask: TaskOnRing?
    
    // ДОБАВЛЯЕМ SUPPORT для ToDoItem
    var todoItems: [ToDoItem] = []
    var filteredTodoItems: [ToDoItem] = []
    var selectedDate = Date()
    var editingTodoItem: ToDoItem?
    var showCompletedTasksOnly = false
    var selectedTasks: Set<UUID> = []
    var isSelectionMode = false
}

// MARK: - View Actions
enum TaskListAction {
    case loadTasks(Date)
    case searchTasks(String)
    case filterByCategory(TaskCategoryModel?)
    case addTask(TaskOnRing)
    case updateTask(TaskOnRing)
    case deleteTask(UUID)
    case toggleTaskCompletion(UUID)
    case showAddTaskForm
    case hideAddTaskForm
    case editTask(TaskOnRing?)
    case clearError
    
    // ДОБАВЛЯЕМ ACTIONS для ToDoItem
    case loadTodoItems(Date)
    case addTodoItem(title: String, category: TaskCategoryModel?, priority: TaskPriority, date: Date)
    case updateTodoItem(ToDoItem)
    case deleteTodoItem(UUID)
    case toggleTodoCompletion(UUID)
    case changeTodoPriority(UUID, TaskPriority)
    case updateTodoDate(UUID, Date)
    case setTodoDeadline(UUID, Date)
    case archiveCompletedTodos
    case editTodoItem(ToDoItem?)
    case toggleSelectionMode
    case selectTodoTask(UUID)
    case deselectTodoTask(UUID)
    case clearSelection
    case showCompletedTodos(Bool)
}

/// Улучшенный ViewModel для управления списком задач
@MainActor
final class TaskListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state = TaskListViewState()
    
    // MARK: - Computed Properties
    var tasks: [TaskOnRing] { state.filteredTasks.isEmpty && state.searchText.isEmpty ? state.tasks : state.filteredTasks }
    var selectedCategory: TaskCategoryModel? { 
        get { state.selectedCategory }
        set { handle(.filterByCategory(newValue)) }
    }
    var searchText: String {
        get { state.searchText }
        set { handle(.searchTasks(newValue)) }
    }
    var isLoading: Bool { state.isLoading }
    var error: String? { state.error }
    var showingAddTaskForm: Bool { state.showingAddTaskForm }
    var editingTask: TaskOnRing? { state.editingTask }
    
    // ДОБАВЛЯЕМ COMPUTED PROPERTIES для ToDoItem
    var todoItems: [ToDoItem] { 
        state.filteredTodoItems.isEmpty && state.searchText.isEmpty ? state.todoItems : state.filteredTodoItems 
    }
    var selectedDate: Date {
        get { state.selectedDate }
        set { handle(.loadTodoItems(newValue)) }
    }
    var editingTodoItem: ToDoItem? { 
        get { state.editingTodoItem }
        set { handle(.editTodoItem(newValue)) }
    }
    var showCompletedTasksOnly: Bool { state.showCompletedTasksOnly }
    var selectedTasks: Set<UUID> { state.selectedTasks }
    var isSelectionMode: Bool { state.isSelectionMode }
    
    // Legacy совместимость
    var items: [ToDoItem] { todoItems }
    var editingItem: ToDoItem? { 
        get { editingTodoItem }
        set { editingTodoItem = newValue }
    }
    
    // MARK: - Private Properties
    private weak var appState: SharedStateService?
    private let taskService: TaskService?
    private var todoDataService: TodoDataService?
    private let logger = Logger(subsystem: "TaskFl0w", category: "TaskListViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        appState: SharedStateService? = nil, 
        taskService: TaskService? = nil,
        todoDataService: TodoDataService? = nil,
        selectedCategory: TaskCategoryModel? = nil
    ) {
        self.appState = appState
        self.taskService = taskService
        self.todoDataService = todoDataService
        self.state.selectedCategory = selectedCategory
        
        // Создаем TodoDataService если не передан
        if todoDataService == nil {
            let context = PersistenceController.shared.container.viewContext
            self.todoDataService = TodoDataService(context: context)
        }
        
        setupBindings()
        
        // Загружаем начальные данные
        if let appState = appState {
            state.tasks = appState.tasks
        }
        
        // Загружаем ToDo items
        handle(.loadTodoItems(Date()))
    }
    
    // MARK: - Action Handler
    func handle(_ action: TaskListAction) {
        switch action {
        case .loadTasks(let date):
            loadTasks(for: date)
        case .searchTasks(let query):
            searchTasks(with: query)
        case .filterByCategory(let category):
            filterByCategory(category)
        case .addTask(let task):
            addTask(task)
        case .updateTask(let task):
            updateTask(task)
        case .deleteTask(let id):
            deleteTask(with: id)
        case .toggleTaskCompletion(let id):
            toggleTaskCompletion(id: id)
        case .showAddTaskForm:
            state.showingAddTaskForm = true
        case .hideAddTaskForm:
            state.showingAddTaskForm = false
        case .editTask(let task):
            state.editingTask = task
        case .clearError:
            state.error = nil
            
        // ОБРАБОТКА ACTIONS для ToDoItem
        case .loadTodoItems(let date):
            loadTodoItems(for: date)
        case .addTodoItem(let title, let category, let priority, let date):
            addTodoItem(title: title, category: category, priority: priority, date: date)
        case .updateTodoItem(let item):
            updateTodoItem(item)
        case .deleteTodoItem(let id):
            deleteTodoItem(with: id)
        case .toggleTodoCompletion(let id):
            toggleTodoCompletion(id: id)
        case .changeTodoPriority(let id, let priority):
            changeTodoPriority(id: id, priority: priority)
        case .updateTodoDate(let id, let date):
            updateTodoDate(id: id, newDate: date)
        case .setTodoDeadline(let id, let deadline):
            setTodoDeadline(id: id, deadline: deadline)
        case .archiveCompletedTodos:
            archiveCompletedTodos()
        case .editTodoItem(let item):
            state.editingTodoItem = item
        case .toggleSelectionMode:
            state.isSelectionMode.toggle()
            if !state.isSelectionMode {
                state.selectedTasks.removeAll()
            }
        case .selectTodoTask(let id):
            state.selectedTasks.insert(id)
        case .deselectTodoTask(let id):
            state.selectedTasks.remove(id)
        case .clearSelection:
            state.selectedTasks.removeAll()
        case .showCompletedTodos(let show):
            state.showCompletedTasksOnly = show
            applyTodoFilters()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Подписываемся на изменения в AppState
        appState?.$tasks
            .sink { [weak self] tasks in
                self?.handleTasksUpdate(tasks)
            }
            .store(in: &cancellables)
    }
    
    private func handleTasksUpdate(_ newTasks: [TaskOnRing]) {
        state.tasks = newTasks
        applyCurrentFilters()
    }
    
    private func loadTasks(for date: Date) {
        state.isLoading = true
        state.error = nil
        
        Task {
            await appState?.loadTasks(for: date)
            await MainActor.run {
                self.state.isLoading = false
            }
        }
    }
    
    private func searchTasks(with query: String) {
        state.searchText = query
        applyCurrentFilters()
        applyTodoFilters()
    }
    
    private func filterByCategory(_ category: TaskCategoryModel?) {
        state.selectedCategory = category
        applyCurrentFilters()
        applyTodoFilters()
    }
    
    private func applyCurrentFilters() {
        var filteredTasks = state.tasks
        
        // Фильтр по категории
        if let category = state.selectedCategory {
            filteredTasks = filteredTasks.filter { $0.category.id == category.id }
        }
        
        // Поиск по тексту
        if !state.searchText.isEmpty {
            filteredTasks = filteredTasks.filter { task in
                task.icon.localizedCaseInsensitiveContains(state.searchText) ||
                task.category.rawValue.localizedCaseInsensitiveContains(state.searchText)
            }
        }
        
        state.filteredTasks = filteredTasks
    }
    
    private func addTask(_ task: TaskOnRing) {
        Task {
            await appState?.addTask(task)
            await MainActor.run {
                self.state.showingAddTaskForm = false
                self.logger.info("Добавлена новая задача: \(task.id)")
            }
        }
    }
    
    private func updateTask(_ task: TaskOnRing) {
        Task {
            await appState?.updateTask(task)
            await MainActor.run {
                self.state.editingTask = nil
                self.logger.info("Обновлена задача: \(task.id)")
            }
        }
    }
    
    private func deleteTask(with id: UUID) {
        Task {
            await appState?.deleteTask(with: id)
            await MainActor.run {
                self.logger.info("Удалена задача: \(id)")
            }
        }
    }
    
    private func toggleTaskCompletion(id: UUID) {
        guard let task = state.tasks.first(where: { $0.id == id }) else {
            logger.warning("Задача с ID \(id) не найдена для переключения статуса")
            return
        }
        
        let updatedTask = TaskOnRing(
            id: task.id,
            startTime: task.startTime,
            endTime: task.endTime,
            color: task.color,
            icon: task.icon,
            category: task.category,
            isCompleted: !task.isCompleted
        )
        
        handle(.updateTask(updatedTask))
    }
    
    // MARK: - ToDo Item Methods
    
    private func loadTodoItems(for date: Date) {
        state.isLoading = true
        state.error = nil
        state.selectedDate = date
        
        Task {
            do {
                let items = try await todoDataService?.loadTasks(for: date) ?? []
                await MainActor.run {
                    self.state.todoItems = items
                    self.applyTodoFilters()
                    self.state.isLoading = false
                    self.logger.info("Загружено \(items.count) ToDo items для даты \(date)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.state.isLoading = false
                    self.logger.error("Ошибка загрузки ToDo items: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func addTodoItem(title: String, category: TaskCategoryModel?, priority: TaskPriority, date: Date) {
        guard !title.isEmpty else { return }
        
        Task {
            do {
                try await todoDataService?.addTask(title: title, category: category, priority: priority, date: date)
                await MainActor.run {
                    self.state.showingAddTaskForm = false
                    self.handle(.loadTodoItems(self.state.selectedDate))
                    self.logger.info("Добавлена новая ToDo задача: \(title)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка добавления ToDo задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateTodoItem(_ item: ToDoItem) {
        Task {
            do {
                try await todoDataService?.updateTask(item)
                await MainActor.run {
                    self.state.editingTodoItem = nil
                    self.handle(.loadTodoItems(self.state.selectedDate))
                    self.logger.info("Обновлена ToDo задача: \(item.id)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка обновления ToDo задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteTodoItem(with id: UUID) {
        Task {
            do {
                try await todoDataService?.deleteTask(with: id)
                await MainActor.run {
                    self.handle(.loadTodoItems(self.state.selectedDate))
                    self.logger.info("Удалена ToDo задача: \(id)")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка удаления ToDo задачи: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func toggleTodoCompletion(id: UUID) {
        guard let task = state.todoItems.first(where: { $0.id == id }) else {
            logger.warning("ToDo задача с ID \(id) не найдена для переключения статуса")
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
        
        handle(.updateTodoItem(updatedTask))
    }
    
    private func changeTodoPriority(id: UUID, priority: TaskPriority) {
        guard let task = state.todoItems.first(where: { $0.id == id }) else {
            logger.warning("ToDo задача с ID \(id) не найдена для изменения приоритета")
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
        
        handle(.updateTodoItem(updatedTask))
    }
    
    private func updateTodoDate(id: UUID, newDate: Date) {
        guard let task = state.todoItems.first(where: { $0.id == id }) else {
            logger.warning("ToDo задача с ID \(id) не найдена для изменения даты")
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
        
        handle(.updateTodoItem(updatedTask))
    }
    
    private func setTodoDeadline(id: UUID, deadline: Date) {
        guard let task = state.todoItems.first(where: { $0.id == id }) else {
            logger.warning("ToDo задача с ID \(id) не найдена для установки deadline")
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
        
        handle(.updateTodoItem(updatedTask))
    }
    
    private func archiveCompletedTodos() {
        Task {
            do {
                try await todoDataService?.archiveCompletedTasks()
                await MainActor.run {
                    self.handle(.loadTodoItems(self.state.selectedDate))
                    self.logger.info("Архивированы выполненные ToDo задачи")
                }
            } catch {
                await MainActor.run {
                    self.state.error = error.localizedDescription
                    self.logger.error("Ошибка архивации ToDo задач: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func applyTodoFilters() {
        var filteredItems = state.todoItems
        
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
        
        state.filteredTodoItems = filteredItems
    }
}

// MARK: - Convenience Methods
extension TaskListViewModel {
    
    /// Получает задачи для сегодняшнего дня
    func loadTodayTasks() {
        handle(.loadTasks(Date()))
        handle(.loadTodoItems(Date()))
    }
    
    /// Очищает все фильтры
    func clearFilters() {
        handle(.searchTasks(""))
        handle(.filterByCategory(nil as TaskCategoryModel?))
    }
    
    /// Получает количество завершенных задач
    var completedTasksCount: Int {
        todoItems.filter { $0.isCompleted }.count
    }
    
    /// Получает количество активных задач
    var activeTasksCount: Int {
        todoItems.filter { !$0.isCompleted }.count
    }
    
    /// Проверяет, есть ли задачи для отображения
    var hasTasks: Bool {
        !todoItems.isEmpty
    }
    
    /// Получает статистику выполнения задач
    var completionPercentage: Double {
        guard !todoItems.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(todoItems.count) * 100
    }
    
    // MARK: - Legacy Compatibility Methods
    
    func getFilteredItems() -> [ToDoItem] {
        return todoItems
    }
    
    func getAllArchivedItems() -> [ToDoItem] {
        return state.todoItems.filter { $0.isCompleted }
    }
    
    func saveNewTask(title: String, priority: TaskPriority) {
        handle(.addTodoItem(
            title: title,
            category: state.selectedCategory,
            priority: priority,
            date: state.selectedDate
        ))
    }
    
    func deleteSelectedTasks() {
        for taskId in state.selectedTasks {
            handle(.deleteTodoItem(taskId))
        }
        handle(.clearSelection)
    }
    
    func unarchiveSelectedTasks() {
        for taskId in state.selectedTasks {
            handle(.toggleTodoCompletion(taskId))
        }
        handle(.clearSelection)
    }
    
    func setPriorityForSelectedTasks(_ priority: TaskPriority) {
        for taskId in state.selectedTasks {
            handle(.changeTodoPriority(taskId, priority))
        }
        handle(.clearSelection)
        handle(.toggleSelectionMode)
    }
    
    func moveSelectedTasksToDate(_ targetDate: Date) {
        for taskId in state.selectedTasks {
            handle(.updateTodoDate(taskId, targetDate))
        }
        handle(.clearSelection)
        handle(.toggleSelectionMode)
    }
    
    func setDeadlineForSelectedTasks(_ deadline: Date) {
        for taskId in state.selectedTasks {
            handle(.setTodoDeadline(taskId, deadline))
        }
        handle(.clearSelection)
        handle(.toggleSelectionMode)
    }
    
    func toggleTaskSelection(taskId: UUID) {
        if state.selectedTasks.contains(taskId) {
            handle(.deselectTodoTask(taskId))
        } else {
            handle(.selectTodoTask(taskId))
        }
    }
    
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
    
    func refreshData() {
        handle(.loadTodoItems(state.selectedDate))
    }
    
    func onViewDidLoad() {
        handle(.loadTodoItems(state.selectedDate))
    }
    
    func checkUncompletedPastTasks() {
        // Функция для проверки невыполненных задач из прошлого
        // Реализация переносится из старого ListViewModel
    }
}

// MARK: - TodoDataService Helper
extension TaskListViewModel {
    class TodoDataService {
        private let context: NSManagedObjectContext
        private let logger = Logger(subsystem: "TaskFl0w", category: "TodoDataService")
        
        init(context: NSManagedObjectContext) {
            self.context = context
        }
        
        func loadTasks(for date: Date) async throws -> [ToDoItem] {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
            request.predicate = NSPredicate(
                format: "date >= %@ AND date < %@",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: true),
                NSSortDescriptor(key: "priority", ascending: false)
            ]
            
            do {
                let results = try context.fetch(request)
                let items = results.compactMap { convertToToDoItem($0) }
                return items
            } catch {
                throw error
            }
        }
        
        func addTask(title: String, category: TaskCategoryModel?, priority: TaskPriority, date: Date) async throws {
            guard let entity = NSEntityDescription.entity(forEntityName: "CDToDoItem", in: context) else {
                throw NSError(domain: "TodoDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Entity not found"])
            }
            
            let newItem = NSManagedObject(entity: entity, insertInto: context)
            let newID = UUID()
            
            newItem.setValue(newID, forKey: "id")
            newItem.setValue(title, forKey: "title")
            newItem.setValue(date, forKey: "date")
            newItem.setValue(false, forKey: "isCompleted")
            newItem.setValue(Int(priority.rawValue), forKey: "priority")
            
            if let category = category {
                newItem.setValue(category.id, forKey: "categoryID")
                newItem.setValue(category.rawValue, forKey: "categoryName")
            }
            
            try saveContext()
        }
        
        func updateTask(_ item: ToDoItem) async throws {
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
            request.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
            request.fetchLimit = 1
            
            let results = try context.fetch(request)
            guard let entity = results.first else {
                throw NSError(domain: "TodoDataService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
            }
            
            entity.setValue(item.title, forKey: "title")
            entity.setValue(item.date, forKey: "date")
            entity.setValue(item.isCompleted, forKey: "isCompleted")
            entity.setValue(Int(item.priority.rawValue), forKey: "priority")
            entity.setValue(item.categoryID, forKey: "categoryID")
            entity.setValue(item.categoryName, forKey: "categoryName")
            
            try saveContext()
        }
        
        func deleteTask(with id: UUID) async throws {
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let results = try context.fetch(request)
            guard let taskToDelete = results.first else {
                throw NSError(domain: "TodoDataService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Task not found"])
            }
            
            context.delete(taskToDelete)
            try saveContext()
        }
        
        func archiveCompletedTasks() async throws {
            let request = NSFetchRequest<NSManagedObject>(entityName: "CDToDoItem")
            request.predicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: true))
            
            let completedItems = try context.fetch(request)
            for item in completedItems {
                context.delete(item)
            }
            try saveContext()
        }
        
        private func convertToToDoItem(_ entity: NSManagedObject) -> ToDoItem? {
            guard let id = entity.value(forKey: "id") as? UUID,
                  let title = entity.value(forKey: "title") as? String,
                  let date = entity.value(forKey: "date") as? Date,
                  let isCompleted = entity.value(forKey: "isCompleted") as? Bool else {
                return nil
            }
            
            let categoryID = entity.value(forKey: "categoryID") as? UUID
            let categoryName = entity.value(forKey: "categoryName") as? String
            let priorityRaw = entity.value(forKey: "priority") as? Int ?? 0
            let priority = TaskPriority(rawValue: priorityRaw) ?? .none
            
            return ToDoItem(
                id: id,
                title: title,
                date: date,
                isCompleted: isCompleted,
                categoryID: categoryID,
                categoryName: categoryName,
                priority: priority,
                deadline: nil
            )
        }
        
        private func saveContext() throws {
            guard context.hasChanges else { return }
            try context.save()
        }
    }
} 
