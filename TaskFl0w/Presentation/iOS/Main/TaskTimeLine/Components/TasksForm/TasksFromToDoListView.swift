//
//  TasksFromView.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Сначала добавим PreferenceKey в начало файла
struct CategoryHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 100
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Компонент для отображения задач из ToDoList
struct TasksFromView: View {
    @ObservedObject var listViewModel: ListViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let selectedDate: Date
    let categoryManager: CategoryManagementProtocol
    let selectedCategoryID: UUID
    var startTime: Date? = nil
    var endTime: Date? = nil
    var isNearestCategory: Bool = true
    var specificTasks: [ToDoItem]? = nil
    var allTimelineTasksForCategory: [TaskOnRing]? = nil
    var slotId: String? = nil // ДОБАВЛЯЕМ УНИКАЛЬНЫЙ ID СЛОТА
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Получаем все задачи для данной категории
            let categoryTasks: [ToDoItem] = specificTasks ?? getFilteredItemsForDate(selectedDate).filter { $0.categoryID == selectedCategoryID }
            
            // Логика определения задач для показа с использованием slotId
            let tasksToShow = getTasksForSlot(categoryTasks: categoryTasks, slotId: slotId)
            
            if let categoryItem = categoryTasks.first, let categoryName = categoryItem.categoryName {
                let (color, icon) = getCategoryInfo(for: selectedCategoryID, categoryManager: categoryManager)
                let category = TaskCategoryModel(id: selectedCategoryID, rawValue: categoryName, iconName: icon, color: color)
                
                CategoryView(
                    category: category,
                    todoTasks: tasksToShow.tasks,
                    startTime: startTime,
                    endTime: endTime,
                    showFullTasks: tasksToShow.shouldShow,
                    transferMessage: tasksToShow.message,
                    onToggleTask: { taskId in
                        listViewModel.presenter?.toggleItem(id: taskId)
                    }
                )
            } else if let category = categoryManager.categories.first(where: { $0.id == selectedCategoryID }) {
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
                    transferMessage: nil,
                    onToggleTask: { _ in }
                )
            } else {
                // Если категория вообще не найдена
                Text("categoryNotFound".localized)
                    .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 15)
            }
        }
    }
    
    // ИСПРАВЛЯЕМ ЛОГИКУ С ПРАВИЛЬНЫМ ИМЕНЕМ ФУНКЦИИ
    private func getTasksForSlot(categoryTasks: [ToDoItem], slotId: String?) -> (tasks: [ToDoItem], shouldShow: Bool, message: String?) {
        // Если нет временных слотов или только один слот
        guard let allCategoryTasks = allTimelineTasksForCategory,
              allCategoryTasks.count > 1,
              let currentStart = startTime,
              let currentEnd = endTime,
              let slotId = slotId else {
            return (tasks: categoryTasks, shouldShow: true, message: nil)
        }
        
        let currentTime = Date()
        let incompleteTasks = categoryTasks.filter { !$0.isCompleted }
        let completedTasks = categoryTasks.filter { $0.isCompleted }
        
        // ИСПОЛЬЗУЕМ СУЩЕСТВУЮЩУЮ ФУНКЦИЮ findActiveSlot
        let activeSlot = findActiveSlot(slots: allCategoryTasks, currentTime: currentTime)
        
        // Создаем ID для активного слота
        let activeSlotId = activeSlot.map { slot in
            createSlotId(
                categoryId: selectedCategoryID,
                startTime: slot.startTime,
                endTime: slot.endTime,
                date: selectedDate
            )
        }
        
        // Проверяем, является ли текущий слот активным
        let isActive = activeSlotId == slotId
        
        if isActive {
            // Активный слот - показываем все задачи
            return (tasks: categoryTasks, shouldShow: true, message: nil)
        } else if !incompleteTasks.isEmpty {
            // Неактивный слот с незавершенными задачами
            let message = getTransferMessage(activeSlot: activeSlot)
            return (tasks: completedTasks, shouldShow: false, message: message)
        } else {
            // Неактивный слот без незавершенных задач
            return (tasks: completedTasks, shouldShow: true, message: nil)
        }
    }
    
    // ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ ДЛЯ СОЗДАНИЯ ID
    private func createSlotId(categoryId: UUID, startTime: Date, endTime: Date, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH:mm"
        let dateString = formatter.string(from: date)
        let startString = formatter.string(from: startTime)
        let endString = formatter.string(from: endTime)
        
        return "\(categoryId)-\(dateString)-\(startString)-\(endString)"
    }
    
    private func findActiveSlot(slots: [TaskOnRing], currentTime: Date) -> TaskOnRing? {
        let sortedSlots = slots.sorted { $0.startTime < $1.startTime }
        
        // Проверяем, находимся ли мы внутри какого-то слота
        for slot in sortedSlots {
            if currentTime >= slot.startTime && currentTime < slot.endTime {
                return slot
            }
        }
        
        // Ищем следующий слот
        for slot in sortedSlots {
            if currentTime < slot.startTime {
                return slot
            }
        }
        
        // Возвращаем последний слот
        return sortedSlots.last
    }
    
    private func getTransferMessage(activeSlot: TaskOnRing?) -> String {
        guard let slot = activeSlot else {
            return "Незавершённые задачи перенесены в активный слот"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeRange = "\(formatter.string(from: slot.startTime)) - \(formatter.string(from: slot.endTime))"
        
        return "Незавершённые задачи перенесены в слот (\(timeRange))"
    }
    
    // Компонент для отображения одной категории (старый дизайн)
    private struct CategoryView: View {
        let category: TaskCategoryModel
        let todoTasks: [ToDoItem]
        let startTime: Date?
        let endTime: Date?
        let showFullTasks: Bool
        let transferMessage: String?
        var onToggleTask: ((UUID) -> Void)? = nil
        @ObservedObject private var themeManager = ThemeManager.shared
        
        // Добавляем локализованный форматтер продолжительности
        private static let durationFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .brief
            formatter.allowedUnits = [.hour, .minute]
            formatter.zeroFormattingBehavior = .dropAll
            formatter.calendar = Calendar.current
            formatter.calendar?.locale = Locale.current
            return formatter
        }()
        
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
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        // Улучшенный индикатор количества задач
                        let totalCount = todoTasks.count
                        let completedCount = todoTasks.filter { $0.isCompleted }.count
                        
                        if totalCount > 0 {
                            HStack(spacing: 4) {
                                // Индикатор прогресса
                                ZStack {
                                    // Фоновая капсула
                                    Capsule()
                                        .stroke(category.color.opacity(0.2), lineWidth: 2)
                                        .frame(width: 60, height: 24)
                                    
                                    // Капсула прогресса
                                    Capsule()
                                        .trim(from: 0, to: CGFloat(completedCount) / CGFloat(totalCount))
                                        .stroke(category.color, lineWidth: 2)
                                        .frame(width: 60, height: 24)
                                    
                                    // Добавляем текст внутрь капсулы
                                    Text("\(completedCount)/\(totalCount)")
                                        .font(.system(size: 10))
                                        .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                                }
                            }
                            .padding(.trailing, 4)
                        }
                    }
                    
                    // Показываем время начала и окончания, если они доступны
                    if let start = startTime, let end = endTime {
                        HStack {
                            Text(formatTime(start))
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                            
                            Text("-")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                            
                            Text(formatTime(end))
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                            
                            Spacer()
                            
                            // Добавляем продолжительность
                            Text("\(formatDuration(end.timeIntervalSince(start)))")
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .gray : .black)
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
                
                // Показываем сообщение о переносе задач
                if let transferMessage = transferMessage {
                    Text(transferMessage)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(category.color.opacity(0.1))
                        )
                }
                
                // Если нет задач в категории, показываем информационное сообщение
                if todoTasks.isEmpty && transferMessage == nil {
                    Text("taskTimeLine.title".localized)
                        .font(.caption)
                        .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.isDarkMode ? Color(red: 0.22, green: 0.22, blue: 0.227) : Color(red: 0.808, green: 0.808, blue: 0.812))
                    .opacity(0.9)
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
            // Автоматическая локализация через DateComponentsFormatter
            return Self.durationFormatter.string(from: interval) ?? ""
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
