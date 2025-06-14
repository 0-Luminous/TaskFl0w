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
    
    // MARK: - Dependencies
    
    private let settings = ClockSettings()
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    private let notificationService: NotificationServiceProtocol
    let clockState: ClockStateManager
    
    // Child ViewModels
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    let dockBarViewModel: DockBarViewModel
    
    // MARK: - Published Properties
    
    // UI State
    @Published var currentDate = Date()
    @Published var selectedDate = Date()
    @Published var searchText = ""
    @Published var isDarkMode = false
    
    // Modal States
    @Published var showingAddTask = false
    @Published var showingSettings = false
    @Published var showingCalendar = false
    @Published var showingStatistics = false
    @Published var showingTodayTasks = false
    @Published var showingCategoryEditor = false
    @Published var showingTaskDetail = false
    
    // Task Management
    @Published var tasks: [TaskOnRing] = []
    @Published var previewTask: TaskOnRing?
    @Published var selectedTask: TaskOnRing?
    @Published var editingTask: TaskOnRing?
    @Published var overlappingTaskGroups: [[TaskOnRing]] = []
    
    // Drag & Drop
    @Published var draggedTask: TaskOnRing?
    @Published var draggedCategory: TaskCategoryModel?
    @Published var selectedCategory: TaskCategoryModel?
    @Published var isDraggingOutside = false
    @Published var isDraggingStart = false
    @Published var isDraggingEnd = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    
    // Edit Mode
    @Published var isEditingMode = false
    @Published var isDockBarEditingEnabled = false
    
    // Clock Configuration
    @Published var zeroPosition: Double = 0 {
        didSet { saveZeroPosition() }
    }
    @Published var clockStyle = "Классический" {
        didSet { saveClockStyle() }
    }
    
    // MARK: - AppStorage Properties
    
    @AppStorage("notificationsEnabled") 
    private var notificationsEnabled = true
    
    @AppStorage("showTimeOnlyForActiveTask") 
    var showTimeOnlyForActiveTask = false
    
    @AppStorage("isAnalogArcStyle") 
    var isAnalogArcStyle = false
    
    // Colors
    @AppStorage("lightModeHandColor") 
    var lightModeHandColor = Color.blue.toHex()
    
    @AppStorage("darkModeHandColor") 
    var darkModeHandColor = Color.blue.toHex()
    
    @AppStorage("lightModeDigitalFontColor") 
    var lightModeDigitalFontColor = Color.gray.toHex()
    
    @AppStorage("darkModeDigitalFontColor") 
    var darkModeDigitalFontColor = Color.white.toHex()
    
    @AppStorage("lightModeClockFaceColor") 
    var lightModeClockFaceColor = Color.white.toHex()
    
    @AppStorage("darkModeClockFaceColor") 
    var darkModeClockFaceColor = Color.black.toHex()
    
    @AppStorage("lightModeOuterRingColor") 
    var lightModeOuterRingColor = Color.gray.opacity(0.3).toHex()
    
    @AppStorage("darkModeOuterRingColor") 
    var darkModeOuterRingColor = Color.gray.opacity(0.3).toHex()
    
    @AppStorage("lightModeMarkersColor") 
    var lightModeMarkersColor = Color.gray.toHex()
        
    @AppStorage("darkModeMarkersColor") 
    var darkModeMarkersColor = Color.gray.toHex()
    
    // Dimensions
    @AppStorage("taskArcLineWidth") 
    private var taskArcLineWidthRaw: Double = 20
    
    @AppStorage("outerRingLineWidth") 
    private var outerRingLineWidthRaw: Double = 20
    
    // Markers
    @AppStorage("showHourNumbers") 
    var showHourNumbers = true
    
    @AppStorage("markersWidth") 
    var markersWidth: Double = 2.0
    
    @AppStorage("markersOffset") 
    var markersOffset: Double = 0.0
    
    @AppStorage("numbersSize") 
    var numbersSize: Double = 16.0
    
    @AppStorage("numberInterval") 
    var numberInterval = 1
    
    @AppStorage("showMarkers") 
    var showMarkers = true
    
    @AppStorage("showIntermediateMarkers") 
    var showIntermediateMarkers = true
    
    // Fonts
    @AppStorage("digitalFont") 
    var digitalFont = "SF Pro"
    
    @AppStorage("fontName") 
    var fontName = "SF Pro"
    
    @AppStorage("digitalFontSize") 
    var digitalFontSizeRaw: Double = 42.0
    
    @AppStorage("markerStyle") 
    private var markerStyleRaw = MarkerStyle.lines.rawValue
    
    // MARK: - Computed Properties
    
    var taskArcLineWidth: CGFloat {
        get { CGFloat(taskArcLineWidthRaw) }
        set { taskArcLineWidthRaw = Double(newValue) }
    }
    
    var outerRingLineWidth: CGFloat {
        get { CGFloat(outerRingLineWidthRaw) }
        set { outerRingLineWidthRaw = Double(newValue) }
    }
    
    var markerStyle: MarkerStyle {
        get { MarkerStyle(rawValue: markerStyleRaw) ?? .lines }
        set { markerStyleRaw = newValue.rawValue }
    }
    
    var digitalFontSize: Double {
        get { digitalFontSizeRaw }
        set { digitalFontSizeRaw = newValue }
    }
    
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }
    
    var currentThemeColors: ClockThemeColors {
        ClockThemeColors(
            lightModeHandColor: lightModeHandColor,
            darkModeHandColor: darkModeHandColor,
            lightModeDigitalFontColor: lightModeDigitalFontColor,
            darkModeDigitalFontColor: darkModeDigitalFontColor,
            lightModeClockFaceColor: lightModeClockFaceColor,
            darkModeClockFaceColor: darkModeClockFaceColor,
            lightModeOuterRingColor: lightModeOuterRingColor,
            darkModeOuterRingColor: darkModeOuterRingColor,
            lightModeMarkersColor: lightModeMarkersColor,
            darkModeMarkersColor: darkModeMarkersColor
        )
    }
    
    var currentMarkerSettings: MarkerSettings {
        MarkerSettings(
            width: markersWidth,
            offset: markersOffset,
            numbersSize: numbersSize,
            numberInterval: numberInterval,
            fontName: fontName,
            style: markerStyle,
            showHourNumbers: showHourNumbers,
            showMarkers: showMarkers,
            showIntermediateMarkers: showIntermediateMarkers
        )
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var currentActiveCategory: TaskCategoryModel?
    
    // MARK: - Initialization
    
    init(
        sharedState: SharedStateService = .shared,
        notificationService: NotificationServiceProtocol = NotificationService.shared
    ) {
        self.sharedState = sharedState
        self.notificationService = notificationService
        self.clockState = ClockStateManager()
        
        // Load saved settings
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
        self.isDarkMode = ThemeManager.shared.isDarkMode
        self.clockStyle = UserDefaults.standard.string(forKey: "clockStyle") ?? "Классический"
        
        let initialDate = Date()
        self.selectedDate = initialDate
        
        // Initialize services with dependency injection
        let taskManagement = TaskManagement(sharedState: sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement
        
        let categoryManager = CategoryManagement(context: sharedState.context, sharedState: sharedState)
        self.categoryManagement = categoryManager
        
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        self.dockBarViewModel = DockBarViewModel(categoryManagement: categoryManager)
        
        self.tasks = sharedState.tasks
        
        Task {
            await setupAsync()
        }
    }
    
    deinit {
        // Метод deinit не может быть @MainActor
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup Methods
    
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
        await bindDockBarUpdates()
        await bindTaskUpdates()
        await bindDateChanges()
        await bindThemeChanges()
    }
    
    private func setupNotifications() async {
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
    
    // MARK: - Public Methods
    
    func updateCurrentTimeIfNeeded() {
        guard Calendar.current.isDate(selectedDate, inSameDayAs: Date()) else { return }
        
        currentDate = Date()
        Task {
            await checkForCategoryChange()
        }
    }
    
    func startDragging(_ task: TaskOnRing) {
        draggedTask = task
        dragAndDropManager.startDragging(task)
    }
    
    func stopDragging(didReturnToClock: Bool) {
        dragAndDropManager.stopDragging(didReturnToClock: didReturnToClock)
        draggedTask = nil
        isDraggingOutside = false
    }
    
    func updateDragPosition(isOutsideClock: Bool) {
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }
    
    func updateZeroPosition(_ newPosition: Double) {
        ZeroPositionManager.shared.updateZeroPosition(newPosition)
        zeroPosition = newPosition
    }
    
    // Добавляем недостающие методы для совместимости с UI
    func updateUIForThemeChange() {
        Task {
            await updateThemeState()
        }
    }
    
    func updateMarkersViewModel() {
        Task {
            await configureMarkersViewModel()
        }
    }
    
    // MARK: - Time Calculation Methods
    
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        RingTimeCalculator.getTimeWithZeroOffset(
            date, 
            baseDate: selectedDate, 
            zeroPosition: zeroPosition, 
            inverse: inverse
        )
    }
    
    func angleToTime(_ angle: Double) -> Date {
        RingTimeCalculator.angleToTime(angle, baseDate: selectedDate, zeroPosition: zeroPosition)
    }
    
    func timeToAngle(_ date: Date) -> Double {
        RingTimeCalculator.timeToAngle(date, zeroPosition: zeroPosition)
    }
    
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: clockState.selectedDate)
        }
    }
    
    func applyWatchFaceSettings() {
        Task {
            await refreshAllSettings()
        }
    }
    
    // MARK: - Private Methods
    
    @objc private func handleZeroPositionChange() {
        let newPosition = ZeroPositionManager.shared.zeroPosition
        zeroPosition = newPosition
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
        
        await MainActor.run {
            objectWillChange.send()
            markersViewModel.objectWillChange.send()
        }
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
        markersViewModel.markerStyle = settings.style
        markersViewModel.showIntermediateMarkers = settings.showIntermediateMarkers
        markersViewModel.digitalFontSize = digitalFontSize
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
                guard let self = self,
                      self.selectedCategory != newCategory else { return }
                self.selectedCategory = newCategory
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$draggedCategory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCategory in
                guard let self = self,
                      self.draggedCategory != newCategory else { return }
                self.draggedCategory = newCategory
            }
            .store(in: &cancellables)
    }
    
    private func bindTaskUpdates() async {
        sharedState.subscribeToTasksUpdates { [weak self] in
            guard let self = self else { return }
            self.tasks = self.sharedState.tasks
        }
        
        $tasks
            .removeDuplicates { oldTasks, newTasks in
                oldTasks.count == newTasks.count && 
                zip(oldTasks, newTasks).allSatisfy { $0.id == $1.id }
            }
            .sink { [weak self] newTasks in
                self?.handleTasksUpdate(newTasks)
            }
            .store(in: &cancellables)
    }
    
    private func bindDateChanges() async {
        $selectedDate
            .removeDuplicates()
            .sink { [weak self] newDate in
                guard let self = self else { return }
                (self.taskManagement as? TaskManagement)?.selectedDate = newDate
                self.updateTasksForSelectedDate()
                self.clockState.selectedDate = newDate
            }
            .store(in: &cancellables)
    }
    
    private func bindThemeChanges() async {
        $isDarkMode
            .removeDuplicates()
            .sink { [weak self] isDark in
                guard let self = self,
                      isDark != ThemeManager.shared.isDarkMode else { return }
                
                UserDefaults.standard.set(isDark, forKey: "isDarkMode")
                ThemeManager.shared.setTheme(isDark)
                self.markersViewModel.isDarkMode = isDark
                self.markersViewModel.updateCurrentThemeColors()
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
        let todayTasks = newTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        overlappingTaskGroups = findOverlappingTaskGroups(todayTasks)
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
        let allTasks = sharedState.tasks
        
        let tasksOnSelectedDate = allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        let incompleteTasksFromPreviousDays = allTasks.filter { task in
            !task.isCompleted && 
            Calendar.current.compare(task.startTime, to: selectedDate, toGranularity: .day) == .orderedAscending
        }
        
        tasks = tasksOnSelectedDate + incompleteTasksFromPreviousDays
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
