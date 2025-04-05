import Combine
import CoreData
import SwiftUI

final class TaskManager: ObservableObject {
    // MARK: - Services
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol

    // MARK: - Published properties
    @Published var tasks: [TaskOnRing] = []

    // MARK: - Drag & Drop
    let dragAndDropManager: DragAndDropManager

    // MARK: - Task states
    @Published var draggedTask: TaskOnRing?
    @Published var isDraggingOutside: Bool = false
    @Published var isEditingMode: Bool = false
    @Published var editingTask: TaskOnRing?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTask: TaskOnRing?
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""

    // MARK: - Category states
    @Published var showingCategoryEditor: Bool = false
    @Published var selectedCategory: TaskCategoryModel?
    @Published var draggedCategory: TaskCategoryModel?

    // MARK: - View states
    @Published var showingAddTask: Bool = false
    @Published var showingTodayTasks: Bool = false

    // MARK: - Initialization
    init(sharedState: SharedStateService = .shared) {
        self.sharedState = sharedState

        // Инициализируем TaskManagement
        let initialDate = Date()
        let taskManagement = TaskManagement(sharedState: sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement

        // Инициализируем CategoryManagement
        self.categoryManagement = CategoryManagement(
            context: sharedState.context, sharedState: sharedState)

        // Инициализируем DragAndDropManager
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)

        // Подписываемся на обновления задач
        sharedState.subscribeToTasksUpdates { [weak self] in
            self?.tasks = sharedState.tasks
        }

        self.tasks = sharedState.tasks
    }

    // MARK: - Task management methods
    func startDragging(_ task: TaskOnRing) {
        dragAndDropManager.startDragging(task)
    }

    func stopDragging(didReturnToClock: Bool) {
        dragAndDropManager.stopDragging(didReturnToClock: didReturnToClock)
    }

    func updateDragPosition(isOutsideClock: Bool) {
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }

    // MARK: - Task filtering
    func tasksForSelectedDate(_ allTasks: [TaskOnRing], selectedDate: Date) -> [TaskOnRing] {
        allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
    }

    // MARK: - Task creation
    func createTaskAtLocation(
        location: CGPoint, screenWidth: CGFloat, clockState: ClockStateManager
    ) -> TaskOnRing? {
        guard let category = draggedCategory else { return nil }

        let time = clockState.timeForLocation(
            location,
            screenWidth: screenWidth
        )

        // Создаём новую задачу
        let newTask = TaskOnRing(
            id: UUID(),
            title: "Новая задача",
            startTime: time,
            endTime: Calendar.current.date(byAdding: .hour, value: 1, to: time) ?? time,
            color: category.color,
            icon: category.iconName,
            category: category,
            isCompleted: false
        )

        taskManagement.addTask(newTask)

        // Включаем режим редактирования
        isEditingMode = true
        editingTask = newTask

        return newTask
    }

    // MARK: - Task deletion
    func deleteTask(_ task: TaskOnRing) {
        taskManagement.removeTask(task)
    }

    // MARK: - Task editing
    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date) {
        taskManagement.updateTaskStartTimeKeepingEnd(task, newStartTime: newStartTime)
    }

    func updateTaskEndTime(_ task: TaskOnRing, newEndTime: Date) {
        taskManagement.updateTaskDuration(task, newEndTime: newEndTime)
    }

    // MARK: - Category access
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }

    // MARK: - Category management methods
    func addCategory(_ category: TaskCategoryModel) {
        categoryManagement.addCategory(category)
    }

    func updateCategory(_ category: TaskCategoryModel) {
        categoryManagement.updateCategory(category)
    }

    func removeCategory(_ category: TaskCategoryModel) {
        categoryManagement.removeCategory(category)
    }
}
