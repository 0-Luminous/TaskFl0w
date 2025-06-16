//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine
import CoreData
import WidgetKit

// MARK: - Configuration Structs

/// Настройки циферблата часов
struct ClockSettings {
    let defaultFontName = "SF Pro"
    let defaultDigitalFontSize: Double = 42.0
    let defaultMarkersWidth: Double = 2.0
    let defaultNumbersSize: Double = 16.0
    let defaultNumberInterval: Int = 1
}

/// Настройки маркеров циферблата
struct MarkerSettings {
    let width: Double
    let offset: Double
    let numbersSize: Double
    let numberInterval: Int
    let fontName: String
    let style: MarkerStyle
    let showHourNumbers: Bool
    let showMarkers: Bool
    let showIntermediateMarkers: Bool
}

/// Кастомные цвета темы для ClockViewModel
struct ClockThemeColors {
    let lightModeHandColor: String
    let darkModeHandColor: String
    let lightModeDigitalFontColor: String
    let darkModeDigitalFontColor: String
    let lightModeClockFaceColor: String
    let darkModeClockFaceColor: String
    let lightModeOuterRingColor: String
    let darkModeOuterRingColor: String
    let lightModeMarkersColor: String
    let darkModeMarkersColor: String
}

// MARK: - Protocols

@MainActor
protocol ClockViewModelProtocol: ObservableObject {
    var currentDate: Date { get }
    var selectedDate: Date { get set }
    var tasks: [TaskOnRing] { get }
    var isDarkMode: Bool { get set }
    
    func updateCurrentTimeIfNeeded()
    func startDragging(_ task: TaskOnRing)
    func stopDragging(didReturnToClock: Bool)
}

// MARK: - Main ViewModel

@MainActor
final class ClockViewModel: ObservableObject, ClockViewModelProtocol {
    
    // MARK: - Specialized ViewModels (Декомпозиция)
    
    private let timeManager: TimeManagementViewModel
    private let taskRenderer: TaskRenderingViewModel
    private let userInteraction: UserInteractionViewModel
    private let themeConfig: ThemeConfigurationViewModel
    
    // MARK: - Dependencies
    
    private let settings = ClockSettings()
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    private let notificationService: NotificationServiceProtocol
    let clockState: ClockStateManager
    
    // Child ViewModels (Legacy - для совместимости)
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    let dockBarViewModel: DockBarViewModel
    
    // MARK: - Published Properties (Delegation)
    
    // Time Management (delegated to timeManager)
    var currentDate: Date {
        get { timeManager.currentDate }
    }
    
    var selectedDate: Date {
        get { timeManager.selectedDate }
        set { 
            timeManager.selectedDate = newValue
            taskRenderer.updateTasksForSelectedDate(newValue)
            clockState.selectedDate = newValue
            objectWillChange.send()
        }
    }
    
    var zeroPosition: Double {
        get { timeManager.zeroPosition }
        set { 
            timeManager.zeroPosition = newValue
            objectWillChange.send()
        }
    }
    
    // Task Rendering (delegated to taskRenderer)
    var tasks: [TaskOnRing] {
        get { taskRenderer.tasks }
    }
    
    var overlappingTaskGroups: [[TaskOnRing]] {
        get { taskRenderer.overlappingTaskGroups }
    }
    
    var previewTask: TaskOnRing? {
        get { taskRenderer.previewTask }
        set { 
            taskRenderer.previewTask = newValue
            objectWillChange.send()
        }
    }
    
    var searchText: String {
        get { taskRenderer.searchText }
        set { 
            taskRenderer.searchText = newValue
            objectWillChange.send()
        }
    }
    
    // Modal States (delegated to userInteraction)
    var showingAddTask: Bool {
        get { userInteraction.showingAddTask }
        set { 
            if newValue {
                userInteraction.showAddTask()
            } else {
                userInteraction.hideAddTask()
            }
            objectWillChange.send()
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
            objectWillChange.send()
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
            objectWillChange.send()
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
            objectWillChange.send()
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
            objectWillChange.send()
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
            objectWillChange.send()
        }
    }
    
    var showingTaskDetail: Bool {
        get { userInteraction.showingTaskDetail }
        set {
            if !newValue {
                userInteraction.hideTaskDetail()
            }
            objectWillChange.send()
        }
    }
    
    // Task Management
    var selectedTask: TaskOnRing? {
        get { userInteraction.selectedTask }
        set { 
            userInteraction.selectTask(newValue)
            objectWillChange.send()
        }
    }
    
    var editingTask: TaskOnRing? {
        get { userInteraction.editingTask }
        set { 
            if let task = newValue {
                userInteraction.startEditingTask(task)
            } else {
                userInteraction.finishEditingTask()
            }
            objectWillChange.send()
        }
    }
    
    var draggedTask: TaskOnRing? {
        get { userInteraction.draggedTask }
    }
    
    var draggedCategory: TaskCategoryModel? {
        get { userInteraction.draggedCategory }
        set { 
            if let category = newValue {
                userInteraction.startDraggingCategory(category)
            } else {
                userInteraction.stopDraggingCategory()
            }
            objectWillChange.send()
        }
    }
    
    var selectedCategory: TaskCategoryModel? {
        get { userInteraction.selectedCategory }
        set { 
            userInteraction.selectCategory(newValue)
            objectWillChange.send()
        }
    }
    
    var isEditingMode: Bool {
        get { userInteraction.isEditingMode }
        set { 
            if newValue {
                userInteraction.enableEditMode()
            } else {
                userInteraction.disableEditMode()
            }
            objectWillChange.send()
        }
    }
    
    var isDraggingOutside: Bool {
        get { userInteraction.isDraggingOutside }
    }
    
    var isDraggingStart: Bool {
        get { userInteraction.isDraggingStart }
        set { 
            if newValue {
                if let task = draggedTask {
                    userInteraction.startDraggingTaskStart(task)
                }
            } else {
                // Сбрасываем состояние через stopDragging если оба false
                if !userInteraction.isDraggingEnd {
                    userInteraction.resetDragStates()
                }
            }
            objectWillChange.send()
        }
    }
    
    var isDraggingEnd: Bool {
        get { userInteraction.isDraggingEnd }
        set { 
            if newValue {
                if let task = draggedTask {
                    userInteraction.startDraggingTaskEnd(task)
                }
            } else {
                // Сбрасываем состояние через stopDragging если оба false
                if !userInteraction.isDraggingStart {
                    userInteraction.resetDragStates()
                }
            }
            objectWillChange.send()
        }
    }
    
    var previewTime: Date? {
        get { userInteraction.previewTime }
        set { 
            userInteraction.updatePreviewTime(newValue)
            objectWillChange.send()
        }
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
            objectWillChange.send()
        }
    }
    
    // Clock Configuration
    var clockStyle: String {
        get { themeConfig.clockStyle }
        set { 
            themeConfig.clockStyle = newValue
            objectWillChange.send()
        }
    }
    
    // MARK: - AppStorage Properties
    
    var notificationsEnabled: Bool {
        get { themeConfig.notificationsEnabled }
        set { 
            themeConfig.notificationsEnabled = newValue
            objectWillChange.send()
        }
    }
    
    var showTimeOnlyForActiveTask: Bool {
        get { themeConfig.showTimeOnlyForActiveTask }
        set { 
            themeConfig.showTimeOnlyForActiveTask = newValue
            objectWillChange.send()
        }
    }
    
    var isAnalogArcStyle: Bool {
        get { themeConfig.isAnalogArcStyle }
        set { 
            themeConfig.isAnalogArcStyle = newValue
            objectWillChange.send()
        }
    }
    
    // Colors
    var lightModeHandColor: String {
        get { themeConfig.lightModeHandColor }
        set { 
            themeConfig.lightModeHandColor = newValue
            objectWillChange.send()
        }
    }
    
    var darkModeHandColor: String {
        get { themeConfig.darkModeHandColor }
        set { 
            themeConfig.darkModeHandColor = newValue
            objectWillChange.send()
        }
    }
    
    var lightModeDigitalFontColor: String {
        get { themeConfig.lightModeDigitalFontColor }
        set { 
            themeConfig.lightModeDigitalFontColor = newValue
            objectWillChange.send()
        }
    }
    
    var darkModeDigitalFontColor: String {
        get { themeConfig.darkModeDigitalFontColor }
        set { 
            themeConfig.darkModeDigitalFontColor = newValue
            objectWillChange.send()
        }
    }
    
    var lightModeClockFaceColor: String {
        get { themeConfig.lightModeClockFaceColor }
        set { 
            themeConfig.lightModeClockFaceColor = newValue
            objectWillChange.send()
        }
    }
    
    var darkModeClockFaceColor: String {
        get { themeConfig.darkModeClockFaceColor }
        set { 
            themeConfig.darkModeClockFaceColor = newValue
            objectWillChange.send()
        }
    }
    
    var lightModeOuterRingColor: String {
        get { themeConfig.lightModeOuterRingColor }
        set { 
            themeConfig.lightModeOuterRingColor = newValue
            objectWillChange.send()
        }
    }
    
    var darkModeOuterRingColor: String {
        get { themeConfig.darkModeOuterRingColor }
        set { 
            themeConfig.darkModeOuterRingColor = newValue
            objectWillChange.send()
        }
    }
    
    var lightModeMarkersColor: String {
        get { themeConfig.lightModeMarkersColor }
        set { 
            themeConfig.lightModeMarkersColor = newValue
            objectWillChange.send()
        }
    }
    
    var darkModeMarkersColor: String {
        get { themeConfig.darkModeMarkersColor }
        set { 
            themeConfig.darkModeMarkersColor = newValue
            objectWillChange.send()
        }
    }
    
    // Dimensions
    var taskArcLineWidth: CGFloat {
        get { themeConfig.taskArcLineWidth }
        set { 
            themeConfig.taskArcLineWidth = newValue
            objectWillChange.send()
        }
    }
    
    var outerRingLineWidth: CGFloat {
        get { themeConfig.outerRingLineWidth }
        set { 
            themeConfig.outerRingLineWidth = newValue
            objectWillChange.send()
        }
    }
    
    // Markers
    var showHourNumbers: Bool {
        get { themeConfig.showHourNumbers }
        set { 
            themeConfig.showHourNumbers = newValue
            objectWillChange.send()
        }
    }
    
    var markersWidth: Double {
        get { themeConfig.markersWidth }
        set { 
            themeConfig.markersWidth = newValue
            objectWillChange.send()
        }
    }
    
    var markersOffset: Double {
        get { themeConfig.markersOffset }
        set { 
            themeConfig.markersOffset = newValue
            objectWillChange.send()
        }
    }
    
    var numbersSize: Double {
        get { themeConfig.numbersSize }
        set { 
            themeConfig.numbersSize = newValue
            objectWillChange.send()
        }
    }
    
    var numberInterval: Int {
        get { themeConfig.numberInterval }
        set { 
            themeConfig.numberInterval = newValue
            objectWillChange.send()
        }
    }
    
    var showMarkers: Bool {
        get { themeConfig.showMarkers }
        set { 
            themeConfig.showMarkers = newValue
            objectWillChange.send()
        }
    }
    
    var showIntermediateMarkers: Bool {
        get { themeConfig.showIntermediateMarkers }
        set { 
            themeConfig.showIntermediateMarkers = newValue
            objectWillChange.send()
        }
    }
    
    // Fonts
    var digitalFont: String {
        get { themeConfig.digitalFont }
        set { 
            themeConfig.digitalFont = newValue
            objectWillChange.send()
        }
    }
    
    var fontName: String {
        get { themeConfig.fontName }
        set { 
            themeConfig.fontName = newValue
            objectWillChange.send()
        }
    }
    
    var digitalFontSize: Double {
        get { themeConfig.digitalFontSize }
        set { 
            themeConfig.digitalFontSize = newValue
            objectWillChange.send()
        }
    }
    
    var markerStyle: MarkerStyle {
        get { themeConfig.markerStyle }
        set { 
            themeConfig.markerStyle = newValue
            objectWillChange.send()
        }
    }
    
    // MARK: - Computed Properties
    
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }
    
    var currentThemeColors: ClockThemeColors {
        themeConfig.currentThemeColors
    }
    
    var currentMarkerSettings: MarkerSettings {
        themeConfig.currentMarkerSettings
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentActiveCategory: TaskCategoryModel?
    
    // MARK: - Initialization
    
    init(
        sharedState: SharedStateService? = nil,
        notificationService: NotificationServiceProtocol? = nil
    ) {
        // Инициализируем зависимости
        self.sharedState = sharedState ?? .shared
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
    
    // MARK: - Private Setup Methods
    
    private func setupAsync() async {
        await setupBindings()
        await setupInitialState()
        await setupNotifications()
    }
    
    private func setupBindings() async {
        // Привязываем изменения дочерних ViewModels к основному
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
        
        await bindDockBarUpdates()
        await bindDateChanges()
        await bindThemeChanges()
    }
    
    private func setupInitialState() async {
        await configureMarkersViewModel()
        await syncDockBarState()
    }
    
    private func setupNotifications() async {
        await MainActor.run {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleZeroPositionChange),
                name: .zeroPositionDidChange,
                object: nil
            )
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleClockStyleChange),
                name: NSNotification.Name("ClockStyleDidChange"),
                object: nil
            )
        }
    }
    
    // MARK: - Public Methods (Delegation)
    
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
    
    func updateDragPosition(isOutsideClock: Bool) {
        userInteraction.updateDragPosition(isOutsideClock: isOutsideClock)
    }
    
    func updateZeroPosition(_ newPosition: Double) {
        timeManager.updateZeroPosition(newPosition)
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
    
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        taskRenderer.tasksForSelectedDate(selectedDate, allTasks: allTasks)
    }
    
    func updateUIForThemeChange() {
        themeConfig.updateUIForThemeChange()
        Task {
            await configureMarkersViewModel()
        }
    }
    
    func updateMarkersViewModel() {
        Task {
            await configureMarkersViewModel()
        }
    }
    
    func applyWatchFaceSettings() {
        Task {
            await themeConfig.applyWatchFaceSettings()
            await configureMarkersViewModel()
        }
    }
    
    func startDraggingTaskStart() {
        if let task = editingTask {
            userInteraction.startDraggingTaskStart(task)
            objectWillChange.send()
        }
    }
    
    func startDraggingTaskEnd() {
        if let task = editingTask {
            userInteraction.startDraggingTaskEnd(task)
            objectWillChange.send()
        }
    }
    
    func stopDraggingTaskEdges() {
        userInteraction.resetDragStates()
        objectWillChange.send()
    }
    
    // MARK: - Time Calculation Methods
    
    // MARK: - Private Methods
    
    @objc private func handleZeroPositionChange() {
        let newPosition = ZeroPositionManager.shared.zeroPosition
        timeManager.zeroPosition = newPosition
        markersViewModel.zeroPosition = newPosition
        objectWillChange.send()
    }
    
    @objc private func handleClockStyleChange(_ notification: Notification) {
        guard let newStyle = notification.userInfo?["clockStyle"] as? String,
              clockStyle != newStyle else { return }
        
        clockStyle = newStyle
    }
    
    private func saveZeroPosition() {
        UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
    }
    
    private func saveClockStyle() {
        UserDefaults.standard.set(clockStyle, forKey: "clockStyle")
        objectWillChange.send()
    }
    
    private func updateThemeState() async {
        let currentThemeIsDark = ThemeManager.shared.isDarkMode
        
        if isDarkMode != currentThemeIsDark {
            isDarkMode = currentThemeIsDark
        }
        
        if markersViewModel.isDarkMode != currentThemeIsDark {
            markersViewModel.isDarkMode = currentThemeIsDark
        }
        
        markersViewModel.updateCurrentThemeColors()
        
        objectWillChange.send()
        markersViewModel.objectWillChange.send()
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
        markersViewModel.isDarkMode = themeConfig.isDarkMode
        markersViewModel.zeroPosition = timeManager.zeroPosition
        markersViewModel.numberInterval = settings.numberInterval
        markersViewModel.showMarkers = settings.showMarkers
        markersViewModel.fontName = settings.fontName
        markersViewModel.markerStyle = settings.style
        markersViewModel.showIntermediateMarkers = settings.showIntermediateMarkers
        markersViewModel.digitalFontSize = themeConfig.digitalFontSize
        markersViewModel.lightModeDigitalFontColor = colors.lightModeDigitalFontColor
        markersViewModel.darkModeDigitalFontColor = colors.darkModeDigitalFontColor
        
        // Принудительно обновляем UI
        await MainActor.run {
            let tempValue = markersViewModel.markersWidth
            markersViewModel.markersWidth = tempValue + 0.01
            
            Task {
                await MainActor.run {
                    markersViewModel.markersWidth = tempValue
                }
            }
        }
    }
    
    private func syncDockBarState() async {
        dockBarViewModel.selectedCategory = selectedCategory
        dockBarViewModel.draggedCategory = draggedCategory
        dockBarViewModel.showingAddTask = showingAddTask
        dockBarViewModel.showingCategoryEditor = showingCategoryEditor
    }
    
    private func bindDockBarUpdates() async {
        dockBarViewModel.$selectedCategory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCategory in
                guard let self = self else { return }
                self.userInteraction.selectCategory(newCategory)
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$draggedCategory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCategory in
                guard let self = self else { return }
                if let category = newCategory {
                    self.userInteraction.startDraggingCategory(category)
                } else {
                    self.userInteraction.stopDraggingCategory()
                }
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
    
    private func handleTasksUpdate(_ newTasks: [TaskOnRing]) {
        Task {
            await updateEditingTaskIfNeeded(newTasks: newTasks)
            await validateTaskOverlaps(newTasks)
            await notifyTaskArcsComponents(newTasks: newTasks)
            await updateCategoryStates(newTasks)
        }
    }
    
    private func updateEditingTaskIfNeeded(newTasks: [TaskOnRing]) async {
        guard let editingTask = editingTask else { return }
        
        if let updatedTask = newTasks.first(where: { $0.id == editingTask.id }) {
            guard !tasksAreEqual(editingTask, updatedTask) else { return }
            self.editingTask = updatedTask
        } else {
            // Edited task was deleted
            self.editingTask = nil
            self.isEditingMode = false
        }
    }
    
    private func validateTaskOverlaps(_ newTasks: [TaskOnRing]) async {
        taskRenderer.validateTaskOverlaps()
    }
    
    private func notifyTaskArcsComponents(newTasks: [TaskOnRing]) async {
        // This could be enhanced with specific change detection
        NotificationCenter.default.post(
            name: .taskArcsTasksModified,
            object: self,
            userInfo: ["modifiedTasks": newTasks]
        )
    }
    
    private func updateCategoryStates(_ newTasks: [TaskOnRing]) async {
        await checkForCategoryChange()
        updateCategoryStatistics(newTasks)
    }
    
    private func checkForCategoryChange() async {
        guard notificationsEnabled else { return }
        
        let todayTasks = tasksForSelectedDate(tasks)
        let now = Date()
        
        let activeTask = todayTasks.first { task in
            task.startTime <= now && task.endTime > now
        }
        
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
    
    private func updateTasksForSelectedDate() {
        taskRenderer.updateTasksForSelectedDate(timeManager.selectedDate)
        objectWillChange.send()
    }
    
    private func updateCategoryStatistics(_ tasks: [TaskOnRing]) {
        let categoryTaskCounts = Dictionary(grouping: tasks) { $0.category }
            .mapValues { $0.count }
        
        NotificationCenter.default.post(
            name: .categoryStatisticsUpdated,
            object: self,
            userInfo: ["categoryTaskCounts": categoryTaskCounts]
        )
    }
    
    private func refreshAllSettings() async {
        await configureMarkersViewModel()
        
        let themeManager = ThemeManager.shared
        let colors = currentThemeColors
        
        // Update ThemeManager colors
        await updateThemeManagerColors(themeManager, colors: colors)
        
        await MainActor.run {
            themeManager.objectWillChange.send()
            self.objectWillChange.send()
            self.markersViewModel.objectWillChange.send()
        }
    }
    
    private func updateThemeManagerColors(_ themeManager: ThemeManager, colors: ClockThemeColors) async {
        guard let lightFaceColor = Color(hex: colors.lightModeClockFaceColor),
              let darkFaceColor = Color(hex: colors.darkModeClockFaceColor),
              let lightRingColor = Color(hex: colors.lightModeOuterRingColor),
              let darkRingColor = Color(hex: colors.darkModeOuterRingColor),
              let lightMarkersColor = Color(hex: colors.lightModeMarkersColor),
              let darkMarkersColor = Color(hex: colors.darkModeMarkersColor) else { return }
        
        themeManager.updateColor(lightFaceColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
        themeManager.updateColor(darkFaceColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
        themeManager.updateColor(lightRingColor, for: ThemeManager.Constants.lightModeOuterRingColorKey)
        themeManager.updateColor(darkRingColor, for: ThemeManager.Constants.darkModeOuterRingColorKey)
        themeManager.updateColor(lightMarkersColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
        themeManager.updateColor(darkMarkersColor, for: ThemeManager.Constants.darkModeMarkersColorKey)
    }
    
    // MARK: - Helper Methods
    
    private func findOverlappingTaskGroups(_ tasks: [TaskOnRing]) -> [[TaskOnRing]] {
        var overlappingGroups: [[TaskOnRing]] = []
        var processedTasks: Set<UUID> = []
        
        for task in tasks.sorted(by: { $0.startTime < $1.startTime }) {
            guard !processedTasks.contains(task.id) else { continue }
            
            var currentGroup: [TaskOnRing] = [task]
            processedTasks.insert(task.id)
            
            // Find all tasks that overlap with current task
            for otherTask in tasks where !processedTasks.contains(otherTask.id) {
                if tasksOverlap(task, otherTask) {
                    currentGroup.append(otherTask)
                    processedTasks.insert(otherTask.id)
                }
            }
            
            // Add group only if it contains more than one task
            if currentGroup.count > 1 {
                overlappingGroups.append(currentGroup)
            }
        }
        
        return overlappingGroups
    }
    
    private func tasksOverlap(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        task1.startTime < task2.endTime && task1.endTime > task2.startTime
    }
    
    private func tasksAreEqual(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        task1.id == task2.id &&
        task1.startTime == task2.startTime &&
        task1.endTime == task2.endTime &&
        task1.category == task2.category &&
        task1.isCompleted == task2.isCompleted
    }
}

// MARK: - Formatted Date Computed Properties

extension ClockViewModel {
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

// MARK: - TaskArcs Notification Extensions

extension Notification.Name {
    static let taskArcsTasksAdded = Notification.Name("TaskArcsTasksAdded")
    static let taskArcsTasksRemoved = Notification.Name("TaskArcsTasksRemoved") 
    static let taskArcsTasksModified = Notification.Name("TaskArcsTasksModified")
    static let categoryStatisticsUpdated = Notification.Name("CategoryStatisticsUpdated")
}

// MARK: - Theme Configuration

extension ClockViewModel {
    var isDarkMode: Bool {
        get { themeConfig.isDarkMode }
        set { 
            themeConfig.setTheme(newValue)
            objectWillChange.send()
        }
    }
}
