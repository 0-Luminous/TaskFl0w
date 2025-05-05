//
//  TimelineView.swift
//  TaskFl0w
//
//  Created by Yan on 1/5/25.
//

import SwiftUI

struct TaskTimeline: View {
    let tasks: [TaskOnRing]
    let selectedDate: Date
    @ObservedObject var listViewModel: ListViewModel
    let categoryManager: CategoryManagementProtocol

    // Добавляем ClockViewModel для TopBarView
    @StateObject private var clockViewModel = ClockViewModel()

    // Состояние для отображения настроек и календаря
    @State private var showSettings = false
    @State private var showWeekCalendar = false

    // Добавляем переменную weekCalendarOffset
    @State private var weekCalendarOffset: CGFloat = -200

    // Вычисляем задачи на выбранную дату, сортированные по времени начала
    private var filteredTasks: [TaskOnRing] {
        tasks.filter { task in
            Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime < $1.startTime }
    }

    // Вычисляем часы, для которых есть задачи
    private var hoursWithTasks: [Int] {
        let calendar = Calendar.current
        let hours = filteredTasks.map { calendar.component(.hour, from: $0.startTime) }
        return Array(Set(hours)).sorted()
    }

    // Текущее время для отображения индикатора
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // Расчет времени до конца дня
    private var timeUntilEndOfDay: (hours: Int, minutes: Int, seconds: Int) {
        let calendar = Calendar.current
        let now = currentTime

        // Получаем конец текущего дня (23:59:59)
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 23
        components.minute = 59
        components.second = 59

        guard let endOfDay = calendar.date(from: components) else {
            return (0, 0, 0)
        }

        let timeRemaining = endOfDay.timeIntervalSince(now)
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60

        return (hours, minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 0) {
            // TopBarView отображается только когда календарь скрыт
            if !showWeekCalendar {
                TopBarView(
                    viewModel: clockViewModel,
                    showSettingsAction: { showSettings = true },
                    toggleCalendarAction: toggleWeekCalendar,
                    isCalendarVisible: false  // Всегда false, чтобы не дублировать календарь
                )
            }
            
            // Отдельный календарь
            if showWeekCalendar {
                WeekCalendarView(selectedDate: $clockViewModel.selectedDate)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .shadow(color: .black.opacity(0.3), radius: 5)
                    )
                    .padding(.horizontal, 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Только если календарь уже показан и свайп вверх
                                if value.translation.height < 0 {
                                    weekCalendarOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                // Если сделан свайп вверх, скрываем календарь
                                if value.translation.height < -20 {
                                    hideWeekCalendar()
                                } else {
                                    // Возвращаем в исходное положение
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        weekCalendarOffset = 0
                                    }
                                }
                            }
                    )
                    .onChange(of: clockViewModel.selectedDate) { _, _ in
                        // Автоматически скрываем календарь после выбора даты
                        if showWeekCalendar {
                            hideWeekCalendar()
                        }
                    }
            }

            ScrollView {
                VStack(spacing: 0) {
                    // Контейнер для временной шкалы и индикатора времени
                    ZStack(alignment: .leading) {
                        // Индикатор текущего времени (теперь ПЕРВЫЙ элемент, чтобы быть НИЖЕ в Z-порядке)
                        GeometryReader { geometry in
                            let totalHeight = geometry.size.height
                            let calendar = Calendar.current
                            let now = currentTime
                            
                            // Получаем общее количество блоков времени и их распределение
                            let timeBlocks = createTimeBlocks()
                            
                            // Определяем высоту одного блока
                            let blockHeight = totalHeight / CGFloat(timeBlocks.count)
                            
                            // Определяем текущий час и минуты
                            let currentHour = calendar.component(.hour, from: now)
                            let currentMinute = calendar.component(.minute, from: now)
                            
                            // Вычисляем, какая часть часа прошла (от 0 до 1)
                            let minuteProgress = CGFloat(currentMinute) / 60.0
                            
                            // Вычисляем положение индикатора на шкале
                            // Расчет позиции на основе самого часа, а не индекса блока
                            // Это позволяет привязать индикатор к правильным значениям часов
                            // Находим общий "прогресс дня" (от 0 до 24 часов с дробной частью)
                            let dayProgress = CGFloat(currentHour) + minuteProgress
                            
                            // Вычисляем позицию как долю от общей высоты (24 часа + 1 для полночи следующего дня)
                            let yPosition = (dayProgress / 25.0) * totalHeight
                            
                            // Только линия и текст слева
                            HStack(alignment: .center, spacing: 2) {
                                // Метка времени слева от линии
                                Text(formatTime(currentTime))
                                    .font(.caption)
                                    .foregroundColor(.pink)
                                
                                // Горизонтальная линия
                                Rectangle()
                                    .fill(Color.pink)
                                    .frame(height: 1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .offset(y: yPosition - 10)  // Вычитаем половину высоты текста для центрирования
                            .padding(.leading, -15)  // Отрицательный padding для максимального смещения влево
                        }
                        
                        // Базовая временная шкала (теперь ВТОРОЙ элемент, чтобы быть ВЫШЕ в Z-порядке)
                        timelineContent
                    }

                    // Информация о конце дня
                    Text(
                        "End of day: \(timeUntilEndOfDay.hours) hrs, \(timeUntilEndOfDay.minutes) min"
                    )
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                }
                .padding(.leading, 20)
                .padding(.trailing, 10)
            }
            .padding(.top, 30)
        }
        .background(Color(red: 0.098, green: 0.098, blue: 0.098))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Обрабатываем только горизонтальное перемещение вправо
                    if value.translation.width > 0 {
                        // Здесь можно добавить анимацию при перетаскивании
                    }
                }
                .onEnded { value in
                    // Если свайп вправо больше 100 пикселей, закрываем TaskTimeline
                    if value.translation.width > 100 {
                        // Отправляем уведомление о необходимости закрыть экран
                        NotificationCenter.default.post(
                            name: NSNotification.Name("CloseTaskTimeline"),
                            object: nil
                        )
                    }
                }
        )
        .onReceive(timer) { _ in
            self.currentTime = Date()
        }
        // Добавляем модальное окно для настроек
        .fullScreenCover(isPresented: $showSettings) {
            NavigationStack {
                PersonalizationViewIOS(viewModel: clockViewModel)
            }
        }
        .onAppear {
            // Устанавливаем selectedDate в ClockViewModel
            clockViewModel.selectedDate = selectedDate
        }
    }

    // Функция для переключения отображения недельного календаря
    private func toggleWeekCalendar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showWeekCalendar.toggle()
            if showWeekCalendar {
                weekCalendarOffset = 0
            } else {
                weekCalendarOffset = -200
            }
        }
    }

    // Функция для скрытия недельного календаря
    private func hideWeekCalendar() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            weekCalendarOffset = -200
            showWeekCalendar = false
        }
    }

    // Основное содержимое временной шкалы (без индикатора времени)
    private var timelineContent: some View {
        ZStack(alignment: .leading) {
            // Вертикальная линия с иконками
            VStack(spacing: 0) {
                // Иконка солнца на линии
                ZStack {
                    // Вертикальная линия сверху
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .frame(height: 0)  // Начинается от солнца

                    // Солнце
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .zIndex(1)

                    Image(systemName: "sun.max")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .zIndex(2)
                }

                // Основная часть вертикальной линии
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)

                // Иконка луны на линии
                ZStack {
                    // Луна
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                        .zIndex(1)

                    Image(systemName: "moon")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .zIndex(2)

                    // Вертикальная линия снизу
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1)
                        .frame(height: 0)  // Заканчивается на луне
                }
            }
            .padding(.leading, 15)

            // Расположение всего содержимого
            VStack(spacing: 0) {
                // Блоки задач с отступами для иконок
                VStack(spacing: 0) {
                    // Отступ для иконки солнца
                    Spacer().frame(height: 20)

                    // Блоки задач
                    ForEach(createTimeBlocks(), id: \.hour) { timeBlock in
                        timeBlockView(for: timeBlock)
                    }

                    // Отступ для иконки луны
                    Spacer().frame(height: 20)
                }
                .padding(.leading, 15)
            }
        }
        .padding(.leading, 10)
    }

    // Отображение блока часа с задачами - переименованный метод для ясности
    private func timeBlockView(for timeBlock: TimeBlock) -> some View {
        VStack(spacing: 0) {
            // Если есть отметка часа, показываем большим текстом
            if timeBlock.showHourLabel {
                ZStack {
                    // Метка часа
                    Text(String(format: "%02d", timeBlock.hour))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 45)
                        .padding(.top, 10)
                }
            }

            // Создаем горизонтальный стек для линии времени и списка задач
            HStack(alignment: .top, spacing: 0) {
                // Левая колонка с индикаторами цвета и иконками
                if !timeBlock.tasks.isEmpty {
                    // Вертикальный стек цветных блоков
                    VStack(spacing: 0) {
                        ForEach(timeBlock.tasks, id: \.id) { task in
                            // Цветной индикатор задачи с иконкой внутри
                            ZStack {
                                Rectangle()
                                    .fill(getCategoryColor(for: task))
                                    .frame(width: 30, height: getTaskHeight(for: task))
                                    .cornerRadius(5)

                                // Иконка категории
                                Image(systemName: task.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }

                // Правая колонка с задачами, сгруппированными по категориям
                VStack(spacing: 15) {
                    // Группируем задачи по категориям и используем CategoryTaskView
                    ForEach(groupTasksByCategory(timeBlock.tasks), id: \.key) {
                        category, tasksInCategory in
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

    // Группировка задач по категориям
    private func groupTasksByCategory(_ tasks: [TaskOnRing]) -> [(key: String, value: [TaskOnRing])]
    {
        let grouped = Dictionary(grouping: tasks) { $0.category.rawValue }
        return grouped.sorted { $0.key < $1.key }
    }

    // Вычисление высоты блока задачи в зависимости от длительности
    private func getTaskHeight(for task: TaskOnRing) -> CGFloat {
        // Получаем задачи из ToDoList для этой категории
        let todoTasks = listViewModel.items.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedDate)
                && item.categoryID == task.category.id
        }

        if todoTasks.isEmpty {
            // Минимальная высота если нет задач (пустой блок с сообщением "Нет задач")
            return 100
        } else {
            // Базовая высота для категории (заголовок, отступы)
            let baseHeight: CGFloat = 60  // Заголовок + отступы

            // Высота одной строки задачи (ToDoTaskRow)
            let taskRowHeight: CGFloat = 45  // Включая содержимое и отступы

            // Общая высота всех задач
            let tasksHeight = CGFloat(todoTasks.count) * taskRowHeight
            
            // Добавляем отступы фона TasksFromView
            let padding: CGFloat = 10 // Отступы сверху и снизу (10 + 10)
            
            return baseHeight + tasksHeight + padding
        }
    }

    // Получение цвета категории задачи (с немного увеличенной яркостью для соответствия дизайну)
    private func getCategoryColor(for task: TaskOnRing) -> Color {
        // Для разных категорий можно настроить разные цвета
        switch task.category.rawValue {
        case "Morning Workout": return .pink
        case "Shower": return .blue
        case "Breakfast": return .orange
        case "Check Email": return .purple
        default: return task.category.color
        }
    }

    // Форматирование времени
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Форматирование продолжительности
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        return "\(minutes) min"
    }

    // Создаем структуры блоков времени для отображения
    private func createTimeBlocks() -> [TimeBlock] {
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.component(.hour, from: now)

        // Группируем задачи по часам
        var tasksByHour: [Int: [TaskOnRing]] = [:]
        // Отдельно отслеживаем часы окончания задач
        var endHours: Set<Int> = []

        // Отслеживаем все занятые диапазоны (чтобы скрыть ненужные метки внутри задач)
        var occupiedRanges: [(start: Int, end: Int)] = []

        for task in filteredTasks {
            let startHour = calendar.component(.hour, from: task.startTime)
            // Вместо endHour берем следующий час, если задача заканчивается не ровно в час
            let endTime = task.endTime
            let endMinute = calendar.component(.minute, from: endTime)
            let endHour = calendar.component(.hour, from: endTime)
            
            // Если задача заканчивается не ровно в час (есть минуты),
            // показываем следующий час вместо текущего
            let adjustedEndHour = endMinute > 0 ? (endHour + 1) % 24 : endHour

            // Добавляем час начала в коллекцию задач
            if tasksByHour[startHour] == nil {
                tasksByHour[startHour] = []
            }
            tasksByHour[startHour]?.append(task)

            // Добавляем скорректированный час окончания в множество часов окончания
            endHours.insert(adjustedEndHour)

            // Добавляем диапазон в занятые часы с скорректированным концом
            if adjustedEndHour > startHour {
                occupiedRanges.append((startHour, adjustedEndHour))
            } else if adjustedEndHour < startHour {  // Задача через полночь
                occupiedRanges.append((startHour, 24))
                occupiedRanges.append((0, adjustedEndHour))
            }
        }

        // Создаем блоки времени
        var blocks: [TimeBlock] = []

        // Берем все часы с 0 до 24
        for hour in 0...24 {
            let tasks = tasksByHour[hour % 24] ?? []
            let hourMod24 = hour % 24

            // Проверяем, находится ли час внутри занятого диапазона
            let isInsideTask = occupiedRanges.contains { range in
                hourMod24 > range.start && hourMod24 < range.end
            }

            // Показываем метку для часа если:
            // 1. В этот час начинается задача
            // 2. Это час окончания задачи
            // 3. Это каждый третий час (для разметки), но только если не внутри задачи
            let showHourLabel =
                !tasks.isEmpty || endHours.contains(hourMod24) || (hour % 3 == 0 && !isInsideTask)

            blocks.append(
                TimeBlock(
                    hour: hour,
                    tasks: tasks,
                    showHourLabel: showHourLabel
                ))
        }

        return blocks
    }

    // Добавляем метод для получения задач из ToDo-списка
    private func getAllTodoTasks() -> [ToDoItem] {
        return listViewModel.items.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: selectedDate)
        }
    }

    // Получаем самое раннее время начала задач в категории
    private func getEarliestStartTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.min { $0.startTime < $1.startTime }?.startTime ?? Date()
    }

    // Получаем самое позднее время окончания задач в категории
    private func getLatestEndTime(for tasks: [TaskOnRing]) -> Date {
        return tasks.max { $0.endTime < $1.endTime }?.endTime ?? Date()
    }
}

// Структура для блока времени
struct TimeBlock {
    let hour: Int
    let tasks: [TaskOnRing]
    let showHourLabel: Bool
}
