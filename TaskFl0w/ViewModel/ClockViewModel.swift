//
//  ClockViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import Combine
import CoreData

final class ClockViewModel: ObservableObject {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    // MARK: - Published properties
    
    @Published var tasks: [Task] = []
    @Published var categories: [TaskCategoryModel] = [
        TaskCategoryModel(id: UUID(), rawValue: "Работа", iconName: "macbook", color: .blue),
        TaskCategoryModel(id: UUID(), rawValue: "Спорт", iconName: "figure.strengthtraining.traditional", color: .green),
        TaskCategoryModel(id: UUID(), rawValue: "Развлечения", iconName: "gamecontroller", color: .red)
    ]
    
    // Текущая "выбранная" дата для отображения задач
    @Published var selectedDate: Date = Date()
    
    // Текущее время для реального обновления
    @Published var currentDate: Date = Date()
    
    // В этот флаг можно прокидывать логику тёмной/светлой темы, если нужно
    @AppStorage("isDarkMode") var isDarkMode = false
    
    // Пример использования AppStorage для цвета циферблата
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()
    
    @Published var isDockBarEditingEnabled: Bool = false
    
    // Перетаскивание задачи
    @Published var draggedTask: Task?
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
    @Published var editingTask: Task?
    @Published var isDraggingStart: Bool = false
    @Published var isDraggingEnd: Bool = false
    @Published var previewTime: Date?
    @Published var dropLocation: CGPoint?
    @Published var selectedTask: Task?
    @Published var showingTaskDetail: Bool = false
    @Published var searchText: String = ""
    
    // MARK: - Инициализация
    
    init() {
        container = PersistenceController.shared.container
        context = container.viewContext
        
        fetchCategories()
        fetchTasks()
    }
    
    // MARK: - CoreData методы
    private func fetchCategories() {
        let request = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
        
        do {
            let categoryEntities = try context.fetch(request)
            categories = categoryEntities.map { $0.categoryModel }
        } catch {
            print("Ошибка при загрузке категорий: \(error)")
        }
    }
    
    private func fetchTasks() {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        
        do {
            let taskEntities = try context.fetch(request)
            tasks = taskEntities.map { $0.taskModel }
        } catch {
            print("Ошибка при загрузке задач: \(error)")
        }
    }
    
    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error)")
            }
        }
    }
    
    // MARK: - Методы работы с задачами
    
    func addTask(_ task: Task) {
        // Убедимся, что время задачи соответствует выбранной дате
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: task.startTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        if let correctedDate = calendar.date(from: components) {
            var newTask = task
            newTask.startTime = correctedDate
            tasks.append(newTask)
        }
    }
    
    func updateTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let existingTask = try context.fetch(request).first {
                existingTask.title = task.title
                existingTask.startTime = task.startTime
                existingTask.duration = task.duration
                existingTask.isCompleted = task.isCompleted
                
                // Обновляем категорию
                let categoryRequest = NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
                categoryRequest.predicate = NSPredicate(format: "id == %@", task.category.id as CVarArg)
                if let category = try context.fetch(categoryRequest).first {
                    existingTask.category = category
                }
                
                saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при обновлении задачи: \(error)")
        }
    }
    
    func removeTask(_ task: Task) {
        let request = NSFetchRequest<TaskEntity>(entityName: "TaskEntity")
        request.predicate = NSPredicate(format: "id == %@", task.id as CVarArg)
        
        do {
            if let taskToDelete = try context.fetch(request).first {
                context.delete(taskToDelete)
                saveContext()
                fetchTasks()
            }
        } catch {
            print("Ошибка при удалении задачи: \(error)")
        }
    }
    
    // MARK: - Методы работы с категориями
    
    func addCategory(_ category: TaskCategoryModel) {
        categories.append(category)
    }
    
    func updateCategory(_ category: TaskCategoryModel) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            // Обновляем все задачи, связанные с этой категорией
            tasks = tasks.map { task in
                if task.category.id == category.id {
                    return Task(
                        id: task.id,
                        title: task.title,
                        startTime: task.startTime,
                        duration: task.duration,
                        color: category.color,
                        icon: category.iconName,
                        category: category,
                        isCompleted: task.isCompleted
                    )
                }
                return task
            }
        }
    }
    
    func removeCategory(_ category: TaskCategoryModel) {
        // Удаляем все задачи, связанные с этой категорией
        tasks.removeAll { task in
            task.category.id == category.id
        }
        
        // Удаляем саму категорию
        categories.removeAll { $0.id == category.id }
    }
    
    func updateTaskStartTimeKeepingEnd(_ task: Task, newStartTime: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        let oldEndTime = task.startTime.addingTimeInterval(task.duration)
        
        // Создаем компоненты для новой даты, сохраняя день из selectedDate
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newStartTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let newStart = calendar.date(from: components) else { return }
        
        // Вычисляем новую продолжительность
        let newDuration = oldEndTime.timeIntervalSince(newStart)
        
        // Обновляем только конкретную задачу
        var updatedTask = task
        updatedTask.startTime = newStart
        updatedTask.duration = max(0, newDuration)
        
        tasks[index] = updatedTask
    }
    
    private func validateTimeInterval(_ interval: TimeInterval) -> TimeInterval {
        guard interval.isFinite else { return 0 }
        return max(0, min(interval, 24 * 60 * 60)) // Максимум 24 часа
    }
    
    func updateTaskStartTime(_ task: Task, newStartTime: Date) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var updatedTask = task
            updatedTask.startTime = newStartTime
            tasks[index] = updatedTask
            updateTask(updatedTask)
        }
    }
    
    func updateTaskDuration(_ task: Task, newEndTime: Date) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let calendar = Calendar.current
        
        // Создаем компоненты для новой даты окончания
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: newEndTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard let newEnd = calendar.date(from: components) else { return }
        
        // Вычисляем новую продолжительность
        let newDuration = newEnd.timeIntervalSince(task.startTime)
        
        // Обновляем только конкретную задачу
        var updatedTask = task
        updatedTask.duration = max(0, newDuration)
        
        tasks[index] = updatedTask
    }
    
    func startDragging(_ task: Task) {
        draggedTask = task
    }
    
    func stopDragging(didReturnToClock: Bool) {
        if let task = draggedTask {
            if !didReturnToClock {
                tasks.removeAll(where: { $0.id == task.id })
            }
        }
        draggedTask = nil
        isDraggingOutside = false
    }
    
    func updateDragPosition(isOutsideClock: Bool) {
        isDraggingOutside = isOutsideClock
    }
}
