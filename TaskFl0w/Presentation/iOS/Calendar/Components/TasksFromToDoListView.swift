//
//  TasksFromToDoListView.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Компонент для отображения задач из ToDoList
struct TasksFromToDoListView: View {
    @ObservedObject var listViewModel: ListViewModel
    let selectedDate: Date
    let categoryManager: CategoryManagementProtocol
    // Добавляем доступ к задачам на циферблате
    var clockTasks: [TaskOnRing] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Получаем все задачи из списка на выбранную дату
            let items = getFilteredItemsForDate(selectedDate)
            
            // Получаем задачи из циферблата на выбранную дату
            let filteredClockTasks = clockTasks.filter { task in
                Calendar.current.isDate(task.startTime, inSameDayAs: selectedDate)
            }
            
            // Получаем уникальные категории из задач на циферблате И из ToDo списка
            let categoriesFromToDo = items.compactMap { $0.categoryID }
                .reduce(into: Set<UUID>()) { set, id in set.insert(id) }

            let allCategoryIds = Set(filteredClockTasks.map { $0.category.id }) 
                .union(categoriesFromToDo)

            // Получаем информацию о каждой категории
            let allCategories = allCategoryIds.compactMap { categoryId -> TaskCategoryModel? in
                if let category = filteredClockTasks.first(where: { $0.category.id == categoryId })?.category {
                    return category
                }
                
                // Если категория не найдена в clockTasks, ищем информацию через categoryManager
                if let categoryItem = items.first(where: { $0.categoryID == categoryId }),
                   let categoryName = categoryItem.categoryName {
                    let (color, icon) = getCategoryInfo(for: categoryId, categoryManager: categoryManager)
                    return TaskCategoryModel(id: categoryId, rawValue: categoryName, iconName: icon, color: color)
                }
                
                return nil
            }
            .sorted { $0.rawValue < $1.rawValue }
            
            if allCategories.isEmpty {
                Text("Нет задач на этот день")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 15)
            } else {
                ForEach(allCategories, id: \.id) { category in
                    let categoryTasks = items.filter { $0.categoryID == category.id }
                    let ringTasks = filteredClockTasks.filter { $0.category.id == category.id }
                    
                    CategoryView(
                        category: category,
                        todoTasks: categoryTasks,
                        ringTasks: ringTasks
                    )
                    .padding(.bottom, 8)
                }
            }
        }
    }
    
    // Компонент для отображения одной категории
    private struct CategoryView: View {
        let category: TaskCategoryModel
        let todoTasks: [ToDoItem]
        let ringTasks: [TaskOnRing]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Заголовок категории
                HStack {
                    Image(systemName: category.iconName)
                        .foregroundColor(category.color)
                        .font(.system(size: 14))
                    
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Показываем общее количество задач (из ToDo и с циферблата)
                    let totalCount = todoTasks.count + ringTasks.count
                    if totalCount > 0 {
                        Text("\(totalCount)")
                            .font(.caption)
                            .padding(6)
                            .background(Circle().fill(category.color.opacity(0.3)))
                    }
                }
                .padding(.horizontal, 10)
                
                // Добавляем информацию о времени категории на циферблате
                if !ringTasks.isEmpty {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(category.color.opacity(0.7))
                            .font(.system(size: 12))
                        
                        Text(getCategoryTimeRangeText())
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 5)
                }
                
                // Отображаем все задачи из категории
                if !todoTasks.isEmpty {
                    if !ringTasks.isEmpty {
                        Text("В списке:")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.top, 5)
                    }
                    
                    // Сортируем задачи: сначала по статусу завершения, затем по приоритету
                    let sortedTasks = todoTasks.sorted { (task1, task2) -> Bool in
                        // Сначала незавершенные задачи
                        if task1.isCompleted != task2.isCompleted {
                            return !task1.isCompleted
                        }
                        
                        // Потом по приоритету от высокого к низкому
                        return task1.priority.rawValue > task2.priority.rawValue
                    }
                    
                    // Отображаем отсортированные задачи
                    ForEach(sortedTasks) { task in
                        ToDoTaskRow(task: task, categoryColor: category.color)
                    }
                }
                
                // Если нет задач в категории, показываем информационное сообщение
                if todoTasks.isEmpty && ringTasks.isEmpty {
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
        
        // Форматирование временных интервалов категории
        private func getCategoryTimeRangeText() -> String {
            // Сортируем задачи по времени начала
            let sortedByStartTime = ringTasks.sorted { $0.startTime < $1.startTime }
            
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            // Если категория появляется только один раз
            if sortedByStartTime.count == 1, let task = sortedByStartTime.first {
                return "На циферблате: " + formatter.string(from: task.startTime) + " - " + formatter.string(from: task.endTime)
            }
            
            // Если категория появляется несколько раз, формируем список всех временных интервалов
            var timeRanges: [String] = []
            for task in sortedByStartTime {
                timeRanges.append(formatter.string(from: task.startTime) + " - " + formatter.string(from: task.endTime))
            }
            
            return "На циферблате: " + timeRanges.joined(separator: ", ")
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

//#Preview {
//    let context = PersistenceController.shared.container.viewContext
//    let categoryManager = CategoryManagement(context: context)
//    let selectedDate = Date()
//    
//    TasksFromToDoListView(
//        listViewModel: ListViewModel(),
//        selectedDate: selectedDate,
//        categoryManager: categoryManager,
//        clockTasks: [TaskOnRing.example]
//    )
//}
