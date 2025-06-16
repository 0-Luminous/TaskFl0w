//
//  ClockViewModelRefactored.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Combine
import CoreData
import WidgetKit

// MARK: - Main Coordinator ViewModel

@MainActor
final class ClockViewModelRefactored: ObservableObject, ClockViewModelProtocol {
    
    // MARK: - Child ViewModels (Specialized Components)
    
    private let timeManager: TimeManagementViewModel
    private let taskRenderer: TaskRenderingViewModel
    private let userInteraction: UserInteractionViewModel
    private let themeConfig: ThemeConfigurationViewModel
    
    // MARK: - Dependencies
    
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    private let notificationService: NotificationServiceProtocol
    let clockState: ClockStateManager
    
    // Legacy Child ViewModels (сохраняем для совместимости)
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    let dockBarViewModel: DockBarViewModel
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentActiveCategory: TaskCategoryModel?
    
    // MARK: - Initialization
    
    init(
        sharedState: SharedStateService? = nil,
        notificationService: NotificationServiceProtocol? = nil
    ) {
        // Инициализируем зависимости
        self.sharedState = sharedState ?? SharedStateService()
        self.notificationService = notificationService ?? NotificationService.shared
        self.clockState = ClockStateManager()
        
        let initialDate = Date()
        
        // Initialize services with dependency injection
        let taskManagement = TaskManagement(sharedState: self.sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement
        
        let categoryManager = CategoryManagement(context: self.sharedState.context, sharedState: self.sharedState)
        self.categoryManagement = categoryManager
        
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        self.dockBarViewModel = DockBarViewModel(categoryManagement: categoryManager)
        
        // Инициализируем специализированные ViewModels
        self.timeManager = TimeManagementViewModel(initialDate: initialDate)
        self.taskRenderer = TaskRenderingViewModel(sharedState: self.sharedState)
        self.userInteraction = UserInteractionViewModel(taskManagement: taskManagement)
        self.themeConfig = ThemeConfigurationViewModel()
        
        Task {
            await setupAsync()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - ClockViewModelProtocol Implementation (Delegation)
    
    var currentDate: Date {
        get { timeManager.currentDate }
    }
    
    var selectedDate: Date {
        get { timeManager.selectedDate }
        set { 
            timeManager.selectedDate = newValue
            taskRenderer.updateTasksForSelectedDate(newValue)
            clockState.selectedDate = newValue
        }
    }
    
    var tasks: [TaskOnRing] {
        get { taskRenderer.tasks }
    }
    
    var isDarkMode: Bool {
        get { themeConfig.isDarkMode }
        set { themeConfig.setTheme(newValue) }
    }
    
    func updateCurrentTimeIfNeeded() {
        timeManager.updateCurrentTimeIfNeeded()
        Task {
            await checkForCategoryChange()
        }
    }
    
    func startDragging(_ task: TaskOnRing) {
        userInteraction.startDragging(task)
    }
    
    func stopDragging(didReturnToClock: Bool) {
        userInteraction.stopDragging(didReturnToClock: didReturnToClock)
    }
    
    // MARK: - Public Interface (Delegation to Child ViewModels)
    
    // Time Management
    var zeroPosition: Double {
        get { timeManager.zeroPosition }
        set { timeManager.zeroPosition = newValue }
    }
    
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        timeManager.getTimeWithZeroOffset(date, inverse: inverse)
    }
    
    func angleToTime(_ angle: Double) -> Date {
        timeManager.angleToTime(angle)
    }
    
    func timeToAngle(_ date: Date) -> Double {
        timeManager.timeToAngle(date)
    }
    
    func updateZeroPosition(_ newPosition: Double) {
        timeManager.updateZeroPosition(newPosition)
    }
    
    // Task Rendering
    var overlappingTaskGroups: [[TaskOnRing]] {
        get { taskRenderer.overlappingTaskGroups }
    }
    
    var previewTask: TaskOnRing? {
        get { taskRenderer.previewTask }
        set { taskRenderer.previewTask = newValue }
    }
    
    var searchText: String {
        get { taskRenderer.searchText }
        set { taskRenderer.searchText = newValue }
    }
    
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        taskRenderer.tasksForSelectedDate(selectedDate, allTasks: allTasks)
    }
    
    func filteredTasks() -> [TaskOnRing] {
        taskRenderer.filteredTasks()
    }
    
    func getCurrentActiveTask() -> TaskOnRing? {
        taskRenderer.getCurrentActiveTask()
    }
    
    // User Interaction
    var selectedTask: TaskOnRing? {
        get { userInteraction.selectedTask }
        set { userInteraction.selectTask(newValue) }
    }
    
    var editingTask: TaskOnRing? {
        get { userInteraction.editingTask }
        set { 
            if let task = newValue {
                userInteraction.startEditingTask(task)
            } else {
                userInteraction.finishEditingTask()
            }
        }
    }
    
    var draggedTask: TaskOnRing? {
        get { userInteraction.draggedTask }
    }
    
    var draggedCategory: TaskCategoryModel? {
        get { userInteraction.draggedCategory }
    }
    
    var selectedCategory: TaskCategoryModel? {
        get { userInteraction.selectedCategory }
        set { userInteraction.selectCategory(newValue) }
    }
    
    var isEditingMode: Bool {
        get { userInteraction.isEditingMode }
        set { 
            if newValue {
                userInteraction.enableEditMode()
            } else {
                userInteraction.disableEditMode()
            }
        }
    }
    
    var isDraggingOutside: Bool {
        get { userInteraction.isDraggingOutside }
    }
    
    var isDraggingStart: Bool {
        get { userInteraction.isDraggingStart }
    }
    
    var isDraggingEnd: Bool {
        get { userInteraction.isDraggingEnd }
    }
    
    var previewTime: Date? {
        get { userInteraction.previewTime }
        set { userInteraction.updatePreviewTime(newValue) }
    }
    
    var dropLocation: CGPoint? {
        get { userInteraction.dropLocation }
    }
   
    var isDockBarEditingEnabled: Bool {
        get { userInteraction.isDockBarEditingEnabled }
        set {
            if newValue {
                userInteraction.enableDockBarEditing()
            } else {
                userInteraction.disableDockBarEditing()
            }
        }
    }
    
    // Modal States
    var showingAddTask: Bool {
        get { userInteraction.showingAddTask }
        set { 
            if newValue {
                userInteraction.showAddTask()
            } else {
                userInteraction.hideAddTask()
            }
        }
    }
    
    var showingSettings: Bool {
        get { userInteraction.showingSettings }
        set {
            if newValue {
                userInteraction.showSettings()
            } else {
                userInteraction.hideSettings()
            }
        }
    }
    
    var showingCalendar: Bool {
        get { userInteraction.showingCalendar }
        set {
            if newValue {
                userInteraction.showCalendar()
            } else {
                userInteraction.hideCalendar()
            }
        }
    }
    
    var showingStatistics: Bool {
        get { userInteraction.showingStatistics }
        set {
            if newValue {
                userInteraction.showStatistics()
            } else {
                userInteraction.hideStatistics()
            }
        }
    }
    
    var showingTodayTasks: Bool {
        get { userInteraction.showingTodayTasks }
        set {
            if newValue {
                userInteraction.showTodayTasksList()
            } else {
                userInteraction.hideTodayTasksList()
            }
        }
    }
    
    var showingCategoryEditor: Bool {
        get { userInteraction.showingCategoryEditor }
        set {
            if newValue {
                userInteraction.showCategoryEditor()
            } else {
                userInteraction.hideCategoryEditor()
            }
        }
    }
    
    var showingTaskDetail: Bool {
        get { userInteraction.showingTaskDetail }
        set {
            if !newValue {
                userInteraction.hideTaskDetail()
            }
        }
    }
    
    // Theme Configuration
    var clockStyle: String {
        get { themeConfig.clockStyle }
        set { themeConfig.clockStyle = newValue }
    }
    
    var currentThemeColors: ClockThemeColors {
        themeConfig.currentThemeColors
    }
    
    var currentMarkerSettings: MarkerSettings {
        themeConfig.currentMarkerSettings
    }
    
    // Computed Properties для совместимости
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }
    
    // MARK: - Public Methods
    
    func updateDragPosition(isOutsideClock: Bool) {
        userInteraction.updateDragPosition(isOutsideClock: isOutsideClock)
    }
    
    func updateUIForThemeChange() {
        themeConfig.updateUIForThemeChange()
        Task {
            await updateMarkersViewModel()
        }
    }
    
    func updateMarkersViewModel() async {
        await configureMarkersViewModel()
    }
    
    func applyWatchFaceSettings() {
        Task {
            await themeConfig.applyWatchFaceSettings()
            await configureMarkersViewModel()
        }
    }
    
    // MARK: - Private Setup Methods
    
    private func setupAsync() async {
        await setupInitialState()
        await setupBindings()
        await setupNotifications()
    }
    
    private func setupInitialState() async {
        await configureMarkersViewModel()
        await syncDockBarState()
    }
    
    private func setupBindings() async {
        await bindChildViewModels()
        await bindDockBarUpdates()
        await bindDateChanges()
        await bindThemeChanges()
    }
    
    private func bindChildViewModels() async {
        // Привязка изменений в дочерних ViewModels к основному
        timeManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        taskRenderer.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        userInteraction.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        themeConfig.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func bindDateChanges() async {
        timeManager.$selectedDate
            .removeDuplicates()
            .sink { [weak self] newDate in
                guard let self = self else { return }
                (self.taskManagement as? TaskManagement)?.selectedDate = newDate
                self.taskRenderer.updateTasksForSelectedDate(newDate)
            }
            .store(in: &cancellables)
    }
    
    private func bindThemeChanges() async {
        themeConfig.$isDarkMode
            .removeDuplicates()
            .sink { [weak self] isDark in
                guard let self = self else { return }
                self.markersViewModel.isDarkMode = isDark
                Task {
                    await self.configureMarkersViewModel()
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindDockBarUpdates() async {
        dockBarViewModel.$selectedCategory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCategory in
                self?.userInteraction.selectCategory(newCategory)
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$draggedCategory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCategory in
                if let category = newCategory {
                    self?.userInteraction.startDraggingCategory(category)
                } else {
                    self?.userInteraction.stopDraggingCategory()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() async {
        await MainActor.run {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClockStyleChange),
                name: NSNotification.Name("ClockStyleDidChange"),
                object: nil
            )
        }
    }
    
    @objc private func handleClockStyleChange(_ notification: Notification) {
        guard let newStyle = notification.userInfo?["clockStyle"] as? String,
              clockStyle != newStyle else { return }
        
        clockStyle = newStyle
    }
    
    private func configureMarkersViewModel() async {
        let settings = currentMarkerSettings
        let colors = currentThemeColors
        
        markersViewModel.showHourNumbers = settings.showHourNumbers
        markersViewModel.markersWidth = settings.width
        markersViewModel.markersOffset = settings.offset
        markersViewModel.numbersSize = settings.numbersSize
        markersViewModel.lightModeMarkersColor = colors.lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = colors.darkModeMarkersColor
        markersViewModel.isDarkMode = isDarkMode
        markersViewModel.zeroPosition = zeroPosition
        markersViewModel.numberInterval = settings.numberInterval
        markersViewModel.showMarkers = settings.showMarkers
        markersViewModel.fontName = settings.fontName
        markersViewModel.showIntermediateMarkers = settings.showIntermediateMarkers
        markersViewModel.lightModeDigitalFontColor = colors.lightModeDigitalFontColor
        markersViewModel.darkModeDigitalFontColor = colors.darkModeDigitalFontColor
    }
    
    private func syncDockBarState() async {
        dockBarViewModel.selectedCategory = selectedCategory
        dockBarViewModel.draggedCategory = draggedCategory
        dockBarViewModel.showingAddTask = showingAddTask
        dockBarViewModel.showingCategoryEditor = showingCategoryEditor
    }
    
    private func checkForCategoryChange() async {
        guard themeConfig.notificationsEnabled else { return }
        
        let activeTask = getCurrentActiveTask()
        let newActiveCategory = activeTask?.category
        
        if let newCategory = newActiveCategory, 
           newCategory != currentActiveCategory {
            currentActiveCategory = newCategory
            
            do {
                try await notificationService.sendCategoryStartNotification(category: newCategory)
            } catch {
                print("⚠️ Failed to send category notification: \(error.localizedDescription)")
            }
        } else if newActiveCategory == nil && currentActiveCategory != nil {
            currentActiveCategory = nil
        }
    }
}

// MARK: - Formatted Date Computed Properties

extension ClockViewModelRefactored {
    var formattedDate: String {
        switch Locale.current.language.languageCode?.identifier {
        case "ru": return selectedDate.formattedForClockDate()
        case "zh": return selectedDate.formattedForClockDateZh()
        case "es": return selectedDate.formattedForClockDateEs()
        case "ja": return selectedDate.formattedForClockDateJa()
        case "fr": return selectedDate.formattedForClockDateFr()
        default: return selectedDate.formattedForClockDateEn()
        }
    }
    
    var formattedWeekday: String {
        switch Locale.current.language.languageCode?.identifier {
        case "ru": return selectedDate.formattedWeekday()
        case "zh": return selectedDate.formattedWeekdayZh()
        case "es": return selectedDate.formattedWeekdayEs()
        case "ja": return selectedDate.formattedWeekdayJa()
        case "fr": return selectedDate.formattedWeekdayFr()
        default: return selectedDate.formattedWeekdayEn()
        }
    }
} 
