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
    let selectedCategoryID: UUID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Получаем все задачи из списка на выбранную дату
            let items = getFilteredItemsForDate(selectedDate)
            
            // Отфильтровываем только задачи с нужной категорией
            let categoryTasks = items.filter { $0.categoryID == selectedCategoryID }
            
            // Получаем информацию о категории
            if let categoryItem = categoryTasks.first,
               let categoryName = categoryItem.categoryName {
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
                        todoTasks: categoryTasks
                    )
                }
            } else {
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
                    
                    // Показываем общее количество задач
                    let totalCount = todoTasks.count
                    if totalCount > 0 {
                        Text("\(totalCount)")
                            .font(.caption)
                            .padding(6)
                            .background(Circle().fill(category.color.opacity(0.3)))
                    }
                }
                .padding(.horizontal, 10)
                
                // Отображаем все задачи из категории
                if !todoTasks.isEmpty {                    
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
    
    TasksFromToDoListView(
        listViewModel: ListViewModel(),
        selectedDate: selectedDate,
        categoryManager: categoryManager,
        selectedCategoryID: UUID()
    )
}
