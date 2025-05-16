//
//  TimelineView.swift
//  TaskFl0w
//
//  Created by Yan on 1/5/25.
//

import SwiftUI
import Combine

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
                } else { // Диапазон через полночь
                    return hour > start || hour < end
                }
            }
        }
        
        // Кэшируем результаты вычислений
        var taskRanges: [TimeRange] = []
        var tasksByHour: [Int: [TaskOnRing]] = [:]
        var startHours: Set<Int> = []
        var endHours: Set<Int> = []
        var processedTasks = Set<UUID>() // Добавляем множество для отслеживания обработанных задач
        var processedTasksAt0Hour = Set<UUID>() // Добавляем отслеживание задач для 0-го часа
        
        // Анализируем задачи и создаем временные диапазоны
        for task in tasks {
            // Убедимся, что задача действительно на этот день
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
                adjustedEndHour = (endHour + 1) % 24  // Увеличиваем на 1, если есть минуты
            } else if startHour == endHour && startMinute == 0 && endMinute == 0 {
                adjustedEndHour = (endHour + 1) % 24
            } else {
                adjustedEndHour = endHour
            }
            
            // Аккуратно обрабатываем граничные случаи с 0 часами
            // Если задача начинается в 0 часов и она уже была обработана для 24 часов (или наоборот)
            // то пропускаем её, чтобы избежать дублирования
            if (startHour == 0 || adjustedEndHour == 0) && processedTasks.contains(task.id) {
                continue
            }
            
            // Отмечаем задачу как обработанную
            processedTasks.insert(task.id)
            
            // Добавляем задачу в соответствующий час
            if tasksByHour[startHour] == nil {
                tasksByHour[startHour] = []
            }
            tasksByHour[startHour]?.append(task)
            
            startHours.insert(startHour)
            endHours.insert(adjustedEndHour)
            
            // Создаем диапазон для задачи
            taskRanges.append(TimeRange(start: startHour, end: adjustedEndHour, task: task))
        }
        
        // Создаем блоки времени с интеллектуальной группировкой
        var blocks: [TimeBlock] = []
        
        // Показываем полные сутки и еще час для наглядности
        for hour in 0...24 {
            let hourMod24 = hour % 24
            
            // Получаем задачи для текущего часа
            var tasksAtHour = tasksByHour[hourMod24] ?? []
            
            // Специальная обработка для 24-го часа (полночь следующего дня)
            if hour == 24 {
                // Фильтруем задачи, исключая те, которые уже были в 0-м часу
                tasksAtHour = tasksAtHour.filter { !processedTasksAt0Hour.contains($0.id) }
            } else if hourMod24 == 0 {
                // Запоминаем ID задач 0-го часа для исключения их при обработке 24-го часа
                processedTasksAt0Hour = Set(tasksAtHour.map { $0.id })
            }
            
            // Если это 0-й или другие часы, проверяем на дубликаты внутри текущего блока
            if tasksAtHour.count > 1 {
                // Фильтруем дубликаты внутри текущего блока
                let uniqueTaskIds = Set(tasksAtHour.map { $0.id })
                if uniqueTaskIds.count != tasksAtHour.count {
                    // Оставляем только уникальные задачи
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
            
            // Определяем статус часа для визуализации
            let isInsideTask = taskRanges.contains { $0.contains(hourMod24) }
            let isStartHour = startHours.contains(hourMod24)
            let isEndHour = endHours.contains(hourMod24)
            let isSignificantHour = hour % 3 == 0 // Каждый третий час
            let isImportantHour = hour == 0 || hour == 12 || hour == 24 // Полночь и полдень
            
            // Интеллектуальный алгоритм показа меток
            let showHourLabel = isStartHour || isEndHour || 
                               ((isSignificantHour || isImportantHour) && !isInsideTask && !endHours.contains((hour+23) % 24))
            
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
    func calculateTimeIndicatorPosition(for date: Date, in height: CGFloat, timeBlocks: [TimeBlock]) -> CGFloat {
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
        let hourProgress = (CGFloat(currentHour - lowerHour) + CGFloat(currentMinute) / 60.0) / CGFloat(upperHour - lowerHour)
        
        // Вычисляем позицию между блоками
        return lowerPosition + blockDistance * hourProgress
    }
}

struct TaskTimeline: View {
    @State var selectedDate: Date
    let tasks: [TaskOnRing]
    @ObservedObject var listViewModel: ListViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let categoryManager: CategoryManagementProtocol
    
    // Добавляем менеджер таймлайна
    @StateObject private var timelineManager = TimelineManager()
    @StateObject private var clockViewModel = ClockViewModel()
    
    // Состояние интерфейса
    @State private var showSettings = false
    @State private var showWeekCalendar = false

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
    
    var body: some View {
        ZStack(alignment: .top) {
            // Основное содержимое
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 40)
                            .listRowBackground(Color.clear)
                            
                        // Контейнер для временной шкалы и индикатора
                        ZStack(alignment: .leading) {
                            // Индикатор текущего времени
                            GeometryReader { geometry in
                                timeIndicatorView(in: geometry)
                            }
                            
                            // Базовая временная шкала
                            timelineContentView
                        }

                        // Информация о конце дня
                        Text("End of day: \(timeUntilEndOfDay.hours) hrs, \(timeUntilEndOfDay.minutes) min")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                    }
                    .padding(.horizontal, 15)
                }
                .padding(.top, 30)
            }
            .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.9, green: 0.9, blue: 0.9))
            
            // Интерфейсные элементы
            VStack {
                VStack {
                    // TopBarView когда календарь скрыт
                    if !showWeekCalendar {
                        TopBarView(
                            viewModel: clockViewModel,
                            showSettingsAction: { showSettings = true },
                            toggleCalendarAction: toggleWeekCalendar,
                            isCalendarVisible: false,
                            searchAction: { /* Логика поиска */ }
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
            listViewModel.refreshData()
        }
        .onChange(of: clockViewModel.selectedDate) { newValue in
            selectedDate = newValue
        }
    }

    // Визуализация индикатора текущего времени
    private func timeIndicatorView(in geometry: GeometryProxy) -> AnyView {
        let isToday = Calendar.current.isDateInToday(selectedDate)
        
        if isToday {
            let yPosition = timelineManager.calculateTimeIndicatorPosition(
                for: timelineManager.currentTime,
                in: geometry.size.height,
                timeBlocks: timeBlocks
            )
            
            return AnyView(
                HStack(alignment: .center, spacing: 4) {
                    // Метка времени
                    Text(formatTime(timelineManager.currentTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.pink)
                    
                    // Линия с индикатором
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.pink)
                            .frame(height: 1.5)
                        
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .offset(y: yPosition - 10)
                .padding(.leading, -15)
            )
        } else {
            return AnyView(Color.clear.frame(height: 0))
        }
    }
    
    // Содержимое временной шкалы
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
                }
                
                // Отступ для иконки луны
                Spacer().frame(height: 20)
            }
            .padding(.leading, 15)
        }
        .padding(.leading, 10)
    }
    
    // Ось времени с иконками
    private var timelineAxisView: some View {
        VStack(spacing: 0) {
            // Иконка солнца
            ZStack {
                Rectangle()
                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.3))
                    .frame(width: 1, height: 0)
                
                Circle()
                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.2) : Color.black.opacity(0.2))
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
                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.2) : Color.black.opacity(0.2))
                    .frame(width: 30, height: 30)
                    .zIndex(1)
                
                Image(systemName: "moon")
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .font(.system(size: 16))
                    .zIndex(2)
                
                Rectangle()
                    .fill(themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.black.opacity(0.3))
                    .frame(width: 1, height: 0)
            }
        }
        .padding(.leading, 15)
    }
    
    // Отображение блока времени
    private func timeBlockView(for timeBlock: TimeBlock) -> some View {
        VStack(spacing: 0) {
            // Метка часа (если нужно показать)
            if timeBlock.showHourLabel {
                ZStack {
                    Text(timeBlock.hour == 24 ? "00" : String(format: "%02d", timeBlock.hour % 24))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(themeManager.isDarkMode ? .gray.opacity(0.3) : .black.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 45)
                        .padding(.top, 10)
                }
            }
            
            // Задачи для этого часа
            if !timeBlock.tasks.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Левая колонка с индикаторами
                    VStack(spacing: 0) {
                        ForEach(timeBlock.tasks, id: \.id) { task in
                            ZStack {
                                Rectangle()
                                    .fill(task.category.color)
                                    .frame(width: 30, height: getTaskHeight(for: task))
                                    .cornerRadius(5)
                                
                                Image(systemName: task.icon)
                                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                    
                    // Правая колонка с задачами по категориям
                    VStack(spacing: 15) {
                        ForEach(timelineManager.groupTasksByCategory(timeBlock.tasks), id: \.key) { category, tasksInCategory in
                            if let firstTask = tasksInCategory.first {
                                TasksFromView(
                                    listViewModel: listViewModel,
                                    selectedDate: selectedDate,
                                    categoryManager: categoryManager,
                                    selectedCategoryID: firstTask.category.id,
                                    startTime: getEarliestStartTime(for: tasksInCategory),
                                    endTime: getLatestEndTime(for: tasksInCategory)
                                )
                            }
                        }
                    }
                    .padding(.leading, 15)
                }
            }
        }
    }
    
    // Переключение календаря
    private func toggleWeekCalendar() {
        withAnimation(Animation.spring(response: 0.3, dampingFraction: 0.7).delay(0.01)) {
            showWeekCalendar.toggle()
        }
    }
    
    // Вспомогательные методы
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    
    private func getTaskHeight(for task: TaskOnRing) -> CGFloat {
        let todoTasks = listViewModel.items.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedDate) && 
            item.categoryID == task.category.id
        }
        
        if todoTasks.isEmpty {
            return 100
        } else {
            let baseHeight: CGFloat = 60
            let taskRowHeight: CGFloat = 45
            let tasksHeight = CGFloat(todoTasks.count) * taskRowHeight
            let padding: CGFloat = 10
            
            return baseHeight + tasksHeight + padding
        }
    }
    
    private func getEarliestStartTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.min { $0.startTime < $1.startTime }?.startTime ?? Date()
    }
    
    private func getLatestEndTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.max { $0.endTime < $1.endTime }?.endTime ?? Date()
    }
}
