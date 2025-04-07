import Combine
import CoreData
//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

final class ClockViewModel: ObservableObject {
    // MARK: - Services
    let sharedState: SharedStateService
    let taskManagement: TaskManagementProtocol
    let categoryManagement: CategoryManagementProtocol
    let clockState: ClockStateManager

    // MARK: - View Models
    let markersViewModel = ClockMarkersViewModel()
    let dragAndDropManager: DragAndDropManager

    // MARK: - Published properties
    @Published var tasks: [TaskOnRing] = []

    // Доступ к категориям только для чтения
    var categories: [TaskCategoryModel] {
        categoryManagement.categories
    }

    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date() {
        didSet {
            // Обновляем selectedDate в TaskManagement при изменении
            (taskManagement as? TaskManagement)?.selectedDate = selectedDate
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
    @Published var selectedCategory: TaskCategoryModel?

    // Drag & Drop
    @Published var draggedCategory: TaskCategoryModel?

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
    @AppStorage("markersOffset") var markersOffset: Double = 40.0 {
        didSet {
            markersViewModel.markersOffset = markersOffset
        }
    }
    @AppStorage("numbersSize") var numbersSize: Double = 12.0 {
        didSet {
            markersViewModel.numbersSize = numbersSize
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
        self.categoryManagement = CategoryManagement(
            context: sharedState.context, sharedState: sharedState)

        // Инициализируем DragAndDropManager
        self.dragAndDropManager = DragAndDropManager(taskManagement: taskManagement)

        // Подписываемся на обновления задач
        sharedState.subscribeToTasksUpdates { [weak self] in
            self?.tasks = sharedState.tasks
        }

        self.tasks = sharedState.tasks
        
        // Инициализируем настройки маркеров
        initializeMarkersViewModel()
    }
    
    deinit {
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
    }
    
    // MARK: - Методы форматирования даты
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate)
    }
    
    var formattedWeekday: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate).capitalized
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
        dragAndDropManager.startDragging(task)
    }

    func stopDragging(didReturnToClock: Bool) {
        dragAndDropManager.stopDragging(didReturnToClock: didReturnToClock)
    }

    func updateDragPosition(isOutsideClock: Bool) {
        dragAndDropManager.updateDragPosition(isOutsideClock: isOutsideClock)
    }

    // MARK: - Методы работы со временем и углами

    // Добавляем метод для обновления положения нуля
    func updateZeroPosition(_ newPosition: Double) {
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
        }
    }
}
