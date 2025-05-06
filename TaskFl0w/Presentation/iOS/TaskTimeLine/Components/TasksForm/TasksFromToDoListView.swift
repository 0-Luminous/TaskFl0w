//
//  TasksFromView.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Компонент для отображения задач из ToDoList
struct TasksFromView: View {
    @ObservedObject var listViewModel: ListViewModel
    let selectedDate: Date
    let categoryManager: CategoryManagementProtocol
    let selectedCategoryID: UUID
    var startTime: Date? = nil
    var endTime: Date? = nil
    var isNearestCategory: Bool = true // Новый параметр: ближайшая ли это категория
    var specificTasks: [ToDoItem]? = nil // Добавляем параметр для передачи конкретных задач
    
    var body: some View {
        // Оборачиваем весь контент в VStack
        VStack(alignment: .leading, spacing: 12) {
            // Используем specificTasks, если они переданы, иначе фильтруем из списка
            let categoryTasks: [ToDoItem] = specificTasks ?? getFilteredItemsForDate(selectedDate).filter { $0.categoryID == selectedCategoryID }
            
            // Проверяем, можем ли извлечь информацию о категории из задач или из менеджера категорий
            if let categoryItem = categoryTasks.first, let categoryName = categoryItem.categoryName {
                let (color, icon) = getCategoryInfo(for: selectedCategoryID, categoryManager: categoryManager)
                let category = TaskCategoryModel(id: selectedCategoryID, rawValue: categoryName, iconName: icon, color: color)
                
                if categoryTasks.isEmpty {
                    Text("Нет задач на этот день")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 15)
                } else {
                    CategoryView(
                        category: category,
                        todoTasks: categoryTasks,
                        startTime: startTime,
                        endTime: endTime,
                        showFullTasks: isNearestCategory,
                        onToggleTask: { taskId in
                            // Используем presenter из ListViewModel для переключения статуса задачи
                            listViewModel.presenter?.toggleItem(id: taskId)
                        }
                    )
                }
            } else if let category = categoryManager.categories.first(where: { $0.id == selectedCategoryID }) {
                // Если нет задач, пытаемся получить информацию о категории из categoryManager
                let taskCategory = TaskCategoryModel(
                    id: selectedCategoryID,
                    rawValue: category.rawValue,
                    iconName: category.iconName,
                    color: category.color
                )
                
                CategoryView(
                    category: taskCategory,
                    todoTasks: [],
                    startTime: startTime,
                    endTime: endTime,
                    showFullTasks: false,
                    onToggleTask: { taskId in
                        // Используем presenter из ListViewModel для переключения статуса задачи
                        listViewModel.presenter?.toggleItem(id: taskId)
                    }
                )
            } else {
                // Если категория вообще не найдена
                Text("Категория не найдена")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 15)
            }
        }
    }
    
    // Компонент для отображения одной категории
    private struct CategoryView: View {
        let category: TaskCategoryModel
        let todoTasks: [ToDoItem]
        let startTime: Date?
        let endTime: Date?
        let showFullTasks: Bool // Новый параметр
        var onToggleTask: ((UUID) -> Void)? = nil
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Заголовок категории
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(category.color)
                            .font(.system(size: 14))
                        
                        Text(category.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Показываем общее количество задач
                        let totalCount = todoTasks.count
                        if totalCount > 0 {
                            Text("\(totalCount)")
                                .font(.caption)
                                .padding(6)
                                .background(Circle().fill(category.color.opacity(0.3)))
                        }
                    }
                    
                    // Показываем время начала и окончания, если они доступны
                    if let start = startTime, let end = endTime {
                        HStack {
                            Text(formatTime(start))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("-")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(formatTime(end))
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            // Добавляем продолжительность
                            Text("\(formatDuration(end.timeIntervalSince(start)))")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(category.color.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.horizontal, 10)
                
                // Отображаем задачи только если showFullTasks = true
                if showFullTasks && !todoTasks.isEmpty {                    
                    // Сортируем задачи: сначала по статусу завершения, затем по приоритету
                    let sortedTasks = todoTasks.sorted { (task1, task2) -> Bool in
                        // Сначала незавершенные задачи
                        if task1.isCompleted != task2.isCompleted {
                            return !task1.isCompleted
                        }
                        
                        // Потом по приоритету от высокого к низкому
                        return task1.priority.rawValue > task2.priority.rawValue
                    }
                    
                    // Отображаем отсортированные задачи с обработчиком нажатия
                    ForEach(sortedTasks) { task in
                        ToDoTaskRow(
                            task: task, 
                            categoryColor: category.color,
                            onToggle: {
                                // Вызываем обработчик переключения задачи
                                onToggleTask?(task.id)
                            }
                        )
                    }
                }
                
                // Для не ранних категорий показываем сообщение
                if !showFullTasks && !todoTasks.isEmpty {
                    Text("Незавершённые задачи перенесены в следующую категорию")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                
                // Если нет задач в категории, показываем информационное сообщение
                if todoTasks.isEmpty {
                    Text("Нет задач на этот день")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(category.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        
        // Форматирование времени
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        // Форматирование продолжительности
        private func formatDuration(_ interval: TimeInterval) -> String {
            let totalMinutes = Int(interval / 60)
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            
            if hours > 0 {
                return "\(hours) ч \(minutes) мин"
            } else {
                return "\(minutes) мин"
            }
        }
    }
    
    // Фильтрация задач на выбранную дату
    private func getFilteredItemsForDate(_ date: Date) -> [ToDoItem] {
        return listViewModel.items.filter { item in
            Calendar.current.isDate(item.date, inSameDayAs: date)
        }.sorted { (item1, item2) -> Bool in
            // Сначала приоритизируем незавершенные задачи
            if item1.isCompleted != item2.isCompleted {
                return !item1.isCompleted
            }
            
            // Затем сортируем по приоритету (от высокого к низкому)
            return item1.priority.rawValue > item2.priority.rawValue
        }
    }
}

// Получение информации о категории (цвет и иконка)
func getCategoryInfo(for categoryID: UUID, categoryManager: CategoryManagementProtocol) -> (Color, String) {
    // Ищем категорию в списке категорий
    if let category = categoryManager.categories.first(where: { $0.id == categoryID }) {
        return (category.color, category.iconName)
    }
    
    // Если не нашли, используем стандартные значения
    let colors: [Color] = [.blue, .green, .orange, .red, .purple, .yellow]
    let hashValue = abs(categoryID.hashValue)
    let color = colors[hashValue % colors.count]
    
    // Используем различные иконки в зависимости от хеша
    let icons = ["tag.fill", "folder.fill", "list.bullet", "checkmark.circle.fill", 
                "calendar", "book.fill", "note.text", "tray.fill"]
    let icon = icons[(hashValue / 2) % icons.count]
    
    return (color, icon)
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let categoryManager = CategoryManagement(context: context)
    let selectedDate = Date()
    let startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate)
    let endTime = Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: selectedDate)
    
    return TasksFromView(
        listViewModel: ListViewModel(),
        selectedDate: selectedDate,
        categoryManager: categoryManager,
        selectedCategoryID: UUID(),
        startTime: startTime,
        endTime: endTime
    )
}
