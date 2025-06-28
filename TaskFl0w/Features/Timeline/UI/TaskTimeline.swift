//
//  TimelineView.swift
//  TaskFl0w
//
//  Created by Yan on 1/5/25.
//

import Combine
import SwiftUI

// Оптимизируем структуру TimeBlock для большей гибкости
struct TimeBlock: Identifiable {
    let id = UUID()
    let hour: Int
    let tasks: [TaskOnRing]
    let showHourLabel: Bool
    let isInsideTask: Bool
    let isStartHour: Bool
    let isEndHour: Bool
    let isImportantHour: Bool  // Полдень или полночь

    // Вычисляемые свойства для удобства использования
    var hourString: String {
        if hour == 24 {
            return "00:00"
        }
        return String(format: "%02d:00", hour % 24)
    }

    var hasActiveTasks: Bool {
        !tasks.isEmpty
    }
}

// ОБНОВЛЯЕМ СТРУКТУРУ BlockPosition для соответствия Equatable
struct BlockPosition: Equatable {
    let hour: Int
    let yPosition: CGFloat
    let height: CGFloat
    
    // Реализация Equatable для сравнения позиций блоков
    static func == (lhs: BlockPosition, rhs: BlockPosition) -> Bool {
        return lhs.hour == rhs.hour && 
               abs(lhs.yPosition - rhs.yPosition) < 0.1 && 
               abs(lhs.height - rhs.height) < 0.1
    }
}

// ДОБАВЛЯЕМ PreferenceKey ДЛЯ ПЕРЕДАЧИ ПОЗИЦИЙ БЛОКОВ
struct BlockPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [BlockPosition] = []
    
    static func reduce(value: inout [BlockPosition], nextValue: () -> [BlockPosition]) {
        value.append(contentsOf: nextValue())
    }
}

// ДОБАВЛЯЕМ PreferenceKey ДЛЯ ПЕРЕДАЧИ ЧАСОВ БЛОКОВ
struct BlockHourPreferenceKey: PreferenceKey {
    static var defaultValue: [Int] = []
    
    static func reduce(value: inout [Int], nextValue: () -> [Int]) {
        value.append(contentsOf: nextValue())
    }
}

// ДОБАВЛЯЕМ новую структуру для хранения позиций часовых меток
struct HourLabelPosition: Equatable {
    let hour: Int
    let yPosition: CGFloat
    
    static func == (lhs: HourLabelPosition, rhs: HourLabelPosition) -> Bool {
        return lhs.hour == rhs.hour && abs(lhs.yPosition - rhs.yPosition) < 0.1
    }
}

// ДОБАВЛЯЕМ PreferenceKey для передачи позиций часовых меток
struct HourLabelPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [HourLabelPosition] = []
    
    static func reduce(value: inout [HourLabelPosition], nextValue: () -> [HourLabelPosition]) {
        value.append(contentsOf: nextValue())
    }
}

// ДОБАВЛЯЕМ структуру для хранения позиций блоков категорий
struct CategoryBlockPosition: Equatable {
    let categoryId: UUID
    let startTime: Date
    let endTime: Date
    let yPosition: CGFloat
    let height: CGFloat
    
    static func == (lhs: CategoryBlockPosition, rhs: CategoryBlockPosition) -> Bool {
        return lhs.categoryId == rhs.categoryId &&
               lhs.startTime == rhs.startTime &&
               lhs.endTime == rhs.endTime &&
               abs(lhs.yPosition - rhs.yPosition) < 0.1 &&
               abs(lhs.height - rhs.height) < 0.1
    }
}

// ДОБАВЛЯЕМ PreferenceKey для передачи позиций блоков категорий
struct CategoryBlockPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [CategoryBlockPosition] = []
    
    static func reduce(value: inout [CategoryBlockPosition], nextValue: () -> [CategoryBlockPosition]) {
        value.append(contentsOf: nextValue())
    }
}

// Абстрагируем логику работы с таймлайном в отдельный класс
class TimelineManager: ObservableObject {
    @Published var currentTime = Date()

    // Используем AnyCancellable вместо Timer для работы с Combine
    private var timerCancellable: AnyCancellable?

    init() {
        // Создаем таймер с интервалом в 1 минуту для обновления времени
        timerCancellable = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
    }

    deinit {
        // Отменяем подписку при уничтожении объекта
        timerCancellable?.cancel()
    }

    // Интеллектуальное определение диапазона задач
    func createTimeBlocks(from tasks: [TaskOnRing], for selectedDate: Date) -> [TimeBlock] {
        let calendar = Calendar.current

        struct TimeRange {
            let start: Int
            let end: Int
            let task: TaskOnRing

            func contains(_ hour: Int) -> Bool {
                if end > start {
                    return hour > start && hour < end
                } else {  // Диапазон через полночь
                    return hour > start || hour < end
                }
            }
        }

        // Кэшируем результаты вычислений
        var taskRanges: [TimeRange] = []
        var tasksByHour: [Int: [TaskOnRing]] = [:]
        var startHours: Set<Int> = []
        var endHours: Set<Int> = []
        var processedTasks = Set<UUID>()
        var processedTasksAt0Hour = Set<UUID>()

        // Анализируем задачи и создаем временные диапазоны
        for task in tasks {
            guard calendar.isDate(task.startTime, inSameDayAs: selectedDate) else {
                continue
            }

            let startHour = calendar.component(.hour, from: task.startTime)
            let startMinute = calendar.component(.minute, from: task.startTime)
            let endHour = calendar.component(.hour, from: task.endTime)
            let endMinute = calendar.component(.minute, from: task.endTime)

            // Интеллектуальная корректировка часа окончания
            let adjustedEndHour: Int
            if endMinute > 0 {
                adjustedEndHour = (endHour + 1) % 24
            } else if startHour == endHour && startMinute == 0 && endMinute == 0 {
                adjustedEndHour = (endHour + 1) % 24
            } else {
                adjustedEndHour = endHour
            }

            if (startHour == 0 || adjustedEndHour == 0) && processedTasks.contains(task.id) {
                continue
            }

            processedTasks.insert(task.id)

            if tasksByHour[startHour] == nil {
                tasksByHour[startHour] = []
            }
            tasksByHour[startHour]?.append(task)

            startHours.insert(startHour)
            endHours.insert(adjustedEndHour)

            taskRanges.append(TimeRange(start: startHour, end: adjustedEndHour, task: task))
        }

        // Создаем блоки времени с интеллектуальной группировкой
        var blocks: [TimeBlock] = []

        for hour in 0...24 {
            let hourMod24 = hour % 24

            var tasksAtHour = tasksByHour[hourMod24] ?? []

            if hour == 24 {
                tasksAtHour = tasksAtHour.filter { !processedTasksAt0Hour.contains($0.id) }
            } else if hourMod24 == 0 {
                processedTasksAt0Hour = Set(tasksAtHour.map { $0.id })
            }

            if tasksAtHour.count > 1 {
                let uniqueTaskIds = Set(tasksAtHour.map { $0.id })
                if uniqueTaskIds.count != tasksAtHour.count {
                    var seenIds = Set<UUID>()
                    tasksAtHour = tasksAtHour.filter { task in
                        if seenIds.contains(task.id) {
                            return false
                        }
                        seenIds.insert(task.id)
                        return true
                    }
                }
            }

            let isInsideTask = taskRanges.contains { $0.contains(hourMod24) }
            let isStartHour = startHours.contains(hourMod24)
            let isEndHour = endHours.contains(hourMod24)
            let isSignificantHour = hour % 3 == 0
            let isImportantHour = hour == 0 || hour == 12 || hour == 24

            // ДОБАВЛЯЕМ ФУНКЦИЮ для проверки промежутков между задачами в одном часе
            let hasGapsInThisHour = hasGapsBetweenTasksInHour(hourMod24, tasks: tasks, calendar: calendar)

            // ОБНОВЛЕННАЯ логика показа меток с учетом промежутков
            let showHourLabel = {
                // Если есть промежутки между задачами в этом часе - НЕ показываем метку
                if hasGapsInThisHour {
                    return false
                }
                
                // Обычная логика для остальных случаев
                return isStartHour || isEndHour ||
                       ((isSignificantHour || isImportantHour) && !isInsideTask &&
                        !endHours.contains((hour + 23) % 24))
            }()

            blocks.append(
                TimeBlock(
                    hour: hour,
                    tasks: tasksAtHour,
                    showHourLabel: showHourLabel,
                    isInsideTask: isInsideTask,
                    isStartHour: isStartHour,
                    isEndHour: isEndHour,
                    isImportantHour: isImportantHour
                )
            )
        }

        return blocks
    }

    // Расчет времени до конца дня
    func calculateTimeUntilEndOfDay(from now: Date = Date()) -> (hours: Int, minutes: Int) {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 59
        components.second = 59

        guard let endOfDay = calendar.date(from: components) else {
            return (0, 0)
        }

        let timeRemaining = endOfDay.timeIntervalSince(now)
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60

        return (hours, minutes)
    }

    // Интеллектуальная группировка задач по категориям
    func groupTasksByCategory(_ tasks: [TaskOnRing]) -> [(key: String, value: [TaskOnRing])] {
        let grouped = Dictionary(grouping: tasks) { $0.category.rawValue }
        return grouped.sorted { $0.key < $1.key }
    }

    // Расчет позиции индикатора текущего времени
    func calculateTimeIndicatorPosition(for date: Date, in height: CGFloat, timeBlocks: [TimeBlock])
        -> CGFloat
    {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)

        // Находим ближайший нижний блок
        let lowerBlock = timeBlocks.filter { $0.hour <= currentHour }.max(by: { $0.hour < $1.hour })
        // Находим ближайший верхний блок
        let upperBlock = timeBlocks.filter { $0.hour > currentHour }.min(by: { $0.hour < $1.hour })

        // Значения по умолчанию
        let lowerHour = lowerBlock?.hour ?? 0
        let upperHour = upperBlock?.hour ?? 24

        // Позиции блоков (пропорционально высоте)
        let lowerPosition = CGFloat(lowerHour) / 24.0 * height
        let upperPosition = CGFloat(upperHour) / 24.0 * height

        // Расстояние между блоками
        let blockDistance = upperPosition - lowerPosition

        // Прогресс между нижним и верхним блоками
        let hourProgress =
            (CGFloat(currentHour - lowerHour) + CGFloat(currentMinute) / 60.0)
            / CGFloat(upperHour - lowerHour)

        // Вычисляем позицию между блоками
        return lowerPosition + blockDistance * hourProgress
    }

    // УЛУЧШЕННАЯ ФУНКЦИЯ ДЛЯ РАСЧЕТА ПОЗИЦИИ НА ОСНОВЕ РЕАЛЬНЫХ ПОЗИЦИЙ БЛОКОВ
    func calculateTimeIndicatorPositionWithBlocks(
        for date: Date, 
        blockPositions: [BlockPosition]
    ) -> CGFloat {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        let currentMinute = calendar.component(.minute, from: date)
        
        // Сортируем позиции блоков по часам
        let sortedPositions = blockPositions.sorted { $0.hour < $1.hour }
        
        // Находим блоки до и после текущего времени
        let lowerBlock = sortedPositions.filter { $0.hour <= currentHour }.last
        let upperBlock = sortedPositions.first { $0.hour > currentHour }
        
        guard let lower = lowerBlock else {
            // Если нет блока до текущего времени, используем первый блок
            return sortedPositions.first?.yPosition ?? 0
        }
        
        guard let upper = upperBlock else {
            // Если нет блока после текущего времени, используем последний блок
            return lower.yPosition + lower.height
        }
        
        // Вычисляем прогресс внутри интервала
        let hourDifference = upper.hour - lower.hour
        let minuteProgress = CGFloat(currentMinute) / 60.0
        let hourProgress = (CGFloat(currentHour - lower.hour) + minuteProgress) / CGFloat(hourDifference)
        
        // Интерполируем позицию между блоками
        let startPosition = lower.yPosition
        let endPosition = upper.yPosition
        let totalDistance = endPosition - startPosition
        
        return startPosition + totalDistance * hourProgress
    }

    // ДОБАВЛЯЕМ ФУНКЦИЮ для проверки промежутков между задачами в одном часе
    private func hasGapsBetweenTasksInHour(_ hour: Int, tasks: [TaskOnRing], calendar: Calendar) -> Bool {
        // Получаем все задачи, которые начинаются или заканчиваются в данном часе
        let tasksInHour = tasks.filter { task in
            let startHour = calendar.component(.hour, from: task.startTime)
            let endHour = calendar.component(.hour, from: task.endTime)
            return startHour == hour || endHour == hour
        }
        
        guard tasksInHour.count > 1 else {
            return false // Если задач меньше 2, промежутков быть не может
        }
        
        // Сортируем задачи по времени начала
        let sortedTasks = tasksInHour.sorted { $0.startTime < $1.startTime }
        
        // Проверяем наличие промежутков между задачами
        for i in 0..<(sortedTasks.count - 1) {
            let currentTask = sortedTasks[i]
            let nextTask = sortedTasks[i + 1]
            
            // Если между концом одной задачи и началом следующей есть промежуток
            if currentTask.endTime < nextTask.startTime {
                let currentEndHour = calendar.component(.hour, from: currentTask.endTime)
                let nextStartHour = calendar.component(.hour, from: nextTask.startTime)
                
                // Если промежуток находится в том же часе
                if currentEndHour == hour && nextStartHour == hour {
                    return true
                }
            }
        }
        
        return false
    }
}

struct TaskTimeline: View {
    @State var selectedDate: Date
    let tasks: [TaskOnRing]
    @ObservedObject var listViewModel: ListViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var calendarState = CalendarState.shared
    let categoryManager: CategoryManagementProtocol

    // Добавляем менеджер таймлайна
    @StateObject private var timelineManager = TimelineManager()
    @StateObject private var clockViewModel = ClockViewModel()

    // ДОБАВЛЯЕМ СЛОВАРЬ ДЛЯ ХРАНЕНИЯ ВЫСОТ БЛОКОВ
    @State private var blockHeights: [String: CGFloat] = [:]

    // Состояние интерфейса
    @State private var showSettings = false
    @State private var showWeekCalendar = false

    // ДОБАВЛЯЕМ СОСТОЯНИЕ ДЛЯ ХРАНЕНИЯ ПОЗИЦИЙ БЛОКОВ
    @State private var blockPositions: [BlockPosition] = []

    // ДОБАВЛЯЕМ СОСТОЯНИЕ ДЛЯ ХРАНЕНИЯ ЧАСОВ БЛОКОВ
    @State private var blockHours: [Int] = []

    // Вычисляемые свойства для фильтрации задач
    private var filteredTasks: [TaskOnRing] {
        tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
            .sorted { $0.startTime < $1.startTime }
    }

    // Кэшируем расчет блоков времени
    private var timeBlocks: [TimeBlock] {
        timelineManager.createTimeBlocks(from: tasks, for: selectedDate)
    }

    // Расчет времени до конца дня
    private var timeUntilEndOfDay: (hours: Int, minutes: Int) {
        timelineManager.calculateTimeUntilEndOfDay(from: timelineManager.currentTime)
    }

    // ДОБАВЛЯЕМ в TaskTimeline состояние для хранения позиций часовых меток
    @State private var hourLabelPositions: [HourLabelPosition] = []

    // ДОБАВЛЯЕМ в TaskTimeline состояние для хранения позиций блоков категорий
    @State private var categoryBlockPositions: [CategoryBlockPosition] = []

    var body: some View {
        ZStack(alignment: .top) {
            // Основное содержимое
            VStack(spacing: 0) {

                if calendarState.isWeekCalendarVisible {
                    Color.clear
                        .frame(height: 70)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if calendarState.isMonthCalendarVisible {
                    Color.clear
                        .frame(height: 300)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 40)
                            .listRowBackground(Color.clear)

                        // Контейнер для временной шкалы и индикатора
                        ZStack(alignment: .leading) {
                            // Базовая временная шкала
                            timelineContentView
                            
                            // Индикатор текущего времени (поверх всего)
                            GeometryReader { geometry in
                                timeIndicatorView(in: geometry)
                            }
                            // .zIndex(1000) // Максимальный приоритет для индикатора
                        }

                        // Информация о конце дня
                        Text(
                            "\("taskTimeLine.endOfDay".localized()) \(timeUntilEndOfDay.hours) \("taskTimeLine.hours".localized()), \(timeUntilEndOfDay.minutes) \("taskTimeLine.minutes".localized())"
                        )
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    }
                }
                .padding(.top, 30)
            }
            .background(
                themeManager.isDarkMode
                    ? Color(red: 0.098, green: 0.098, blue: 0.098)
                    : Color(red: 0.9, green: 0.9, blue: 0.9))

            // Интерфейсные элементы
            VStack {
                VStack {
                    // HeaderView когда календарь скрыт
                    if !showWeekCalendar {
                        HeaderView(
                            viewModel: clockViewModel,
                            showSettingsAction: { showSettings = true },
                            toggleCalendarAction: { toggleWeekCalendar() },
                            isCalendarVisible: showWeekCalendar,
                            searchAction: { /* Логика поиска */  }
                        )
                        .zIndex(100)
                    }

                    // Календарь
                    if showWeekCalendar {
                        WeekCalendarView(
                            selectedDate: $clockViewModel.selectedDate,
                            onHideCalendar: { showWeekCalendar = false }
                        )
                        .zIndex(90)
                    }

                    Spacer()

                    // // Нижняя панель
                    // TimelineBar(
                    //     onTodayTap: {
                    //         let today = Date()
                    //         clockViewModel.selectedDate = today
                    //         selectedDate = today
                    //     },
                    //     onAddTaskTap: {
                    //         NotificationCenter.default.post(
                    //             name: NSNotification.Name("ShowAddTaskForm"),
                    //             object: nil
                    //         )
                    //     },
                    //     onInfoTap: { showSettings = true }
                    // )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showWeekCalendar)
        .gesture(
            DragGesture()
                .onChanged { _ in }
                .onEnded { value in
                    if value.translation.width > 100 {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CloseTaskTimeline"),
                            object: nil
                        )
                    }
                }
        )
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            self.timelineManager.currentTime = Date()
        }
        .fullScreenCover(isPresented: $showSettings) {
            NavigationStack {
                PersonalizationViewIOS(viewModel: clockViewModel)
            }
        }
        .onAppear {
            clockViewModel.selectedDate = selectedDate
            listViewModel.handle(.loadTasks(Date()))
        }
        .onChange(of: clockViewModel.selectedDate) { newValue in
            selectedDate = newValue
        }
    }

    // ОБНОВЛЯЕМ ГЛАВНЫЙ МЕТОД расчета позиции с учетом всех трех кейсов
    private func calculateTimeIndicatorPositionFromHourLabels(
        currentHour: Int,
        currentMinute: Int,
        hourLabelPositions: [HourLabelPosition],
        totalHeight: CGFloat
    ) -> CGFloat {
        let currentTime = timelineManager.currentTime
        
        // ВЫЗЫВАЕМ ОТЛАДКУ ТОЛЬКО КОГДА НУЖНО (можно закомментировать)
        // debugIntermediatePositions(currentTime)
        
        // ПРОВЕРЯЕМ, находится ли текущее время в зоне категории (кейс 2)
        if let categoryBlock = findCategoryBlockForCurrentTime(currentTime) {
            return calculatePositionWithinCategoryBlock(currentTime: currentTime, categoryBlock: categoryBlock)
        }
        
        // НОВАЯ ЛОГИКА: проверяем промежуточные зоны (кейс 3)
        if let intermediatePosition = calculateIntermediatePosition(
            currentTime: currentTime,
            currentHour: currentHour,
            currentMinute: currentMinute,
            hourLabelPositions: hourLabelPositions
        ) {
            return intermediatePosition
        }
        
        // Кейс 1: используем существующую логику с временными метками
        return calculatePositionFromHourLabels(
            currentHour: currentHour,
            currentMinute: currentMinute,
            hourLabelPositions: hourLabelPositions,
            totalHeight: totalHeight
        )
    }

    // ИСПРАВЛЯЕМ ФУНКЦИЮ для поиска блока категории (убираем print из View контекста)
    private func findCategoryBlockForCurrentTime(_ currentTime: Date) -> CategoryBlockPosition? {
        return categoryBlockPositions.first { block in
            // ИСПРАВЛЯЕМ ЛОГИКУ: время должно быть строго внутри интервала
            return currentTime >= block.startTime && currentTime < block.endTime
        }
    }

    // ФУНКЦИЯ для расчета позиции внутри блока категории
    private func calculatePositionWithinCategoryBlock(
        currentTime: Date, 
        categoryBlock: CategoryBlockPosition
    ) -> CGFloat {
        let totalDuration = categoryBlock.endTime.timeIntervalSince(categoryBlock.startTime)
        let elapsedDuration = currentTime.timeIntervalSince(categoryBlock.startTime)
        
        // Избегаем деления на ноль
        guard totalDuration > 0 else {
            return categoryBlock.yPosition
        }
        
        let progress = CGFloat(elapsedDuration / totalDuration)
        
        // Ограничиваем прогресс от 0 до 1
        let clampedProgress = max(0, min(1, progress))
        
        return categoryBlock.yPosition + (categoryBlock.height * clampedProgress)
    }

    // ВЫДЕЛЯЕМ ЛОГИКУ расчета по временным меткам в отдельную функцию
    private func calculatePositionFromHourLabels(
        currentHour: Int,
        currentMinute: Int,
        hourLabelPositions: [HourLabelPosition],
        totalHeight: CGFloat
    ) -> CGFloat {
        guard !hourLabelPositions.isEmpty else {
            // Fallback к пропорциональному расчету
            let progress = (CGFloat(currentHour) + CGFloat(currentMinute) / 60.0) / 24.0
            return totalHeight * progress
        }
        
        // Сортируем позиции меток по часам
        let sortedLabels = hourLabelPositions.sorted { $0.hour < $1.hour }
        
        // Ищем точное совпадение по часу
        if let exactLabel = sortedLabels.first(where: { $0.hour == currentHour }) {
            // Ищем следующую метку для интерполяции
            if let nextLabel = sortedLabels.first(where: { $0.hour > currentHour }) {
                let minuteProgress = CGFloat(currentMinute) / 60.0
                let positionDifference = nextLabel.yPosition - exactLabel.yPosition
                return exactLabel.yPosition + (positionDifference * minuteProgress)
            } else {
                // Если нет следующей метки, используем среднее расстояние
                let averageDistance = calculateAverageDistanceBetweenLabels(sortedLabels)
                let minuteProgress = CGFloat(currentMinute) / 60.0
                return exactLabel.yPosition + (averageDistance * minuteProgress)
            }
        }
        
        // Ищем ближайшие метки до и после текущего времени
        let lowerLabel = sortedLabels.filter { $0.hour < currentHour }.last
        let upperLabel = sortedLabels.first { $0.hour > currentHour }
        
        // Если есть метки до и после текущего времени
        if let lower = lowerLabel, let upper = upperLabel {
            let hourDifference = upper.hour - lower.hour
            let minuteProgress = CGFloat(currentMinute) / 60.0
            let hourProgress = (CGFloat(currentHour - lower.hour) + minuteProgress) / CGFloat(hourDifference)
            
            // Линейная интерполяция между метками
            let positionDifference = upper.yPosition - lower.yPosition
            return lower.yPosition + (positionDifference * hourProgress)
        }
        
        // Если есть только нижняя метка (время после последней метки)
        if let lower = lowerLabel, upperLabel == nil {
            let averageDistance = calculateAverageDistanceBetweenLabels(sortedLabels)
            let hoursAfterLastLabel = currentHour - lower.hour
            let minuteProgress = CGFloat(currentMinute) / 60.0
            let timeProgress = CGFloat(hoursAfterLastLabel) + minuteProgress
            
            return lower.yPosition + (averageDistance * timeProgress)
        }
        
        // Если есть только верхняя метка (время до первой метки)
        if let upper = upperLabel, lowerLabel == nil {
            let averageDistance = calculateAverageDistanceBetweenLabels(sortedLabels)
            let hoursBeforeFirstLabel = upper.hour - currentHour
            let minuteProgress = CGFloat(currentMinute) / 60.0
            let timeProgress = CGFloat(hoursBeforeFirstLabel) - minuteProgress
            
            return upper.yPosition - (averageDistance * timeProgress)
        }
        
        // Fallback
        let progress = (CGFloat(currentHour) + CGFloat(currentMinute) / 60.0) / 24.0
        return totalHeight * progress
    }

    // ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ для расчета среднего расстояния между метками
    private func calculateAverageDistanceBetweenLabels(_ labels: [HourLabelPosition]) -> CGFloat {
        guard labels.count > 1 else { return 60.0 } // Значение по умолчанию
        
        var totalDistance: CGFloat = 0
        var count = 0
        
        for i in 0..<(labels.count - 1) {
            let distance = labels[i + 1].yPosition - labels[i].yPosition
            let hourDiff = labels[i + 1].hour - labels[i].hour
            if hourDiff > 0 {
                totalDistance += distance / CGFloat(hourDiff) // Расстояние на час
                count += 1
            }
        }
        
        return count > 0 ? totalDistance / CGFloat(count) : 60.0
    }

    // ОБНОВЛЯЕМ timeIndicatorView для использования нового метода
    private func timeIndicatorView(in geometry: GeometryProxy) -> AnyView {
        let isToday = Calendar.current.isDateInToday(selectedDate)

        if isToday {
            let currentHour = Calendar.current.component(.hour, from: timelineManager.currentTime)
            let currentMinute = Calendar.current.component(.minute, from: timelineManager.currentTime)
            
            // Используем новый точный расчет на основе позиций часовых меток
            let yPosition = calculateTimeIndicatorPositionFromHourLabels(
                currentHour: currentHour,
                currentMinute: currentMinute,
                hourLabelPositions: hourLabelPositions,
                totalHeight: geometry.size.height
            )

            return AnyView(
                HStack(alignment: .center, spacing: 0) {
                    // Метка времени
                    Text(formatTime(timelineManager.currentTime))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThickMaterial)
                                .stroke(
                                    LinearGradient(
                                        colors: [.red.opacity(0.5), .red.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: 50, height: 22)
                                .shadow(color: Color.red.opacity(0.15), radius: 5, x: 0, y: 2)
                        )

                    // Линия времени
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.red.opacity(0.8), .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                        .padding(.leading, 7)
                }
                .offset(y: yPosition - 11)
                .padding(.leading, 16)
                .zIndex(10)
            )
        } else {
            return AnyView(Color.clear.frame(height: 0))
        }
    }

    // ОБНОВЛЯЕМ timelineContentView для сбора позиций блоков категорий
    private var timelineContentView: some View {
        ZStack(alignment: .leading) {
            // Вертикальная линия с иконками
            timelineAxisView

            // Расположение всего содержимого
            VStack(spacing: 0) {
                // Отступ для иконки солнца
                Spacer().frame(height: 20)

                // Блоки времени с задачами
                ForEach(timeBlocks) { block in
                    timeBlockView(for: block)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(
                                        key: BlockPositionPreferenceKey.self,
                                        value: [BlockPosition(
                                            hour: block.hour,
                                            yPosition: geometry.frame(in: .named("timelineContainer")).minY,
                                            height: geometry.size.height
                                        )]
                                    )
                                    .preference(
                                        key: BlockHourPreferenceKey.self,
                                        value: [block.hour]
                                    )
                            }
                        )
                }

                // Отступ для иконки луны
                Spacer().frame(height: 20)
            }
            .padding(.leading, 12)
        }
        .padding(.leading, 8)
        .coordinateSpace(name: "timelineContainer")
        .onPreferenceChange(BlockPositionPreferenceKey.self) { positions in
            self.blockPositions = positions
        }
        .onPreferenceChange(BlockHourPreferenceKey.self) { hours in
            self.blockHours = hours
        }
        .onPreferenceChange(HourLabelPositionPreferenceKey.self) { positions in
            self.hourLabelPositions = positions
        }
        .onPreferenceChange(CategoryBlockPositionPreferenceKey.self) { positions in
            self.categoryBlockPositions = positions
        }
    }

    // Ось времени с иконками
    private var timelineAxisView: some View {
        VStack(spacing: 0) {
            // Иконка солнца
            ZStack {
                Rectangle()
                    .fill(
                        themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.3)
                    )
                    .frame(width: 1, height: 0)

                Circle()
                    .fill(
                        themeManager.isDarkMode ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
                    )
                    .frame(width: 30, height: 30)
                    .zIndex(1)

                Image(systemName: "sun.max")
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .font(.system(size: 16))
                    .zIndex(2)
            }

            // Линия
            Rectangle()
                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.3))
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            // Иконка луны
            ZStack {
                Circle()
                    .fill(
                        themeManager.isDarkMode ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
                    )
                    .frame(width: 30, height: 30)
                    .zIndex(1)

                Image(systemName: "moon")
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .font(.system(size: 16))
                    .zIndex(2)

                Rectangle()
                    .fill(
                        themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.3)
                    )
                    .frame(width: 1, height: 0)
            }
        }
        .padding(.leading, 11)
    }

    // ОБНОВЛЯЕМ timeBlockView с увеличенными отступами
    private func timeBlockView(for timeBlock: TimeBlock) -> some View {
        VStack(spacing: 0) {
            // Метка часа (если нужно показать)
            if timeBlock.showHourLabel {
                ZStack {
                    Text(timeBlock.hour == 24 ? "00" : String(format: "%02d", timeBlock.hour % 24))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(
                            themeManager.isDarkMode ? .gray.opacity(0.3) : .black.opacity(0.3)
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 45)
                        .padding(.top, 10)
                        .background(
                            GeometryReader { labelGeometry in
                                Color.clear
                                    .preference(
                                        key: HourLabelPositionPreferenceKey.self,
                                        value: [HourLabelPosition(
                                            hour: timeBlock.hour,
                                            yPosition: labelGeometry.frame(in: .named("timelineContainer")).midY
                                        )]
                                    )
                            }
                        )
                }
            }

            // ЛЕВЫЕ ИНДИКАТОРЫ С ДИНАМИЧЕСКОЙ ВЫСОТОЙ И УВЕЛИЧЕННЫМИ ОТСТУПАМИ
            if !timeBlock.tasks.isEmpty {
                VStack(spacing: 25) { // УВЕЛИЧИВАЕМ отступ с 15 до 25
                    ForEach(timelineManager.groupTasksByCategory(timeBlock.tasks), id: \.key) {
                        category, tasksInCategory in
                        if let firstTask = tasksInCategory.first {
                            // СОЗДАЕМ УНИКАЛЬНЫЙ ID ДЛЯ ВРЕМЕННОГО СЛОТА
                            let slotId = createSlotId(
                                categoryId: firstTask.category.id,
                                startTime: getEarliestStartTime(for: tasksInCategory),
                                endTime: getLatestEndTime(for: tasksInCategory),
                                date: selectedDate
                            )
                            
                            // ПОЛУЧАЕМ ВЫСОТУ БЛОКА
                            let blockHeight = blockHeights[slotId] ?? 60.0
                            
                            // ПРАВИЛЬНО ОПРЕДЕЛЯЕМ ВРЕМЕНА БЛОКА
                            let blockStartTime = getEarliestStartTime(for: tasksInCategory)
                            let blockEndTime = getLatestEndTime(for: tasksInCategory)
                            
                            HStack(alignment: .top, spacing: 0) {
                                // Левый индикатор с динамической высотой
                                ZStack {
                                    Rectangle()
                                        .fill(firstTask.category.color)
                                        .frame(width: 30, height: blockHeight)
                                        .cornerRadius(10)
                                    
                                    VStack {
                                        Spacer()

                                        Image(systemName: firstTask.icon)
                                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                            .font(.system(size: 14))
                                        
                                        Spacer()
                                    }
                
                                }
                                .shadow(color: Color.black.opacity(0.25), radius: 5, x: 0, y: 2)
                                
                                // Правый блок с измерением высоты
                                let allCategoryTasks = filteredTasks.filter { $0.category.id == firstTask.category.id }
                                
                                TasksFromView(
                                    listViewModel: listViewModel,
                                    selectedDate: selectedDate,
                                    categoryManager: categoryManager,
                                    selectedCategoryID: firstTask.category.id,
                                    startTime: blockStartTime,
                                    endTime: blockEndTime,
                                    allTimelineTasksForCategory: allCategoryTasks,
                                    slotId: slotId
                                )
                                .padding(.horizontal, 11)
                                .background(
                                    GeometryReader { geometry in
                                        Color.clear
                                            .preference(
                                                key: BlockHeightPreferenceKey.self,
                                                value: [slotId: geometry.size.height]
                                            )
                                            .preference(
                                                key: CategoryBlockPositionPreferenceKey.self,
                                                value: [CategoryBlockPosition(
                                                    categoryId: firstTask.category.id,
                                                    startTime: blockStartTime,
                                                    endTime: blockEndTime,
                                                    yPosition: geometry.frame(in: .named("timelineContainer")).minY,
                                                    height: geometry.size.height
                                                )]
                                            )
                                    }
                                )
                            }
                            .padding(.bottom, 8) // ДОБАВЛЯЕМ дополнительный отступ снизу для каждого блока
                        }
                    }
                }
                .padding(.top, 8) // ДОБАВЛЯЕМ отступ сверху для группы блоков
            }
        }
        .onPreferenceChange(BlockHeightPreferenceKey.self) { heights in
            // ОБНОВЛЯЕМ ВЫСОТЫ БЛОКОВ
            for (id, height) in heights {
                blockHeights[id] = height
            }
        }
    }
    
    // ФУНКЦИЯ ДЛЯ СОЗДАНИЯ УНИКАЛЬНОГО ID СЛОТА
    private func createSlotId(categoryId: UUID, startTime: Date, endTime: Date, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm"
        let dateString = formatter.string(from: date)
        let startString = formatter.string(from: startTime)
        let endString = formatter.string(from: endTime)
        
        return "\(categoryId)-\(dateString)-\(startString)-\(endString)"
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func getEarliestStartTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.min { $0.startTime < $1.startTime }?.startTime ?? Date()
    }

    private func getLatestEndTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.max { $0.endTime < $1.endTime }?.endTime ?? Date()
    }

    // Переключение календаря
    private func toggleWeekCalendar() {
        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7).delay(0.01)) {
            showWeekCalendar.toggle()
        }
    }

    // ДОПОЛНИТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ ОТЛАДКИ (МОЖНО УБРАТЬ ПОЗЖЕ)
    private func debugBlockPositions() {
        print("=== Debug Block Positions ===")
        for position in blockPositions.sorted(by: { $0.hour < $1.hour }) {
            print("Hour: \(position.hour), Y: \(position.yPosition), Height: \(position.height)")
        }
        print("Block Hours: \(blockHours.sorted())")
        print("=============================")
    }

    // ДОБАВЛЯЕМ ОТДЕЛЬНУЮ ФУНКЦИЮ ДЛЯ ОТЛАДКИ (вызываем только при необходимости)
    private func debugCategoryBlocks(_ currentTime: Date) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        print("=== DEBUG: Поиск блока категории для времени \(formatter.string(from: currentTime)) ===")
        
        for block in categoryBlockPositions {
            print("Блок категории: \(formatter.string(from: block.startTime)) - \(formatter.string(from: block.endTime))")
            print("Проверка: \(currentTime) >= \(block.startTime) && \(currentTime) < \(block.endTime)")
            print("Результат: \(currentTime >= block.startTime && currentTime < block.endTime)")
        }
        
        let result = findCategoryBlockForCurrentTime(currentTime)
        if let foundBlock = result {
            print("Найден блок: \(formatter.string(from: foundBlock.startTime)) - \(formatter.string(from: foundBlock.endTime))")
        } else {
            print("Блок не найден - используем временные метки")
        }
        print("===============================")
    }

    // НОВАЯ ФУНКЦИЯ для расчета промежуточных позиций (кейс 3)
    private func calculateIntermediatePosition(
        currentTime: Date,
        currentHour: Int,
        currentMinute: Int,
        hourLabelPositions: [HourLabelPosition]
    ) -> CGFloat? {
        
        // Находим все блоки категорий для текущего часа
        let categoryBlocksInCurrentHour = categoryBlockPositions.filter { block in
            let calendar = Calendar.current
            let blockStartHour = calendar.component(.hour, from: block.startTime)
            let blockEndHour = calendar.component(.hour, from: block.endTime)
            
            // Блок может начинаться в текущем часе или заканчиваться в нем
            return blockStartHour == currentHour || blockEndHour == currentHour ||
                   (blockStartHour < currentHour && blockEndHour > currentHour)
        }
        
        guard !categoryBlocksInCurrentHour.isEmpty else {
            return nil // Нет блоков категорий для текущего часа
        }
        
        // Сортируем блоки по времени начала
        let sortedBlocks = categoryBlocksInCurrentHour.sorted { $0.startTime < $1.startTime }
        
        // Находим позицию временной метки для текущего часа
        guard let currentHourLabel = hourLabelPositions.first(where: { $0.hour == currentHour }) else {
            return nil
        }
        
        // Находим следующую временную метку
        let nextHourLabel = hourLabelPositions.first { $0.hour > currentHour }
        
        // Кейс 3.1: Время ДО начала первого блока категории
        if let firstBlock = sortedBlocks.first, currentTime < firstBlock.startTime {
            let calendar = Calendar.current
            let blockStartHour = calendar.component(.hour, from: firstBlock.startTime)
            let blockStartMinute = calendar.component(.minute, from: firstBlock.startTime)
            
            if blockStartHour == currentHour {
                // Блок начинается в том же часе - интерполируем между началом часа и началом блока
                let totalMinutesInSegment = CGFloat(blockStartMinute)
                let currentMinutesInSegment = CGFloat(currentMinute)
                
                guard totalMinutesInSegment > 0 else { return currentHourLabel.yPosition }
                
                let progress = currentMinutesInSegment / totalMinutesInSegment
                let segmentHeight = firstBlock.yPosition - currentHourLabel.yPosition
                
                return currentHourLabel.yPosition + (segmentHeight * progress)
            }
        }
        
        // Кейс 3.2: Время ПОСЛЕ конца последнего блока категории
        if let lastBlock = sortedBlocks.last, currentTime > lastBlock.endTime {
            let calendar = Calendar.current
            let blockEndHour = calendar.component(.hour, from: lastBlock.endTime)
            let blockEndMinute = calendar.component(.minute, from: lastBlock.endTime)
            
            if blockEndHour == currentHour {
                // Блок заканчивается в том же часе
                let blockEndPosition = lastBlock.yPosition + lastBlock.height
                
                if let nextLabel = nextHourLabel {
                    // Интерполируем между концом блока и следующей временной меткой
                    let totalMinutesInSegment = CGFloat(60 - blockEndMinute)
                    let currentMinutesInSegment = CGFloat(currentMinute - blockEndMinute)
                    
                    guard totalMinutesInSegment > 0 && currentMinutesInSegment >= 0 else {
                        return blockEndPosition
                    }
                    
                    let progress = currentMinutesInSegment / totalMinutesInSegment
                    let segmentHeight = nextLabel.yPosition - blockEndPosition
                    
                    return blockEndPosition + (segmentHeight * progress)
                } else {
                    // Нет следующей метки - используем среднее расстояние
                    let averageDistance = calculateAverageDistanceBetweenLabels(hourLabelPositions)
                    let totalMinutesInSegment = CGFloat(60 - blockEndMinute)
                    let currentMinutesInSegment = CGFloat(currentMinute - blockEndMinute)
                    
                    guard totalMinutesInSegment > 0 && currentMinutesInSegment >= 0 else {
                        return blockEndPosition
                    }
                    
                    let progress = currentMinutesInSegment / totalMinutesInSegment
                    
                    return blockEndPosition + (averageDistance * progress)
                }
            }
        }
        
        // Кейс 3.3: Время между блоками категорий в одном часе
        for i in 0..<(sortedBlocks.count - 1) {
            let currentBlock = sortedBlocks[i]
            let nextBlock = sortedBlocks[i + 1]
            
            if currentTime > currentBlock.endTime && currentTime < nextBlock.startTime {
                let calendar = Calendar.current
                let currentBlockEndMinute = calendar.component(.minute, from: currentBlock.endTime)
                let nextBlockStartMinute = calendar.component(.minute, from: nextBlock.startTime)
                
                let currentBlockEndPosition = currentBlock.yPosition + currentBlock.height
                let nextBlockStartPosition = nextBlock.yPosition
                
                let totalMinutesInSegment = CGFloat(nextBlockStartMinute - currentBlockEndMinute)
                let currentMinutesInSegment = CGFloat(currentMinute - currentBlockEndMinute)
                
                guard totalMinutesInSegment > 0 && currentMinutesInSegment >= 0 else {
                    return currentBlockEndPosition
                }
                
                let progress = currentMinutesInSegment / totalMinutesInSegment
                let segmentHeight = nextBlockStartPosition - currentBlockEndPosition
                
                return currentBlockEndPosition + (segmentHeight * progress)
            }
        }
        
        return nil // Не попадает ни в один промежуточный кейс
    }

    // ДОБАВЛЯЕМ ОТЛАДОЧНУЮ ФУНКЦИЮ для лучшего понимания логики
    private func debugIntermediatePositions(_ currentTime: Date) {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        
        print("=== DEBUG: Промежуточные позиции для \(formatter.string(from: currentTime)) ===")
        print("Текущий час: \(currentHour), минута: \(currentMinute)")
        
        let categoryBlocksInCurrentHour = categoryBlockPositions.filter { block in
            let blockStartHour = calendar.component(.hour, from: block.startTime)
            let blockEndHour = calendar.component(.hour, from: block.endTime)
            return blockStartHour == currentHour || blockEndHour == currentHour ||
                   (blockStartHour < currentHour && blockEndHour > currentHour)
        }
        
        print("Блоки категорий в текущем часе: \(categoryBlocksInCurrentHour.count)")
        for block in categoryBlocksInCurrentHour.sorted(by: { $0.startTime < $1.startTime }) {
            print("  \(formatter.string(from: block.startTime)) - \(formatter.string(from: block.endTime))")
        }
        
        if let result = calculateIntermediatePosition(
            currentTime: currentTime,
            currentHour: currentHour,
            currentMinute: currentMinute,
            hourLabelPositions: hourLabelPositions
        ) {
            print("Найдена промежуточная позиция: \(result)")
        } else {
            print("Промежуточная позиция не найдена")
        }
        print("==============================================")
    }
}

// ДОБАВЛЯЕМ PreferenceKey ДЛЯ ПЕРЕДАЧИ ВЫСОТ
struct BlockHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}
