//
//  TaskListViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation
import SwiftUI
import Combine
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
    
    // MARK: - Private Properties
    private weak var appState: SharedStateService?
    private let taskService: TaskService?
    private let logger = Logger(subsystem: "TaskFl0w", category: "TaskListViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(appState: SharedStateService? = nil, taskService: TaskService? = nil) {
        self.appState = appState
        self.taskService = taskService
        
        setupBindings()
        
        // Загружаем начальные данные
        if let appState = appState {
            state.tasks = appState.tasks
        }
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
    }
    
    private func filterByCategory(_ category: TaskCategoryModel?) {
        state.selectedCategory = category
        applyCurrentFilters()
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
}

// MARK: - Convenience Methods
extension TaskListViewModel {
    
    /// Получает задачи для сегодняшнего дня
    func loadTodayTasks() {
        handle(.loadTasks(Date()))
    }
    
    /// Очищает все фильтры
    func clearFilters() {
        handle(.searchTasks(""))
        handle(.filterByCategory(nil))
    }
    
    /// Получает количество завершенных задач
    var completedTasksCount: Int {
        tasks.filter(\.isCompleted).count
    }
    
    /// Получает количество активных задач
    var activeTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }
    
    /// Проверяет, есть ли задачи для отображения
    var hasTasks: Bool {
        !tasks.isEmpty
    }
    
    /// Получает статистику выполнения задач
    var completionPercentage: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasksCount) / Double(tasks.count) * 100
    }
} 