//
//  TaskRenderingViewModel.swift  
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import Combine

// MARK: - View State
struct TaskRenderingViewState {
    var tasks: [TaskOnRing] = []
    var overlappingTaskGroups: [[TaskOnRing]] = []
    var previewTask: TaskOnRing?
    var searchText = ""
    var isLoading = false
    var error: String?
}

// MARK: - View Actions
enum TaskRenderingAction {
    case loadTasks(Date)
    case searchTasks(String)
    case validateOverlaps
    case clearError
    case setPreviewTask(TaskOnRing?)
}

/// Улучшенный ViewModel для управления отображением задач на циферблате
@MainActor
final class TaskRenderingViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var state = TaskRenderingViewState()
    
    // MARK: - Computed Properties
    var tasks: [TaskOnRing] { state.tasks }
    var overlappingTaskGroups: [[TaskOnRing]] { state.overlappingTaskGroups }
    var previewTask: TaskOnRing? { 
        get { state.previewTask }
        set { state.previewTask = newValue }
    }
    var searchText: String {
        get { state.searchText }
        set { 
            state.searchText = newValue
            handle(.searchTasks(newValue))
        }
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private weak var sharedState: SharedStateService?
    
    // MARK: - Initialization
    init(sharedState: SharedStateService) {
        self.sharedState = sharedState
        self.state.tasks = sharedState.tasks
        
        setupBindings()
    }
    
    // MARK: - Action Handler
    func handle(_ action: TaskRenderingAction) {
        switch action {
        case .loadTasks(let date):
            loadTasks(for: date)
        case .searchTasks(let query):
            searchTasks(with: query)
        case .validateOverlaps:
            validateTaskOverlaps()
        case .clearError:
            state.error = nil
        case .setPreviewTask(let task):
            state.previewTask = task
        }
    }
    
    // MARK: - Public Methods
    
    /// Находит пересекающиеся группы задач
    func findOverlappingTaskGroups(_ tasksToCheck: [TaskOnRing]) -> [[TaskOnRing]] {
        var overlappingGroups: [[TaskOnRing]] = []
        var processedTasks: Set<UUID> = []
        
        for task in tasksToCheck.sorted(by: { $0.startTime < $1.startTime }) {
            guard !processedTasks.contains(task.id) else { continue }
            
            var currentGroup: [TaskOnRing] = [task]
            processedTasks.insert(task.id)
            
            // Находим все задачи, которые пересекаются с текущей задачей
            for otherTask in tasksToCheck where !processedTasks.contains(otherTask.id) {
                if tasksOverlap(task, otherTask) {
                    currentGroup.append(otherTask)
                    processedTasks.insert(otherTask.id)
                }
            }
            
            // Добавляем группу только если она содержит более одной задачи
            if currentGroup.count > 1 {
                overlappingGroups.append(currentGroup)
            }
        }
        
        return overlappingGroups
    }
    
    /// Валидирует пересечения задач
    func validateTaskOverlaps() {
        let todayTasks = state.tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: Date())
        }
        
        state.overlappingTaskGroups = findOverlappingTaskGroups(todayTasks)
    }
    
    /// Обновляет задачи при изменении редактируемой задачи
    func updateEditingTaskIfNeeded(newTasks: [TaskOnRing], editingTask: TaskOnRing?) -> TaskOnRing? {
        guard let editingTask = editingTask else { return nil }
        
        if let updatedTask = newTasks.first(where: { $0.id == editingTask.id }) {
            guard !tasksAreEqual(editingTask, updatedTask) else { return editingTask }
            return updatedTask
        } else {
            // Edited task was deleted
            return nil
        }
    }
    
    /// Уведомляет компоненты TaskArcs об изменениях
    func notifyTaskArcsComponents(newTasks: [TaskOnRing]) {
        NotificationCenter.default.post(
            name: NSNotification.Name("TaskArcsTasksModified"),
            object: self,
            userInfo: ["modifiedTasks": newTasks]
        )
    }
    
    /// Обновляет статистику категорий
    func updateCategoryStatistics(_ tasks: [TaskOnRing]) {
        let categoryTaskCounts = Dictionary(grouping: tasks) { $0.category }
            .mapValues { $0.count }
        
        NotificationCenter.default.post(
            name: NSNotification.Name("CategoryStatisticsUpdated"),
            object: self,
            userInfo: ["categoryTaskCounts": categoryTaskCounts]
        )
    }
    
    // MARK: - Private Methods
    
    private func loadTasks(for date: Date) {
        guard let sharedState = sharedState else { return }
        
        state.isLoading = true
        state.error = nil
        
        Task {
            await sharedState.loadTasks(for: date)
            await MainActor.run {
                self.state.tasks = self.tasksForSelectedDate(date, allTasks: sharedState.tasks)
                self.state.isLoading = false
                self.validateTaskOverlaps()
            }
        }
    }
    
    private func searchTasks(with query: String) {
        guard let sharedState = sharedState else { return }
        
        if query.isEmpty {
            state.tasks = sharedState.tasks
        } else {
            state.tasks = sharedState.tasks.filter { task in
                task.icon.localizedCaseInsensitiveContains(query) ||
                task.category.rawValue.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    /// Фильтрует задачи для указанной даты
    func tasksForSelectedDate(_ selectedDate: Date, allTasks: [TaskOnRing] = []) -> [TaskOnRing] {
        let tasksToFilter = allTasks.isEmpty ? state.tasks : allTasks
        
        let tasksOnSelectedDate = tasksToFilter.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        let incompleteTasksFromPreviousDays = tasksToFilter.filter { task in
            !task.isCompleted && 
            Calendar.current.compare(task.startTime, to: selectedDate, toGranularity: .day) == .orderedAscending
        }
        
        return tasksOnSelectedDate + incompleteTasksFromPreviousDays
    }
    
    /// Обновляет задачи для выбранной даты
    func updateTasksForSelectedDate(_ selectedDate: Date) {
        handle(.loadTasks(selectedDate))
    }
    
    /// Фильтрует задачи по поисковому запросу
    func filteredTasks() -> [TaskOnRing] {
        guard !state.searchText.isEmpty else { return state.tasks }
        
        return state.tasks.filter { task in
            task.icon.localizedCaseInsensitiveContains(state.searchText) ||
            task.category.rawValue.localizedCaseInsensitiveContains(state.searchText)
        }
    }
    
    /// Получает активную задачу на текущий момент
    func getCurrentActiveTask() -> TaskOnRing? {
        let now = Date()
        return state.tasks.first { task in
            task.startTime <= now && task.endTime > now
        }
    }
    
    /// Получает задачи для конкретной категории
    func tasksForCategory(_ category: TaskCategoryModel) -> [TaskOnRing] {
        return state.tasks.filter { $0.category.id == category.id }
    }
    
    /// Получает статистику по категориям
    func getCategoryStatistics() -> [TaskCategoryModel: Int] {
        return Dictionary(grouping: state.tasks) { $0.category }
            .mapValues { $0.count }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        guard let sharedState = sharedState else { return }
        
        sharedState.subscribeToTasksUpdates { [weak self] in
            guard let self = self else { return }
            self.handleTasksUpdate()
        }
    }
    
    private func handleTasksUpdate() {
        guard let sharedState = sharedState else { return }
        
        let newTasks = sharedState.tasks
        
        // Проверяем, изменились ли задачи
        guard !tasksAreEqual(state.tasks, newTasks) else { return }
        
        state.tasks = newTasks
        validateTaskOverlaps()
        
        // Уведомляем компоненты TaskArcs об изменениях
        notifyTaskArcsComponents(newTasks: newTasks)
        
        // Обновляем статистику категорий
        updateCategoryStatistics(newTasks)
    }
    
    private func tasksOverlap(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        return task1.startTime < task2.endTime && task1.endTime > task2.startTime
    }
    
    private func tasksAreEqual(_ tasks1: [TaskOnRing], _ tasks2: [TaskOnRing]) -> Bool {
        return tasks1.count == tasks2.count && 
               zip(tasks1, tasks2).allSatisfy { tasksAreEqual($0, $1) }
    }
    
    private func tasksAreEqual(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        return task1.id == task2.id &&
               task1.startTime == task2.startTime &&
               task1.endTime == task2.endTime &&
               task1.category.id == task2.category.id &&
               task1.isCompleted == task2.isCompleted
    }
}

// MARK: - TaskRenderingProtocol

protocol TaskRenderingProtocol: ObservableObject {
    var tasks: [TaskOnRing] { get }
    var overlappingTaskGroups: [[TaskOnRing]] { get }
    var previewTask: TaskOnRing? { get set }
    
    func tasksForSelectedDate(_ selectedDate: Date, allTasks: [TaskOnRing]) -> [TaskOnRing]
    func updateTasksForSelectedDate(_ selectedDate: Date)
    func findOverlappingTaskGroups(_ tasksToCheck: [TaskOnRing]) -> [[TaskOnRing]]
    func validateTaskOverlaps()
    func getCurrentActiveTask() -> TaskOnRing?
}

extension TaskRenderingViewModel: TaskRenderingProtocol {}


