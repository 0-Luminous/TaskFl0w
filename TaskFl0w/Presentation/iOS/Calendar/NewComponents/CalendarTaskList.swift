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
                ForEach(createTimeBlocks(), id: \.hour) { timeBlock in
                    hourBlock(for: timeBlock)
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
    
    // Отображение блока часа с задачами
    private func hourBlock(for timeBlock: TimeBlock) -> some View {
        VStack(spacing: 0) {
            // Если есть отметка часа
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
            
            // Блоки задач для этого часа
            VStack(spacing: 8) {
                ForEach(timeBlock.tasks, id: \.id) { task in
                    taskView(for: task)
                }
            }
            .padding(.leading, 65)
            
            // Если есть индикатор текущего времени
            if timeBlock.showCurrentTime {
                HStack(spacing: 5) {
                    Text(formatTime(currentTime))
                        .font(.caption)
                        .foregroundColor(.pink)
                    
                    Rectangle()
                        .fill(Color.pink)
                        .frame(height: 1)
                }
                .padding(.leading, 7)
            }
        }
    }
    
    // Отображение задачи
    private func taskView(for task: TaskOnRing) -> some View {
        HStack(spacing: 0) {
            // Цветной блок категории слева
            Rectangle()
                .fill(getCategoryColor(for: task))
                .frame(width: 30)
                .cornerRadius(5, corners: [.topLeft, .bottomLeft])
            
            // Основное содержимое задачи
            VStack(alignment: .leading, spacing: 4) {
                if task.isCompleted {
                    // Зачеркнутый текст для выполненных задач
                    Text(task.category.rawValue)
                        .font(.headline)
                        .strikethrough()
                        .foregroundColor(.gray)
                } else {
                    Text(task.category.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text("\(formatTime(task.startTime)) – \(formatTime(task.endTime))\n(\(formatDuration(task.duration)))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Индикатор завершения
            checkboxView(isCompleted: task.isCompleted, color: getCategoryColor(for: task))
                .padding(.trailing, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // Чекбокс для отображения статуса завершения
    private func checkboxView(isCompleted: Bool, color: Color) -> some View {
        ZStack {
            if isCompleted {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 20, height: 20)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color, lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
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
        let currentHour = calendar.component(.hour, from: now)
        
        // Группируем задачи по часам
        var tasksByHour: [Int: [TaskOnRing]] = [:]
        for task in filteredTasks {
            let hour = calendar.component(.hour, from: task.startTime)
            if tasksByHour[hour] == nil {
                tasksByHour[hour] = []
            }
            tasksByHour[hour]?.append(task)
        }
        
        // Создаем блоки времени
        var blocks: [TimeBlock] = []
        
        // Берем все часы с 7 до 21 (или другой диапазон по необходимости)
        for hour in 7...21 {
            let tasks = tasksByHour[hour] ?? []
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
}

// Структура для блока времени
struct TimeBlock {
    let hour: Int
    let tasks: [TaskOnRing]
    let showHourLabel: Bool
    let showCurrentTime: Bool
}

// Расширение для создания скругленных углов только с определенных сторон
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, 
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
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
        
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            TaskTimeline(tasks: exampleTasks, selectedDate: now)
        }
    }
}

