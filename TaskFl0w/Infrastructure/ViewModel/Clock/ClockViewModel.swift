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

final class ClockViewModel: ObservableObject {
    // MARK: - Constants
    private enum Constants {
        static let defaultFontName = "SF Pro"
        static let defaultDigitalFontSize: Double = 42.0
        static let defaultMarkersWidth: Double = 2.0
        static let defaultNumbersSize: Double = 16.0
        static let defaultNumberInterval: Int = 1
    }
    
    // MARK: - Services
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    let dockBarViewModel: DockBarViewModel
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    let clockState: ClockStateManager
    private let notificationService: NotificationServiceProtocol = NotificationService.shared

    // MARK: - View State Properties
    @Published var previewTask: TaskOnRing?
    @Published var currentDate: Date = Date()
    @Published var isDockBarEditingEnabled: Bool = false
    @Published var draggedTask: TaskOnRing?
    @Published var isDraggingOutside: Bool = false
    @Published var showingAddTask: Bool = false
    @Published var showingSettings: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var showingTodayTasks: Bool = false
    @Published var showingCategoryEditor: Bool = false
    @Published var isEditingMode: Bool = false
    @Published var editingTask: TaskOnRing?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTask: TaskOnRing?
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""
    @Published var zeroPosition: Double {
        didSet {
            UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
        }
    }
    @Published var draggedCategory: TaskCategoryModel? {
        didSet {
            print("🔥 DEBUG: ClockViewModel.draggedCategory changed from \(oldValue?.rawValue ?? "nil") to \(draggedCategory?.rawValue ?? "nil")")
            dockBarViewModel.draggedCategory = draggedCategory
        }
    }
    @Published var selectedCategory: TaskCategoryModel? {
        didSet {
            dockBarViewModel.selectedCategory = selectedCategory
        }
    }
    @Published var isDarkMode: Bool = false {
        didSet {
            if isDarkMode != ThemeManager.shared.isDarkMode {
                UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
                ThemeManager.shared.setTheme(isDarkMode)
                markersViewModel.isDarkMode = isDarkMode
                markersViewModel.updateCurrentThemeColors()
            }
        }
    }
    @Published var selectedDate: Date = Date() {
        didSet {
            (taskManagement as? TaskManagement)?.selectedDate = selectedDate
            updateTasksForSelectedDate()
            clockState.selectedDate = selectedDate
        }
    }
    @Published var clockStyle: String = UserDefaults.standard.string(forKey: "clockStyle") ?? "Классический" {
        didSet {
            UserDefaults.standard.set(clockStyle, forKey: "clockStyle")
            objectWillChange.send()
        }
    }
    @Published var tasks: [TaskOnRing] = [] {
        didSet {
            handleTasksUpdate(oldValue: oldValue, newValue: tasks)
        }
    }
    @Published var overlappingTaskGroups: [[TaskOnRing]] = []

    // MARK: - AppStorage Properties
    @AppStorage("lightModeHandColor") var lightModeHandColor: String = Color.blue.toHex()
    @AppStorage("darkModeHandColor") var darkModeHandColor: String = Color.blue.toHex()
    @AppStorage("lightModeDigitalFontColor") var lightModeDigitalFontColor: String = Color.gray.toHex()
    @AppStorage("darkModeDigitalFontColor") var darkModeDigitalFontColor: String = Color.white.toHex()
    @AppStorage("digitalFont") var digitalFont: String = Constants.defaultFontName
    @AppStorage("showTimeOnlyForActiveTask") var showTimeOnlyForActiveTask: Bool = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()
    @AppStorage("lightModeOuterRingColor") var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("taskArcLineWidth") var taskArcLineWidthRaw: Double = 20
    @AppStorage("isAnalogArcStyle") var isAnalogArcStyle: Bool = false
    @AppStorage("outerRingLineWidth") var outerRingLineWidthRaw: Double = 20
    @AppStorage("showHourNumbers") var showHourNumbers: Bool = true {
        didSet {
            markersViewModel.showHourNumbers = showHourNumbers
        }
    }
    @AppStorage("markersWidth") var markersWidth: Double = Constants.defaultMarkersWidth {
        didSet {
            markersViewModel.markersWidth = markersWidth
        }
    }
    @AppStorage("markersOffset") var markersOffset: Double = 0.0 {
        didSet {
            markersViewModel.markersOffset = markersOffset
        }
    }
    @AppStorage("numbersSize") var numbersSize: Double = Constants.defaultNumbersSize {
        didSet {
            markersViewModel.numbersSize = numbersSize
        }
    }
    @AppStorage("numberInterval") var numberInterval: Int = Constants.defaultNumberInterval {
        didSet {
            markersViewModel.numberInterval = numberInterval
            updateMarkersViewModel()
        }
    }
    @AppStorage("lightModeMarkersColor") var lightModeMarkersColor: String = Color.gray.toHex() {
        didSet {
            markersViewModel.lightModeMarkersColor = lightModeMarkersColor
            updateMarkersViewModel()
        }
    }
    @AppStorage("darkModeMarkersColor") var darkModeMarkersColor: String = Color.gray.toHex() {
        didSet {
            markersViewModel.darkModeMarkersColor = darkModeMarkersColor
            updateMarkersViewModel()
        }
    }
    @AppStorage("showMarkers") var showMarkers: Bool = true {
        didSet {
            markersViewModel.showMarkers = showMarkers
        }
    }
    @AppStorage("fontName") var fontName: String = Constants.defaultFontName {
        didSet {
            markersViewModel.fontName = fontName
        }
    }
    @AppStorage("markerStyle") var markerStyleRaw: String = MarkerStyle.lines.rawValue {
        didSet {
            if let style = MarkerStyle(rawValue: markerStyleRaw) {
                markersViewModel.markerStyle = style
            }
        }
    }
    @AppStorage("showIntermediateMarkers") var showIntermediateMarkers: Bool = true {
        didSet {
            markersViewModel.showIntermediateMarkers = showIntermediateMarkers
        }
    }
    @AppStorage("digitalFontSize") var digitalFontSizeRaw: Double = Constants.defaultDigitalFontSize {
        didSet {
            markersViewModel.digitalFontSize = digitalFontSizeRaw
        }
    }

    
    var taskArcLineWidth: CGFloat {
        get { CGFloat(taskArcLineWidthRaw) }
        set { taskArcLineWidthRaw = Double(newValue) }
    }
    var outerRingLineWidth: CGFloat {
        get { CGFloat(outerRingLineWidthRaw) }
        set { outerRingLineWidthRaw = Double(newValue) }
    }
    var markerStyle: MarkerStyle {
        get {
            MarkerStyle(rawValue: markerStyleRaw) ?? .lines
        }
        set {
            markerStyleRaw = newValue.rawValue
        }
    }
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }
    private var currentActiveCategory: TaskCategoryModel?

    // MARK: - Initialization    
    init(sharedState: SharedStateService = .shared) {
        self.sharedState = sharedState
        self.clockState = ClockStateManager()
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
        self.isDarkMode = ThemeManager.shared.isDarkMode
        
        let initialDate = Date()
        self.selectedDate = initialDate
        
        let taskManagement = TaskManagement(sharedState: sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement
        
        let categoryManager = CategoryManagement(context: sharedState.context, sharedState: sharedState)
        self.categoryManagement = categoryManager
        
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        self.dockBarViewModel = DockBarViewModel(categoryManagement: categoryManager)
        
        self.tasks = sharedState.tasks
        
        setupInitialState()
        setupBindings()
        setupNotifications()
    }
    
    private func setupInitialState() {
        initializeMarkersViewModel()
    }
    
    private func setupBindings() {
        setupDockBarBindings()
        setupTaskBindings()
    }
    
    private func setupNotifications() {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ClockStyleDidChange"),
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func updateCurrentTimeIfNeeded() {
        guard Calendar.current.isDate(selectedDate, inSameDayAs: Date()) else { return }
        
        currentDate = Date()
        checkForCategoryChange()
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


    // MARK: - Private Methods
    @objc private func handleZeroPositionChange() {
        DispatchQueue.main.async { [weak self] in
            let newPosition = ZeroPositionManager.shared.zeroPosition
            self?.zeroPosition = newPosition
            self?.markersViewModel.zeroPosition = newPosition
            // Принудительно обновляем UI
            self?.objectWillChange.send()
        }
    }
    @objc private func handleClockStyleChange(_ notification: Notification) {
        if let newStyle = notification.userInfo?["clockStyle"] as? String {
            DispatchQueue.main.async { [weak self] in
                // Проверяем, что стиль действительно изменился
                if self?.clockStyle != newStyle {
                    self?.clockStyle = newStyle
                    // objectWillChange.send() 
                }
            }
        }
    }
    private func initializeMarkersViewModel() {
        markersViewModel.showHourNumbers = showHourNumbers
        markersViewModel.markersWidth = markersWidth
        markersViewModel.markersOffset = markersOffset
        markersViewModel.numbersSize = numbersSize
        markersViewModel.lightModeMarkersColor = lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = darkModeMarkersColor
        markersViewModel.isDarkMode = isDarkMode
        markersViewModel.zeroPosition = zeroPosition
        markersViewModel.numberInterval = numberInterval
        markersViewModel.showMarkers = showMarkers
        markersViewModel.fontName = fontName
        markersViewModel.markerStyle = markerStyle
        markersViewModel.showIntermediateMarkers = showIntermediateMarkers
        markersViewModel.digitalFontSize = digitalFontSizeRaw
        markersViewModel.lightModeDigitalFontColor = lightModeDigitalFontColor
        markersViewModel.darkModeDigitalFontColor = darkModeDigitalFontColor
    }
    
    // MARK: - Formatted Date Methods
    var formattedDate: String {
        switch Locale.current.language.languageCode?.identifier {
        case "ru":
            return selectedDate.formattedForClockDate()
        case "zh":
            return selectedDate.formattedForClockDateZh()
        case "es":
            return selectedDate.formattedForClockDateEs()
        case "ja":
            return selectedDate.formattedForClockDateJa()
        case "fr":
            return selectedDate.formattedForClockDateFr()
        default:
            return selectedDate.formattedForClockDateEn()
        }
    }
    
    var formattedWeekday: String {
        switch Locale.current.language.languageCode?.identifier {
        case "ru":
            return selectedDate.formattedWeekday()
        case "zh":
            return selectedDate.formattedWeekdayZh()
        case "es":
            return selectedDate.formattedWeekdayEs()
        case "ja":
            return selectedDate.formattedWeekdayJa()
        case "fr":
            return selectedDate.formattedWeekdayFr()
        default:
            return selectedDate.formattedWeekdayEn()
        }
    }
    
    // MARK: - UI Update Methods
    func updateMarkersViewModel() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let tempValue = self.markersViewModel.markersWidth
            self.markersViewModel.markersWidth = tempValue + 0.01
            DispatchQueue.main.async {
                self.markersViewModel.markersWidth = tempValue
            }
        }
    }
    
    func updateUIForThemeChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let currentThemeIsDark = ThemeManager.shared.isDarkMode
            if self.isDarkMode != currentThemeIsDark {
                self.isDarkMode = currentThemeIsDark
            }
            if self.markersViewModel.isDarkMode != currentThemeIsDark {
                self.markersViewModel.isDarkMode = currentThemeIsDark
            }
            self.markersViewModel.updateCurrentThemeColors()
            self.objectWillChange.send()
            self.markersViewModel.objectWillChange.send()
        }
    }
    
    // MARK: - Task Management Methods
    func updateDragPosition(isOutsideClock: Bool) {
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }

    // MARK: - Time and Angle Methods
    func updateZeroPosition(_ newPosition: Double) {
        ZeroPositionManager.shared.updateZeroPosition(newPosition)
        zeroPosition = newPosition
    }
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        RingTimeCalculator.getTimeWithZeroOffset(date, baseDate: selectedDate, zeroPosition: zeroPosition, inverse: inverse)
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
    
    // MARK: - Category Change Methods
    private func checkForCategoryChange() {
        guard notificationsEnabled else { return }
        
        let todayTasks = tasksForSelectedDate(tasks)
        let now = Date()
        
        let activeTask = todayTasks.first { task in
            task.startTime <= now && task.endTime > now
        }
        
        let newActiveCategory = activeTask?.category
        
        if let newCategory = newActiveCategory, newCategory != currentActiveCategory {
            currentActiveCategory = newCategory
            notificationService.sendCategoryStartNotification(category: newCategory)
        } else if newActiveCategory == nil && currentActiveCategory != nil {
            currentActiveCategory = nil
        }
    }

    // MARK: - Dock Bar Binding Methods
    private func setupDockBarBindings() {
        dockBarViewModel.$selectedCategory
            .sink { [weak self] newCategory in
                if self?.selectedCategory != newCategory {
                    self?.selectedCategory = newCategory
                }
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$draggedCategory
            .sink { [weak self] newCategory in
                print("🔄 DEBUG: DockBar draggedCategory changed to: \(newCategory?.rawValue ?? "nil")")
                print("🔄 DEBUG: Current ClockViewModel draggedCategory: \(self?.draggedCategory?.rawValue ?? "nil")")
                if self?.draggedCategory != newCategory {
                    self?.draggedCategory = newCategory
                    print("✅ DEBUG: ClockViewModel draggedCategory updated to: \(newCategory?.rawValue ?? "nil")")
                }
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$showingAddTask
            .sink { [weak self] newValue in
                if self?.showingAddTask != newValue {
                    self?.showingAddTask = newValue
                }
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$showingCategoryEditor
            .sink { [weak self] newValue in
                if self?.showingCategoryEditor != newValue {
                    self?.showingCategoryEditor = newValue
                }
            }
            .store(in: &cancellables)
            
        dockBarViewModel.selectedCategory = selectedCategory
        dockBarViewModel.draggedCategory = draggedCategory
        dockBarViewModel.showingAddTask = showingAddTask
        dockBarViewModel.showingCategoryEditor = showingCategoryEditor
    }
    
    // MARK: - Task Management Methods
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // updateWidgetData()
    }

    // MARK: - Widget Update Methods
    // private func updateWidgetData() {
    //     guard let defaults = UserDefaults(suiteName: "group.AbstractSoft.TaskFl0w") else {
    //         print("Не удалось получить доступ к группе UserDefaults")
    //         return
    //     }
        
    //     updateWidgetCurrentCategory(defaults)
    //     updateWidgetTasks(defaults)
    //     updateWidgetCategories(defaults)
        
    //     WidgetCenter.shared.reloadAllTimelines()
    // }

    // private func updateWidgetCurrentCategory(_ defaults: UserDefaults) {
    //     // Логика обновления текущей категории
    // }

    // private func updateWidgetTasks(_ defaults: UserDefaults) {
    //     // Логика обновления задач
    // }

    // private func updateWidgetCategories(_ defaults: UserDefaults) {
    //     // Логика обновления категорий
    // }

    // Модифицируем метод applyWatchFaceSettings() для обновления ThemeManager
    func applyWatchFaceSettings() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Получаем ThemeManager
            let themeManager = ThemeManager.shared
            
            // Перезагружаем основные настройки
            self.showHourNumbers = UserDefaults.standard.bool(forKey: "showHourNumbers")
            self.markersWidth = UserDefaults.standard.double(forKey: "markersWidth")
            self.markersOffset = UserDefaults.standard.double(forKey: "markersOffset")
            self.numbersSize = UserDefaults.standard.double(forKey: "numbersSize")
            self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
            self.numberInterval = UserDefaults.standard.integer(forKey: "numberInterval")
            self.showMarkers = UserDefaults.standard.bool(forKey: "showMarkers")
            self.fontName = UserDefaults.standard.string(forKey: "fontName") ?? "SF Pro"
            self.outerRingLineWidthRaw = UserDefaults.standard.double(forKey: "outerRingLineWidth")
            self.taskArcLineWidthRaw = UserDefaults.standard.double(forKey: "taskArcLineWidth")
            self.isAnalogArcStyle = UserDefaults.standard.bool(forKey: "isAnalogArcStyle")
            self.showTimeOnlyForActiveTask = UserDefaults.standard.bool(forKey: "showTimeOnlyForActiveTask")
            self.digitalFont = UserDefaults.standard.string(forKey: "digitalFont") ?? "SF Pro"
            self.digitalFontSizeRaw = UserDefaults.standard.double(forKey: "digitalFontSize")
            
            // Обновляем цвета в ThemeManager
            if let lightFaceColorHex = UserDefaults.standard.string(forKey: "lightModeClockFaceColor"),
               let lightFaceColor = Color(hex: lightFaceColorHex) {
                self.lightModeClockFaceColor = lightFaceColorHex
                themeManager.updateColor(lightFaceColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
            }
            
            if let darkFaceColorHex = UserDefaults.standard.string(forKey: "darkModeClockFaceColor"),
               let darkFaceColor = Color(hex: darkFaceColorHex) {
                self.darkModeClockFaceColor = darkFaceColorHex
                themeManager.updateColor(darkFaceColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
            }
            
            if let lightRingColorHex = UserDefaults.standard.string(forKey: "lightModeOuterRingColor"),
               let lightRingColor = Color(hex: lightRingColorHex) {
                self.lightModeOuterRingColor = lightRingColorHex
                themeManager.updateColor(lightRingColor, for: ThemeManager.Constants.lightModeOuterRingColorKey)
            }
            
            if let darkRingColorHex = UserDefaults.standard.string(forKey: "darkModeOuterRingColor"),
               let darkRingColor = Color(hex: darkRingColorHex) {
                self.darkModeOuterRingColor = darkRingColorHex
                themeManager.updateColor(darkRingColor, for: ThemeManager.Constants.darkModeOuterRingColorKey)
            }
            
            if let lightMarkersColorHex = UserDefaults.standard.string(forKey: "lightModeMarkersColor"),
               let lightMarkersColor = Color(hex: lightMarkersColorHex) {
                self.lightModeMarkersColor = lightMarkersColorHex
                themeManager.updateColor(lightMarkersColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
            }
            
            if let darkMarkersColorHex = UserDefaults.standard.string(forKey: "darkModeMarkersColor"),
               let darkMarkersColor = Color(hex: darkMarkersColorHex) {
                self.darkModeMarkersColor = darkMarkersColorHex
                themeManager.updateColor(darkMarkersColor, for: ThemeManager.Constants.darkModeMarkersColorKey)
            }
            
            if let lightDigitalFontColorHex = UserDefaults.standard.string(forKey: "lightModeDigitalFontColor") {
                self.lightModeDigitalFontColor = lightDigitalFontColorHex
            }
            
            if let darkDigitalFontColorHex = UserDefaults.standard.string(forKey: "darkModeDigitalFontColor") {
                self.darkModeDigitalFontColor = darkDigitalFontColorHex
            }
            
            if let lightHandColorHex = UserDefaults.standard.string(forKey: "lightModeHandColor") {
                self.lightModeHandColor = lightHandColorHex
            }
            
            if let darkHandColorHex = UserDefaults.standard.string(forKey: "darkModeHandColor") {
                self.darkModeHandColor = darkHandColorHex
            }
            
            if let savedStyle = UserDefaults.standard.string(forKey: "clockStyle") {
                self.clockStyle = savedStyle
            }
            
            if let rawStyle = UserDefaults.standard.string(forKey: "markerStyle"),
               let style = MarkerStyle(rawValue: rawStyle) {
                self.markerStyle = style
            }
            
            self.showIntermediateMarkers = UserDefaults.standard.bool(forKey: "showIntermediateMarkers")
            
            self.initializeMarkersViewModel()
            
            DispatchQueue.main.async {
                themeManager.objectWillChange.send()
            }
            
            self.objectWillChange.send()
            self.markersViewModel.objectWillChange.send()
            
            self.updateMarkersViewModel()
        }
    }

    private func setupTaskBindings() {
        self.sharedState.subscribeToTasksUpdates { [weak self] in
            guard let self = self else { return }
            self.tasks = self.sharedState.tasks
        }
        
        $selectedDate
            .sink { [weak self] newDate in
                guard let self = self else { return }
                // Обновляем selectedDate в TaskManagement
                (self.taskManagement as? TaskManagement)?.selectedDate = newDate
                // Обновляем задачи для выбранной даты
                self.updateTasksForSelectedDate()
                // Обновляем состояние clockState
                self.clockState.selectedDate = newDate
            }
            .store(in: &cancellables)
    }

    // MARK: - Task Update Handling Methods
    private func handleTasksUpdate(oldValue: [TaskOnRing], newValue: [TaskOnRing]) {
        // Обновляем редактируемую задачу если она была изменена
        updateEditingTaskIfNeeded(newTasks: newValue)
        
        // Проверяем наличие конфликтов и перекрытий
        validateTaskOverlaps(newValue)
        
        // Уведомляем TaskArcs компоненты об изменениях
        notifyTaskArcsComponents(oldTasks: oldValue, newTasks: newValue)
        
        // Обновляем состояние категорий
        updateCategoryStates(newValue)
    }

    private func updateEditingTaskIfNeeded(newTasks: [TaskOnRing]) {
        guard let editingTask = editingTask else { return }
        
        if let updatedTask = newTasks.first(where: { $0.id == editingTask.id }) {
            // Обновляем редактируемую задачу только если она действительно изменилась
            if !tasksAreEqual(editingTask, updatedTask) {
                self.editingTask = updatedTask
            }
        } else {
            // Редактируемая задача была удалена
            self.editingTask = nil
            self.isEditingMode = false
        }
    }

    private func validateTaskOverlaps(_ newTasks: [TaskOnRing]) {
        // Проверяем задачи только для выбранной даты
        let todayTasks = newTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        // Группируем перекрывающиеся задачи для дальнейшей обработки
        let overlappingGroups = findOverlappingTaskGroups(todayTasks)
        
        // Сохраняем информацию о перекрытиях напрямую в ClockViewModel
        self.overlappingTaskGroups = overlappingGroups
    }

    private func notifyTaskArcsComponents(oldTasks: [TaskOnRing], newTasks: [TaskOnRing]) {
        // Находим добавленные задачи
        let addedTasks = newTasks.filter { newTask in
            !oldTasks.contains { $0.id == newTask.id }
        }
        
        // Находим удаленные задачи
        let removedTasks = oldTasks.filter { oldTask in
            !newTasks.contains { $0.id == oldTask.id }
        }
        
        // Находим измененные задачи
        let modifiedTasks = newTasks.compactMap { newTask -> TaskOnRing? in
            guard let oldTask = oldTasks.first(where: { $0.id == newTask.id }) else { return nil }
            return tasksAreEqual(oldTask, newTask) ? nil : newTask
        }
        
        // Отправляем уведомления компонентам TaskArcs
        if !addedTasks.isEmpty {
            NotificationCenter.default.post(
                name: .taskArcsTasksAdded,
                object: self,
                userInfo: ["addedTasks": addedTasks]
            )
        }
        
        if !removedTasks.isEmpty {
            NotificationCenter.default.post(
                name: .taskArcsTasksRemoved,
                object: self,
                userInfo: ["removedTasks": removedTasks]
            )
        }
        
        if !modifiedTasks.isEmpty {
            NotificationCenter.default.post(
                name: .taskArcsTasksModified,
                object: self,
                userInfo: ["modifiedTasks": modifiedTasks]
            )
        }
    }

    private func updateCategoryStates(_ newTasks: [TaskOnRing]) {
        // Обновляем информацию о текущей активной категории
        checkForCategoryChange()
        
        // Обновляем статистику категорий для внутреннего использования
        updateCategoryStatistics(newTasks)
    }

    private func updateCategoryStatistics(_ tasks: [TaskOnRing]) {
        // Подсчитываем задачи по категориям для внутренней статистики
        let categoryTaskCounts = Dictionary(grouping: tasks) { $0.category }
            .mapValues { $0.count }
        
        // Уведомляем об изменениях в статистике категорий
        NotificationCenter.default.post(
            name: .categoryStatisticsUpdated,
            object: self,
            userInfo: ["categoryTaskCounts": categoryTaskCounts]
        )
    }

    private func findOverlappingTaskGroups(_ tasks: [TaskOnRing]) -> [[TaskOnRing]] {
        var overlappingGroups: [[TaskOnRing]] = []
        var processedTasks: Set<UUID> = []
        
        for task in tasks.sorted(by: { $0.startTime < $1.startTime }) {
            if processedTasks.contains(task.id) { continue }
            
            var currentGroup: [TaskOnRing] = [task]
            processedTasks.insert(task.id)
            
            // Ищем все задачи, которые пересекаются с текущей
            for otherTask in tasks where !processedTasks.contains(otherTask.id) {
                if tasksOverlap(task, otherTask) {
                    currentGroup.append(otherTask)
                    processedTasks.insert(otherTask.id)
                }
            }
            
            // Добавляем группу только если в ней больше одной задачи
            if currentGroup.count > 1 {
                overlappingGroups.append(currentGroup)
            }
        }
        
        return overlappingGroups
    }

    private func tasksOverlap(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        return task1.startTime < task2.endTime && task1.endTime > task2.startTime
    }

    private func tasksAreEqual(_ task1: TaskOnRing, _ task2: TaskOnRing) -> Bool {
        return task1.id == task2.id &&
               task1.startTime == task2.startTime &&
               task1.endTime == task2.endTime &&
               task1.category == task2.category &&
               task1.isCompleted == task2.isCompleted
    }

    // Добавляем метод для принудительного обновления UI
    func forceUIUpdate() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
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
