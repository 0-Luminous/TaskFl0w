//
//  TaskRow.swift
//  ToDoList
//
//  Created by Yan on 23/3/25.
//
import SwiftUI

struct TaskRow: View {
    let item: ToDoItem
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    let categoryColor: Color
    let isSelectionMode: Bool
    let isInArchiveMode: Bool
    @Binding var selectedTasks: Set<UUID>

    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isSelectionMode {
                        Button(action: {
                            toggleSelection()
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : (item.isCompleted ? "checkmark.circle" : "circle"))
                                .foregroundColor(themeManager.isDarkMode ? isSelected ? categoryColor : (item.isCompleted ? .black : .white) : isSelected ? categoryColor : (item.isCompleted ? .black : .white))
                                .font(.system(size: 22))
                        }
                    } else {
                        Button(action: onToggle) {
                            Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                                .foregroundColor(themeManager.isDarkMode ? item.isCompleted ? .black : .white : item.isCompleted ? .black : .white)
                                .font(.system(size: 22))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        // Название задачи
                        Text(item.title)
                            .strikethrough(item.isCompleted && !isSelectionMode && !isInArchiveMode)
                            .foregroundColor(themeManager.isDarkMode ? item.isCompleted && !isSelectionMode && !isInArchiveMode ? .gray : .white : item.isCompleted && !isSelectionMode && !isInArchiveMode ? .gray : .black)
                            .fontWeight(getFontWeight(for: item.priority))
                        
                        // Крайний срок, если установлен
                        if let deadline = item.deadline {
                            HStack(spacing: 6) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(deadlineColor(for: deadline))
                                
                                Text(formatDeadline(deadline))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(deadlineColor(for: deadline))
                            }
                            .opacity((item.isCompleted && !isSelectionMode && !isInArchiveMode) || isInArchiveMode ? 0.5 : 1.0)
                        }
                    }
                    
                    Spacer()
                    
                    // Заменяем иконку приоритета на столбец приоритета
                    if item.priority != .none {
                        priorityIndicator(for: item.priority)
                    }
                }
            }
        }
        .animation(.easeInOut, value: item.priority)
    }
    
    // Проверяем, выбрана ли задача
    private var isSelected: Bool {
        selectedTasks.contains(item.id)
    }
    
    // Переключение выбора задачи
    private func toggleSelection() {
        if selectedTasks.contains(item.id) {
            selectedTasks.remove(item.id)
        } else {
            selectedTasks.insert(item.id)
        }
    }
    
    // Цвет для приоритета
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        case .none:
            return .clear
        }
    }
    
    // Индикатор приоритета в виде столбца (увеличенный вариант)
    private func priorityIndicator(for priority: TaskPriority) -> some View {
        VStack(spacing: 2) {
            ForEach(0..<priority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(priorityColor(for: priority))
                    .frame(width: 12, height: 3)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .opacity((item.isCompleted && !isSelectionMode && !isInArchiveMode) || isInArchiveMode ? 0.5 : 1.0)
    }
    
    // Настройка жирности шрифта в зависимости от приоритета
    private func getFontWeight(for priority: TaskPriority) -> Font.Weight {
        switch priority {
        case .high:
            return .semibold
        case .medium:
            return .semibold
        case .low, .none:
            return .regular
        }
    }
    
    // MARK: - Deadline функции
    
    // Форматирование даты крайнего срока
    private func formatDeadline(_ deadline: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // Проверяем, установлено ли конкретное время (не 00:00)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: deadline)
        let hasSpecificTime = timeComponents.hour != 0 || timeComponents.minute != 0
        
        // Проверяем, сегодня ли deadline
        if calendar.isDateInToday(deadline) {
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "сегодня \(timeFormatter.string(from: deadline))"
            } else {
                return "сегодня"
            }
        }
        
        // Проверяем, завтра ли deadline
        if calendar.isDateInTomorrow(deadline) {
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "завтра \(timeFormatter.string(from: deadline))"
            } else {
                return "завтра"
            }
        }
        
        // Проверяем, на этой неделе ли deadline
        let weekOfYear = calendar.component(.weekOfYear, from: now)
        let deadlineWeek = calendar.component(.weekOfYear, from: deadline)
        let year = calendar.component(.year, from: now)
        let deadlineYear = calendar.component(.year, from: deadline)
        
        if weekOfYear == deadlineWeek && year == deadlineYear {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.dateFormat = "EEEE"
            
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "\(weekdayFormatter.string(from: deadline)) \(timeFormatter.string(from: deadline))"
            } else {
                return weekdayFormatter.string(from: deadline)
            }
        }
        
        // Обычное форматирование для более отдаленных дат
        if hasSpecificTime {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .short
            return dateFormatter.string(from: deadline)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            return dateFormatter.string(from: deadline)
        }
    }
    
    // Цвет для отображения deadline в зависимости от срочности
    private func deadlineColor(for deadline: Date) -> Color {
        let now = Date()
        let timeInterval = deadline.timeIntervalSince(now)
        
        // Прошедший deadline - красный
        if timeInterval < 0 {
            return .red
        }
        
        // Меньше часа - красный
        if timeInterval < 3600 {
            return .red
        }
        
        // Меньше 6 часов - оранжевый
        if timeInterval < 21600 {
            return .orange
        }
        
        // Меньше дня - желтый
        if timeInterval < 86400 {
            return .yellow
        }
        
        // Обычный цвет для дальних deadline
        return themeManager.isDarkMode ? .white.opacity(0.7) : .secondary
    }
}
