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
    
    // MARK: - Specialized ViewModels (Modern Architecture)
    let timeManager: TimeManagementViewModel
    let taskRenderer: TaskRenderingViewModel
    let userInteraction: UserInteractionViewModel
    let themeConfig: ThemeConfigurationViewModel
    
    // MARK: - Dependencies
    private let settings = ClockSettings()
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    private let notificationService: NotificationServiceProtocol
    let clockState: ClockStateManager
    
    // Legacy ViewModels (для совместимости с существующим UI)
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    let dockBarViewModel: DockBarViewModel
    
    // MARK: - Essential Properties (только самые необходимые для UI)
    
    // Time Management - прямое делегирование
    var currentDate: Date { timeManager.currentDate }
    var selectedDate: Date {
        get { timeManager.selectedDate }
        set { 
            timeManager.selectedDate = newValue
            taskRenderer.updateTasksForSelectedDate(newValue)
            clockState.selectedDate = newValue
            objectWillChange.send()
        }
    }
    
    // Task Management - прямое делегирование
    var tasks: [TaskOnRing] { taskRenderer.tasks }
    var overlappingTaskGroups: [[TaskOnRing]] { taskRenderer.overlappingTaskGroups }
    
    // Theme - прямое делегирование
    var isDarkMode: Bool {
        get { themeConfig.isDarkMode }
        set { 
            themeConfig.setTheme(newValue)
            objectWillChange.send()
        }
    }
    
    // Categories
    var categories: [TaskCategoryModel] { categoryManagement.categories }
    
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
    
    // MARK: - Public Methods (Essential Coordinator Functions)
    
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
                name: NSNotification.Name("ZeroPositionDidChange"),
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
    
    // MARK: - Private Methods
    
    @objc private func handleZeroPositionChange() {
        let newPosition = ZeroPositionManager.shared.zeroPosition
        timeManager.zeroPosition = newPosition
        markersViewModel.zeroPosition = newPosition
        objectWillChange.send()
    }
    
    @objc private func handleClockStyleChange(_ notification: Notification) {
        guard let newStyle = notification.userInfo?["clockStyle"] as? String,
              themeConfig.clockStyle != newStyle else { return }
        
        themeConfig.clockStyle = newStyle
    }
    
    private func configureMarkersViewModel() async {
        let settings = themeConfig.currentMarkerSettings
        let colors = themeConfig.currentThemeColors
        
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
        dockBarViewModel.selectedCategory = userInteraction.selectedCategory
        dockBarViewModel.draggedCategory = userInteraction.draggedCategory
        dockBarViewModel.showingAddTask = userInteraction.showingAddTask
        dockBarViewModel.showingCategoryEditor = userInteraction.showingCategoryEditor
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
    
    private func checkForCategoryChange() async {
        guard themeConfig.notificationsEnabled else { return }
        
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
