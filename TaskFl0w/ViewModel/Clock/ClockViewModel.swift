//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine

final class ClockViewModel: ObservableObject {
    // MARK: - Published properties
    
    @Published var tasks: [Task] = []
    @Published var categories: [TaskCategoryModel] = []
    
    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date()
    
    // В этот флаг можно прокидывать логику тёмной/светлой темы, если нужно
    @AppStorage("isDarkMode") var isDarkMode = false
    
    // Пример использования AppStorage для цвета циферблата
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()
    
    // MARK: - Инициализация
    
    init() {
        // Здесь можно загрузить данные из базы/сервиса/файлов
        // Заполнить tasks, categories и т.д.
        // Ниже для примера:
        
        self.categories = [
            TaskCategoryModel(id: UUID(), rawValue: "Работа", iconName: "briefcase.fill", color: .blue),
            TaskCategoryModel(id: UUID(), rawValue: "Спорт", iconName: "sportscourt.fill", color: .green),
            TaskCategoryModel(id: UUID(), rawValue: "Развлечения", iconName: "gamecontroller.fill", color: .orange),
            // Добавьте свои категории...
        ]
        
//        // Пример добавления тестовых задач
//        self.tasks = [
//            Task(
//                id: UUID(),
//                title: "Пример задачи",
//                startTime: Date(),
//                duration: 60 * 60,       // 1 час
//                color: .blue,
//                icon: "briefcase.fill",
//                category: categories[0],
//                isCompleted: false
//            )
//        ]
    }
    
    // MARK: - Методы работы с задачами
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func updateTaskStartTime(_ task: Task, newStartTime: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].startTime = newStartTime
        
        // Если при изменении начала задачи нужно, например, сдвигать конец — можно делать здесь
        // tasks[index].duration = ...
    }
    
    func updateTaskDuration(_ task: Task, newEndTime: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let currentStart = tasks[index].startTime
        let newDuration = newEndTime.timeIntervalSince(currentStart)
        if newDuration > 0 {
            tasks[index].duration = newDuration
        } else {
            // Обработка ситуации, когда новое время меньше начала (на случай ухода за полночь)
            tasks[index].duration = newDuration + 24 * 3600
        }
    }
    
    func removeTask(_ task: Task) {
        tasks.removeAll(where: { $0.id == task.id })
    }
    
    // MARK: - Методы работы с категориями
    
    func addCategory(_ category: TaskCategoryModel) {
        categories.append(category)
    }
    
    // И т.д., если нужно
}
