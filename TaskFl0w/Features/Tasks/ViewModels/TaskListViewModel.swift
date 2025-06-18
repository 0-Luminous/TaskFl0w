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
    private let taskRepository: TaskRepositoryProtocol?
    private let logger = Logger(subsystem: "TaskFl0w", category: "TaskListViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(appState: SharedStateService? = nil, taskRepository: TaskRepositoryProtocol? = nil) {
        self.appState = appState
        self.taskRepository = taskRepository
        
        setupBindings()

        // Загружаем начальные данные
        if let repo = taskRepository {
            Task { [weak self] in
                do {
                    let tasks = try await repo.fetchAll()
                    await MainActor.run {
                        self?.state.tasks = tasks
                    }
                } catch {
                    await MainActor.run {
                        self?.state.error = error.localizedDescription
                    }
                }
            }
        } else if let appState = appState {
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
            if let repo = taskRepository {
                do {
                    let tasks = try await repo.fetch(for: date)
                    await MainActor.run {
                        self.state.tasks = tasks
                        self.applyCurrentFilters()
                        self.state.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.state.error = error.localizedDescription
                        self.state.isLoading = false
                    }
                }
            } else {
                await appState?.loadTasks(for: date)
                await MainActor.run {
                    self.state.isLoading = false
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
            if let repo = taskRepository {
                do {
                    try await repo.save(task)
                    await MainActor.run {
                        self.state.tasks.append(task)
                        self.applyCurrentFilters()
                        self.state.showingAddTaskForm = false
                        self.logger.info("Добавлена новая задача: \(task.id)")
                    }
                } catch {
                    await MainActor.run { self.state.error = error.localizedDescription }
                }
            } else {
                await appState?.addTask(task)
                await MainActor.run {
                    self.state.showingAddTaskForm = false
                    self.logger.info("Добавлена новая задача: \(task.id)")
                }
            }
        }
    }
    
    private func updateTask(_ task: TaskOnRing) {
        Task {
            if let repo = taskRepository {
                do {
                    try await repo.update(task)
                    await MainActor.run {
                        if let index = self.state.tasks.firstIndex(where: { $0.id == task.id }) {
                            self.state.tasks[index] = task
                        }
                        self.applyCurrentFilters()
                        self.state.editingTask = nil
                        self.logger.info("Обновлена задача: \(task.id)")
                    }
                } catch {
                    await MainActor.run { self.state.error = error.localizedDescription }
                }
            } else {
                await appState?.updateTask(task)
                await MainActor.run {
                    self.state.editingTask = nil
                    self.logger.info("Обновлена задача: \(task.id)")
                }
            }
        }
    }
    
    private func deleteTask(with id: UUID) {
        Task {
            if let repo = taskRepository {
                do {
                    try await repo.delete(id: id)
                    await MainActor.run {
                        self.state.tasks.removeAll { $0.id == id }
                        self.applyCurrentFilters()
                        self.logger.info("Удалена задача: \(id)")
                    }
                } catch {
                    await MainActor.run { self.state.error = error.localizedDescription }
                }
            } else {
                await appState?.deleteTask(with: id)
                await MainActor.run {
                    self.logger.info("Удалена задача: \(id)")
                }
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