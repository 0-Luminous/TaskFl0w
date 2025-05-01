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
            ScrollView {
                VStack(spacing: 0) {
                    // Временная шкала
                    timelineContent
                    
                    // Информация о конце дня
                    Text("End of day: \(timeUntilEndOfDay.hours) hrs, \(timeUntilEndOfDay.minutes) min, \(timeUntilEndOfDay.seconds) secs")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    // Кнопка создания события
                    Button(action: {
                        // Действие для создания нового события
                    }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.caption)
                            Text("Create event")
                                .font(.callout)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                        )
                    }
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal)
            }
        }
        .onReceive(timer) { _ in
            self.currentTime = Date()
        }
    }
    
    // Основное содержимое временной шкалы
    private var timelineContent: some View {
        ZStack(alignment: .leading) {
            // Вертикальная линия
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.leading, 28)
            
            // Содержимое временной шкалы
            VStack(spacing: 0) {
                // Иконка солнца вверху
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "sun.max")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .padding(.bottom, 5)
                
                // Блоки задач по часам
                VStack(spacing: 0) {
                    ForEach(createTimeBlocks(), id: \.hour) { timeBlock in
                        timeBlockView(for: timeBlock)
                    }
                }
                
                // Иконка луны внизу
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "moon")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
                .padding(.top, 5)
            }
            .padding(.leading, 14) // Центрируем на линии
        }
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
                    ForEach(groupTasksByCategory(timeBlock.tasks), id: \.key) { category, tasksInCategory in
                        if let firstTask = tasksInCategory.first {
                            TasksFromToDoListView(
                                listViewModel: listViewModel,
                                selectedDate: selectedDate,
                                categoryManager: categoryManager,
                                selectedCategoryID: firstTask.category.id
                            )
                        }
                    }
                }
                .padding(.leading, 15)
            }
            
            // Если есть индикатор текущего времени
            if timeBlock.showCurrentTime {
                HStack(alignment: .center, spacing: 5) {
                    // Метка времени слева от линии
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    // Горизонтальная линия, показывающая текущее время
                    Rectangle()
                        .fill(Color.pink)
                        .frame(height: 1)
                }
                .padding(.leading, 7)
                .padding(.top, 5)
            }
        }
    }
    
    // Группировка задач по категориям
    private func groupTasksByCategory(_ tasks: [TaskOnRing]) -> [(key: String, value: [TaskOnRing])] {
        let grouped = Dictionary(grouping: tasks) { $0.category.rawValue }
        return grouped.sorted { $0.key < $1.key }
    }
    
    // Вычисление высоты блока задачи в зависимости от длительности
    private func getTaskHeight(for task: TaskOnRing) -> CGFloat {
    // Получаем задачи из ToDoList для этой категории
    let todoTasks = listViewModel.items.filter { item in
        Calendar.current.isDate(item.date, inSameDayAs: selectedDate) && 
        item.categoryID == task.category.id
    }
    
    if todoTasks.isEmpty {
        // Минимальная высота если нет задач (пустой блок с сообщением "Нет задач")
        return 100
    } else {
        // Базовая высота для категории (заголовок, отступы)
        let baseHeight: CGFloat = 60 // Заголовок + отступы
        
        // Высота одной строки задачи (ToDoTaskRow)
        let taskRowHeight: CGFloat = 45 // Включая содержимое и отступы
        
        // Общая высота всех задач
        let tasksHeight = CGFloat(todoTasks.count) * taskRowHeight
        
        return baseHeight + tasksHeight
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
        let now = currentTime
        let currentHour = calendar.component(.hour, from: now)
        
        // Группируем задачи по часам только по времени начала
        var tasksByHour: [Int: [TaskOnRing]] = [:]
        
        for task in filteredTasks {
            let startHour = calendar.component(.hour, from: task.startTime)
            
            // Добавляем задачу только в час её начала
            if tasksByHour[startHour] == nil {
                tasksByHour[startHour] = []
            }
            tasksByHour[startHour]?.append(task)
        }
        
        // Создаем блоки времени
        var blocks: [TimeBlock] = []
        
        // Берем все часы с 0 до 24 (полные сутки с завершающим часом)
        for hour in 0...24 {
            let tasks = tasksByHour[hour % 24] ?? [] // Используем модуль для обработки 24 часа как 0
            let showHourLabel = !tasks.isEmpty || hour % 3 == 0 // Показываем каждые 3 часа или где есть задачи
            let showCurrentTime = hour == currentHour
            
            blocks.append(TimeBlock(
                hour: hour,
                tasks: tasks,
                showHourLabel: showHourLabel,
                showCurrentTime: showCurrentTime
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
}

// Структура для блока времени
struct TimeBlock {
    let hour: Int
    let tasks: [TaskOnRing]
    let showHourLabel: Bool
    let showCurrentTime: Bool
}

struct TaskTimeline_Previews: PreviewProvider {
    static var previews: some View {
        // Создаем примеры задач для предпросмотра
        let calendar = Calendar.current
        let now = Date()
        
        // Создаем категории
        let workoutCategory = TaskCategoryModel(id: UUID(), rawValue: "Morning Workout", iconName: "figure.run", color: .pink)
        let showerCategory = TaskCategoryModel(id: UUID(), rawValue: "Shower", iconName: "drop", color: .blue)
        let breakfastCategory = TaskCategoryModel(id: UUID(), rawValue: "Breakfast", iconName: "cup.and.saucer", color: .orange)
        let emailCategory = TaskCategoryModel(id: UUID(), rawValue: "Check Email", iconName: "envelope", color: .purple)
        
        // Создаем задачи на примерное время
        var workoutStart = calendar.date(bySettingHour: 7, minute: 45, second: 0, of: now)!
        var workoutEnd = calendar.date(bySettingHour: 8, minute: 15, second: 0, of: now)!
        let workoutTask = TaskOnRing(id: UUID(), startTime: workoutStart, endTime: workoutEnd, 
                                    color: .pink, icon: "figure.run", category: workoutCategory, 
                                    isCompleted: true)
        
        var showerStart = calendar.date(bySettingHour: 8, minute: 15, second: 0, of: now)!
        var showerEnd = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!
        let showerTask = TaskOnRing(id: UUID(), startTime: showerStart, endTime: showerEnd,
                                   color: .blue, icon: "drop", category: showerCategory,
                                   isCompleted: false)
        
        var breakfastStart = calendar.date(bySettingHour: 8, minute: 30, second: 0, of: now)!
        var breakfastEnd = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        let breakfastTask = TaskOnRing(id: UUID(), startTime: breakfastStart, endTime: breakfastEnd,
                                      color: .orange, icon: "cup.and.saucer", category: breakfastCategory,
                                      isCompleted: false)
        
        var emailStart = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!
        var emailEnd = calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now)!
        let emailTask = TaskOnRing(id: UUID(), startTime: emailStart, endTime: emailEnd,
                                  color: .purple, icon: "envelope", category: emailCategory,
                                  isCompleted: false)
        
        let exampleTasks = [workoutTask, showerTask, breakfastTask, emailTask]
        
        // Создаем необходимый CategoryManagement для превью
        let context = PersistenceController.shared.container.viewContext
        let categoryManager = CategoryManagement(context: context)
        
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            TaskTimeline(
                tasks: exampleTasks, 
                selectedDate: now,
                listViewModel: ListViewModel(),
                categoryManager: categoryManager
            )
        }
    }
}

