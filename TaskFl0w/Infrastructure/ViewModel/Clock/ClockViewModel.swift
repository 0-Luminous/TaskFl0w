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
    }
    
    deinit {
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

    // Обновляем метод коррекции времени
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Получаем часы и минуты
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Вычисляем смещение в минутах
        let offsetDegrees = inverse ? -zeroPosition : zeroPosition
        let offsetHours = offsetDegrees / 15.0  // 15 градусов = 1 час
        let offsetMinutes = offsetHours * 60

        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + 1440).truncatingRemainder(
            dividingBy: 1440)

        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / 60)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? date
    }

    // Вспомогательный метод для конвертации угла в время
    func angleToTime(_ angle: Double) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // Преобразуем угол в минуты (360 градусов = 24 часа = 1440 минут)
        var totalMinutes = angle * 4  // angle * (1440 / 360)

        // Учитываем zeroPosition и переводим в 24-часовой формат
        totalMinutes = (totalMinutes + (90 - zeroPosition) * 4 + 1440).truncatingRemainder(
            dividingBy: 1440)

        components.hour = Int(totalMinutes / 60)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? selectedDate
    }

    // Вспомогательный метод для конвертации времени в угол
    func timeToAngle(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Преобразуем минуты в угол (1440 минут = 360 градусов)
        var angle = totalMinutes / 4  // totalMinutes * (360 / 1440)

        // Учитываем zeroPosition и 90-градусное смещение (12 часов сверху)
        angle = (angle - (90 - zeroPosition) + 360).truncatingRemainder(dividingBy: 360)

        return angle
    }

    /// Получает задачи для выбранной даты
    func tasksForSelectedDate(_ allTasks: [TaskOnRing]) -> [TaskOnRing] {
        allTasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: clockState.selectedDate)
        }
    }
}
