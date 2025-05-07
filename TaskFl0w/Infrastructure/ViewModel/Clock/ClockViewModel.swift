import Combine
import CoreData
//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Foundation
import WidgetKit

final class ClockViewModel: ObservableObject {
    // MARK: - Services
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    let clockState: ClockStateManager

    // MARK: - View Models
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager
    // Добавляем ViewModel для панели категорий
    let dockBarViewModel: DockBarViewModel

    // MARK: - Published properties
    @Published var tasks: [TaskOnRing] = [] {
        didSet {
            // Если есть редактируемая задача, обновляем ее из списка задач
            if let editingTask = editingTask, 
               let updatedTask = tasks.first(where: { $0.id == editingTask.id }) {
                self.editingTask = updatedTask
            }
        }
    }

    // Доступ к категориям только для чтения
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }

    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date() {
        didSet {
            // Обновляем selectedDate в TaskManagement при изменении
            (taskManagement as? TaskManagement)?.selectedDate = selectedDate
            
            // Обновляем задачи для выбранной даты
            updateTasksForSelectedDate()
            
            // Обновляем состояние clockState
            clockState.selectedDate = selectedDate
        }
    }

    // Текущее время для реального обновления
    @Published var currentDate: Date = Date()

    // Режим темной темы
    @Published var isDarkMode: Bool = false {
        didSet {
            // Только если изменилось значение относительно ThemeManager
            if isDarkMode != ThemeManager.shared.isDarkMode {
                // При изменении isDarkMode обновляем UserDefaults и ThemeManager
                UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
                // Отключаем цикличное обновление
                ThemeManager.shared.setTheme(isDarkMode)
                
                // Обновляем маркеры
                markersViewModel.isDarkMode = isDarkMode
                markersViewModel.updateCurrentThemeColors()
            }
        }
    }

    // Пример использования AppStorage для цвета циферблата
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()

    @Published var isDockBarEditingEnabled: Bool = false

    // Перетаскивание задачи
    @Published var draggedTask: TaskOnRing?
    @Published var isDraggingOutside: Bool = false

    // Состояния представлений
    @Published var showingAddTask: Bool = false
    @Published var showingSettings: Bool = false
    @Published var showingCalendar: Bool = false
    @Published var showingStatistics: Bool = false
    @Published var showingTodayTasks: Bool = false
    @Published var showingCategoryEditor: Bool = false
    @Published var selectedCategory: TaskCategoryModel? {
        didSet {
            // Синхронизируем с dockBarViewModel
            dockBarViewModel.selectedCategory = selectedCategory
        }
    }

    // Drag & Drop
    @Published var draggedCategory: TaskCategoryModel? {
        didSet {
            // Синхронизируем с dockBarViewModel
            dockBarViewModel.draggedCategory = draggedCategory
        }
    }

    // Режим редактирования
    @Published var isEditingMode: Bool = false
    @Published var editingTask: TaskOnRing?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTask: TaskOnRing?
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""

    // Добавляем свойство для положения нуля
    @Published var zeroPosition: Double {
        didSet {
            // Сохраняем значение в UserDefaults при изменении
            UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
        }
    }
    
    // AppStorage для маркеров
    @AppStorage("showHourNumbers") var showHourNumbers: Bool = true {
        didSet {
            markersViewModel.showHourNumbers = showHourNumbers
        }
    }
    @AppStorage("markersWidth") var markersWidth: Double = 2.0 {
        didSet {
            markersViewModel.markersWidth = markersWidth
        }
    }
    @AppStorage("markersOffset") var markersOffset: Double = 0.0 {
        didSet {
            markersViewModel.markersOffset = markersOffset
        }
    }
    @AppStorage("numbersSize") var numbersSize: Double = 16.0 {
        didSet {
            markersViewModel.numbersSize = numbersSize
        }
    }
    @AppStorage("numberInterval") var numberInterval: Int = 1 {
        didSet {
            markersViewModel.numberInterval = numberInterval
            updateMarkersViewModel() // Обновляем представление для немедленного отображения изменений
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
    
    // Outer ring colors
    @AppStorage("lightModeOuterRingColor") var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()

    // AppStorage for taskArcLineWidth
    @AppStorage("taskArcLineWidth") var taskArcLineWidthRaw: Double = 20

    var taskArcLineWidth: CGFloat {
        get { CGFloat(taskArcLineWidthRaw) }
        set { taskArcLineWidthRaw = Double(newValue) }
    }

    @AppStorage("outerRingLineWidth") var outerRingLineWidthRaw: Double = 20

    var outerRingLineWidth: CGFloat {
        get { CGFloat(outerRingLineWidthRaw) }
        set { outerRingLineWidthRaw = Double(newValue) }
    }

    // AppStorage for isAnalogArcStyle
    @AppStorage("isAnalogArcStyle") var isAnalogArcStyle: Bool = false

    @AppStorage("showMarkers") var showMarkers: Bool = true {
        didSet {
            markersViewModel.showMarkers = showMarkers
        }
    }

    @AppStorage("fontName") var fontName: String = "SF Pro" {
        didSet {
            markersViewModel.fontName = fontName
        }
    }

    // Добавляем сервис уведомлений
    private let notificationService: NotificationServiceProtocol = NotificationService.shared
    
    // Для отслеживания текущей активной категории
    private var currentActiveCategory: TaskCategoryModel?
    
    // Флаг для проверки, разрешены ли уведомления
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    // MARK: - Инициализация
    init(sharedState: SharedStateService = .shared) {
        self.sharedState = sharedState
        self.clockState = ClockStateManager()

        // Загружаем сохраненное значение zeroPosition
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")
        
        // Инициализируем isDarkMode из ThemeManager
        self.isDarkMode = ThemeManager.shared.isDarkMode

        // Сначала инициализируем selectedDate
        let initialDate = Date()
        self.selectedDate = initialDate

        // Теперь можем безопасно использовать selectedDate
        let taskManagement = TaskManagement(sharedState: sharedState, selectedDate: initialDate)
        self.taskManagement = taskManagement
        let categoryManager = CategoryManagement(
            context: sharedState.context, sharedState: sharedState)
        self.categoryManagement = categoryManager

        // Инициализируем DragAndDropManager
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)
        
        // Инициализируем DockBarViewModel
        self.dockBarViewModel = DockBarViewModel(categoryManagement: categoryManager)

        // Подписываемся на обновления задач
        sharedState.subscribeToTasksUpdates { [weak self] in
            self?.tasks = sharedState.tasks
        }

        self.tasks = sharedState.tasks
        
        // Инициализируем настройки маркеров
        initializeMarkersViewModel()
        
        // Подписываемся на уведомления об изменении zeroPosition
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleZeroPositionChange),
            name: .zeroPositionDidChange,
            object: nil
        )
        
        // Настраиваем двустороннее связывание с dockBarViewModel
        setupDockBarBindings()
    }
    
    deinit {
        // Отписываемся от уведомлений
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Обработчики уведомлений
    
    @objc private func handleZeroPositionChange() {
        // Обновляем zeroPosition из ZeroPositionManager
        DispatchQueue.main.async { [weak self] in
            let newPosition = ZeroPositionManager.shared.zeroPosition
            self?.zeroPosition = newPosition
            self?.markersViewModel.zeroPosition = newPosition
            // Принудительно обновляем UI
            self?.objectWillChange.send()
        }
    }
    
    // MARK: - Методы инициализации
    
    private func initializeMarkersViewModel() {
        // Инициализируем начальные значения для markersViewModel
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
    }
    
    // MARK: - Методы форматирования даты
    
    var formattedDate: String {
        return selectedDate.formattedForClockDate()
    }
    
    var formattedWeekday: String {
        return selectedDate.formattedWeekday()
    }
    
    // MARK: - Методы обновления UI
    
    func updateMarkersViewModel() {
        // Создаем временное обновление для принудительного обновления вида
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
        // Гарантируем, что UI обновится при смене темы
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Передаем статус темной темы из ThemeManager в ViewModel
            let currentThemeIsDark = ThemeManager.shared.isDarkMode
            if self.isDarkMode != currentThemeIsDark {
                self.isDarkMode = currentThemeIsDark
            }
            if self.markersViewModel.isDarkMode != currentThemeIsDark {
                self.markersViewModel.isDarkMode = currentThemeIsDark
            }
            
            // Принудительно обновляем UI
            self.markersViewModel.updateCurrentThemeColors()
            
            // Обновляем свойства моделей, которые вызовут обновление представления
            self.objectWillChange.send()
            self.markersViewModel.objectWillChange.send()
        }
    }
    
    // MARK: - Методы управления задачами

    func startDragging(_ task: TaskOnRing) {
        // Задаем задачу для перетаскивания
        draggedTask = task
        // Мы намеренно НЕ сбрасываем draggedCategory, так как это независимый процесс
        dragAndDropManager.startDragging(task)
        print("Перетаскивание категории на циферблате: \(task.category.rawValue)")
    }

    func stopDragging(didReturnToClock: Bool) {
        // 1. даём менеджеру удалить задачу, если она ушла за пределы часов
        dragAndDropManager.stopDragging(didReturnToClock: didReturnToClock)

        // 2. сбрасываем локальное состояние
        draggedTask = nil          // главное добавление
        isDraggingOutside = false  // на всякий случай
    }

    func updateDragPosition(isOutsideClock: Bool) {
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }

    // MARK: - Методы работы со временем и углами

    // Добавляем метод для обновления положения нуля
    func updateZeroPosition(_ newPosition: Double) {
        // Обновляем через ZeroPositionManager, чтобы все подписчики получили уведомление
        ZeroPositionManager.shared.updateZeroPosition(newPosition)
        
        // Локально обновляем значение (это должно произойти и через обработчик уведомления)
        zeroPosition = newPosition
    }

    // Делегируем расчеты в RingTimeCalculator
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        RingTimeCalculator.getTimeWithZeroOffset(date, baseDate: selectedDate, zeroPosition: zeroPosition, inverse: inverse)
    }

    func angleToTime(_ angle: Double) -> Date {
        RingTimeCalculator.angleToTime(angle, baseDate: selectedDate, zeroPosition: zeroPosition)
    }

    func timeToAngle(_ date: Date) -> Double {
        RingTimeCalculator.timeToAngle(date, zeroPosition: zeroPosition)
    }

    /// Получает задачи для выбранной даты
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: clockState.selectedDate)
        }
    }
    
    // MARK: - Методы обработки обновления часов
    
    func updateCurrentTimeIfNeeded() {
        // Если выбранная дата совпадает с сегодня, тогда обновляем "currentDate" каждую секунду
        if Calendar.current.isDate(selectedDate, inSameDayAs: Date()) {
            currentDate = Date()
            
            // Проверяем, изменилась ли активная категория
            checkForCategoryChange()
        }
    }

    // Проверка изменения активной категории на циферблате
    private func checkForCategoryChange() {
        // Проверяем, включены ли уведомления
        guard notificationsEnabled else { return }
        
        // Получаем текущие задачи на сегодня
        let todayTasks = tasksForSelectedDate(tasks)
        
        // Ищем задачу, которая активна в данный момент времени
        let now = Date()
        let activeTask = todayTasks.first { task in
            task.startTime <= now && task.endTime > now
        }
        
        // Получаем категорию текущей активной задачи
        let newActiveCategory = activeTask?.category
        
        // Если категория изменилась, отправляем уведомление
        if let newCategory = newActiveCategory, newCategory != currentActiveCategory {
            print("Обнаружена новая активная категория: \(newCategory.rawValue)")
            
            // Сохраняем новую активную категорию
            currentActiveCategory = newCategory
            
            // Отправляем уведомление о начале новой категории
            notificationService.sendCategoryStartNotification(category: newCategory)
            
            // Обновляем данные для виджета
            updateWidgetData()
        } else if newActiveCategory == nil && currentActiveCategory != nil {
            print("Больше нет активной категории")
            // Если больше нет активной категории, сбрасываем текущую
            currentActiveCategory = nil
            
            // Обновляем данные для виджета
            updateWidgetData()
        }
    }

    // Метод для настройки двусторонней синхронизации с dockBarViewModel
    private func setupDockBarBindings() {
        // Следим за изменениями в dockBarViewModel и синхронизируем с ClockViewModel
        dockBarViewModel.$selectedCategory
            .sink { [weak self] newCategory in
                if self?.selectedCategory != newCategory {
                    self?.selectedCategory = newCategory
                }
            }
            .store(in: &cancellables)
            
        dockBarViewModel.$draggedCategory
            .sink { [weak self] newCategory in
                if self?.draggedCategory != newCategory {
                    self?.draggedCategory = newCategory
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
            
        // Начальная синхронизация
        dockBarViewModel.selectedCategory = selectedCategory
        dockBarViewModel.draggedCategory = draggedCategory
        dockBarViewModel.showingAddTask = showingAddTask
        dockBarViewModel.showingCategoryEditor = showingCategoryEditor
    }
    
    // Добавляем коллекцию для хранения подписок
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Методы управления задачами и обновления циферблата
    
    /// Обновляет задачи для выбранной даты
    private func updateTasksForSelectedDate() {
        // Получаем все задачи из SharedState
        let allTasks = sharedState.tasks
        
        // Фильтруем задачи на выбранную дату
        let tasksOnSelectedDate = allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }
        
        // Получаем незавершенные задачи с предыдущих дней
        let incompleteTasksFromPreviousDays = allTasks.filter { task in
            !task.isCompleted && 
            Calendar.current.compare(task.startTime, to: selectedDate, toGranularity: .day) == .orderedAscending
        }
        
        // Объединяем задачи текущего дня и невыполненные с предыдущих дней
        tasks = tasksOnSelectedDate + incompleteTasksFromPreviousDays
        
        // Принудительно обновляем интерфейс
        objectWillChange.send()
        
        // Обновляем данные для виджета
        updateWidgetData()
    }

    // Метод для обновления данных виджета
    private func updateWidgetData() {
        guard let defaults = UserDefaults(suiteName: "group.AbstractSoft.TaskFl0w") else {
            print("Не удалось получить доступ к группе UserDefaults")
            return
        }
        
        // Получаем текущие задачи на сегодня
        let todayTasks = tasksForSelectedDate(tasks)
        
        // Ищем задачу, которая активна в данный момент времени
        let now = Date()
        guard let activeTask = todayTasks.first(where: { $0.startTime <= now && $0.endTime > now }),
              let category = activeTask.category as? TaskCategoryModel else {
            // Если нет активной задачи, отправляем пустые данные
            defaults.set("Отдых", forKey: "widget_current_category")
            defaults.set(0, forKey: "widget_time_remaining")
            defaults.set(0, forKey: "widget_total_time")
            
            // Запрашиваем обновление виджета
            WidgetCenter.shared.reloadAllTimelines()
            return
        }
        
        // Сохраняем данные текущей категории для виджета
        defaults.set(category.rawValue, forKey: "widget_current_category")
        defaults.set(activeTask.endTime.timeIntervalSince(now), forKey: "widget_time_remaining")
        defaults.set(activeTask.endTime.timeIntervalSince(activeTask.startTime), forKey: "widget_total_time")
        
        // Сохраняем категории
        let categoryNames = categories.map { $0.rawValue }
        if let categoriesData = try? JSONEncoder().encode(categoryNames) {
            defaults.set(categoriesData, forKey: "widget_categories")
        }
        
        // Сохраняем задачи для виджета
        // Создаем словари вместо объектов WidgetTodoTask
        let widgetTasks = todayTasks.map { task -> [String: Any] in
            return [
                "id": task.id.uuidString,
                "title": task.category.rawValue + " (" + formatTimeForTask(task.startTime) + "-" + formatTimeForTask(task.endTime) + ")",
                "isCompleted": task.isCompleted,
                "category": category.rawValue
            ]
        }
        
        // Используем JSONSerialization вместо JSONEncoder
        if let tasksData = try? JSONSerialization.data(withJSONObject: widgetTasks) {
            defaults.set(tasksData, forKey: "widget_tasks")
        }
        
        // Запрашиваем обновление виджета
        WidgetCenter.shared.reloadAllTimelines()
    }

    // Вспомогательный метод для форматирования времени
    private func formatTimeForTask(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
