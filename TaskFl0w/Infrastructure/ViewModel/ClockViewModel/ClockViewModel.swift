//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import Combine
import CoreData
import SwiftUI

final class ClockViewModel: ObservableObject {
    // MARK: - Services
    let sharedState: SharedStateService
    let clockState: ClockStateManager
    let taskManager: TaskManager

    // MARK: - View Models
    let markersViewModel = ClockMarkersViewModel()

    // MARK: - View States
    @Published var isDockBarEditingEnabled: Bool = false
    @Published var showingSettings: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var selectedDate: Date = Date() {
        didSet {
            updateSelectedDate(selectedDate)
        }
    }
    @Published var zeroPosition: Double = 0.0

    // MARK: - Theme properties
    var isDarkMode: Bool {
        get { clockState.isDarkMode }
        set { clockState.isDarkMode = newValue }
    }

    var lightModeClockFaceColor: String {
        get { clockState.lightModeClockFaceColor }
        set { clockState.lightModeClockFaceColor = newValue }
    }

    var darkModeClockFaceColor: String {
        get { clockState.darkModeClockFaceColor }
        set { clockState.darkModeClockFaceColor = newValue }
    }

    // MARK: - Инициализация
    init(sharedState: SharedStateService = .shared) {
        self.sharedState = sharedState
        self.clockState = ClockStateManager()
        self.taskManager = TaskManager(sharedState: sharedState)
        self.selectedDate = clockState.selectedDate
    }

    // MARK: - Date management
    private func updateSelectedDate(_ date: Date) {
        clockState.selectedDate = date
    }

    // MARK: - Zero position management
    func updateZeroPosition(_ position: Double) {
        zeroPosition = position
        clockState.updateZeroPosition(position)
        markersViewModel.zeroPosition = position
    }

    // MARK: - Task access
    var tasks: [TaskOnRing] {
        taskManager.tasks
    }

    var categories: [TaskCategoryModel] {
        taskManager.categories
    }

    // MARK: - Task states
    var draggedTask: TaskOnRing? {
        get { taskManager.draggedTask }
        set { taskManager.draggedTask = newValue }
    }

    var isDraggingOutside: Bool {
        get { taskManager.isDraggingOutside }
        set { taskManager.isDraggingOutside = newValue }
    }

    var isEditingMode: Bool {
        get { taskManager.isEditingMode }
        set { taskManager.isEditingMode = newValue }
    }

    var editingTask: TaskOnRing? {
        get { taskManager.editingTask }
        set { taskManager.editingTask = newValue }
    }

    var isDraggingStart: Bool {
        get { taskManager.isDraggingStart }
        set { taskManager.isDraggingStart = newValue }
    }

    var isDraggingEnd: Bool {
        get { taskManager.isDraggingEnd }
        set { taskManager.isDraggingEnd = newValue }
    }

    var previewTime: Date? {
        get { taskManager.previewTime }
        set { taskManager.previewTime = newValue }
    }

    var dropLocation: CGPoint? {
        get { taskManager.dropLocation }
        set { taskManager.dropLocation = newValue }
    }

    var selectedTask: TaskOnRing? {
        get { taskManager.selectedTask }
        set { taskManager.selectedTask = newValue }
    }

    var showingTaskDetail: Bool {
        get { taskManager.showingTaskDetail }
        set { taskManager.showingTaskDetail = newValue }
    }

    var searchText: String {
        get { taskManager.searchText }
        set { taskManager.searchText = newValue }
    }

    // MARK: - Category states
    var showingCategoryEditor: Bool {
        get { taskManager.showingCategoryEditor }
        set { taskManager.showingCategoryEditor = newValue }
    }

    var selectedCategory: TaskCategoryModel? {
        get { taskManager.selectedCategory }
        set { taskManager.selectedCategory = newValue }
    }

    var draggedCategory: TaskCategoryModel? {
        get { taskManager.draggedCategory }
        set { taskManager.draggedCategory = newValue }
    }

    // MARK: - View states
    var showingAddTask: Bool {
        get { taskManager.showingAddTask }
        set { taskManager.showingAddTask = newValue }
    }

    var showingTodayTasks: Bool {
        get { taskManager.showingTodayTasks }
        set { taskManager.showingTodayTasks = newValue }
    }

    // MARK: - Task management methods
    func startDragging(_ task: TaskOnRing) {
        taskManager.startDragging(task)
    }

    func stopDragging(didReturnToClock: Bool) {
        taskManager.stopDragging(didReturnToClock: didReturnToClock)
    }

    func updateDragPosition(isOutsideClock: Bool) {
        taskManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }

    // MARK: - Task filtering
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        taskManager.tasksForSelectedDate(allTasks, selectedDate: clockState.selectedDate)
    }

    // MARK: - Task creation
    func createTaskAtLocation(location: CGPoint, screenWidth: CGFloat) -> TaskOnRing? {
        taskManager.createTaskAtLocation(
            location: location, screenWidth: screenWidth, clockState: clockState)
    }

    // MARK: - Task deletion
    func deleteTask(_ task: TaskOnRing) {
        taskManager.deleteTask(task)
    }

    // MARK: - Task editing
    func updateTaskStartTime(_ task: TaskOnRing, newStartTime: Date) {
        taskManager.updateTaskStartTime(task, newStartTime: newStartTime)
    }

    func updateTaskEndTime(_ task: TaskOnRing, newEndTime: Date) {
        taskManager.updateTaskEndTime(task, newEndTime: newEndTime)
    }
}
