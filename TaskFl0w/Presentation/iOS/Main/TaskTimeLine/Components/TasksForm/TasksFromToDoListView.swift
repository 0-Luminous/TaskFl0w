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
            return "Будущий слот"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeRange = "\(formatter.string(from: slot.startTime)) - \(formatter.string(from: slot.endTime))"
        
        return "Слот завершён"
    }
    
    // Компонент для отображения одной категории (новый дизайн по фото)
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
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.hour, .minute]
            formatter.zeroFormattingBehavior = .dropAll
            formatter.calendar = Calendar.current
            formatter.calendar?.locale = Locale.current
            return formatter
        }()
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Основной блок с временем и категорией
                VStack(alignment: .leading, spacing: 8) {
                    // Время и продолжительность
                    if let start = startTime, let end = endTime {
                        HStack(alignment: .top) {
                            // Время начала и окончания
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTime(start))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text(formatTime(end))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            
                            Spacer()
                            
                            // Индикатор продолжительности
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(formatDuration(end.timeIntervalSince(start)))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.3))
                                    )
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                // Иконка и название категории
                                HStack(spacing: 6) {
                                    Image(systemName: category.iconName)
                                        .foregroundColor(.black)
                                        .font(.system(size: 16))
                                    
                                    Text(category.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                .padding(.top, 6)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    } else {
                        // Если нет времени, показываем только категорию
                        HStack(spacing: 8) {
                            Image(systemName: category.iconName)
                                .foregroundColor(.black)
                                .font(.system(size: 20))
                            
                            Text(category.rawValue)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                    }
                    
                    // Список задач
                    if showFullTasks && !todoTasks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
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
                                ToDoTaskRow(
                                    task: task, 
                                    categoryColor: category.color,
                                    onToggle: {
                                        onToggleTask?(task.id)
                                    }
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Показываем сообщение о переносе задач
                    if let transferMessage = transferMessage {
                        Text(transferMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 8)
                    }
                    
                    // Если нет задач в категории, показываем информационное сообщение
                    if todoTasks.isEmpty && transferMessage == nil {
                        Text("taskTimeLine.title".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(.top, 8)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    category.color.opacity(0.9),
                                    category.color.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: category.color.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        
        // Форматирование времени в формате HH:MM
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
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
