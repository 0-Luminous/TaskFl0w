//
//  ToDoTaskRow.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Компонент для отображения строки задачи из ToDoList
struct ToDoTaskRow: View {
    let task: ToDoItem
    let categoryColor: Color
    let hapticsManager = HapticsManager.shared
    var onToggle: (() -> Void)? = nil
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: handleTap) {
            HStack(spacing: 12) {
                // Индикатор выполнения
                completionIndicator
                
                // Основной контент
                taskContent
                
                Spacer()
                
                // Индикатор приоритета
                if task.priority != .none {
                    priorityIndicator
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(taskBackground)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Private Views
    
    private var completionIndicator: some View {
        Circle()
            .fill(task.isCompleted ? categoryColor : Color.clear)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(task.isCompleted ? categoryColor.opacity(0.7) : categoryColor.opacity(0.7), lineWidth: 1)
            )
    }
    
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Название задачи
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(task.isCompleted ? .gray : themeManager.isDarkMode ? .white : .black)
                .strikethrough(task.isCompleted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Крайний срок, если установлен
            if let deadline = task.deadline {
                HStack(spacing: 4) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(deadlineColor(for: deadline))
                    
                    Text(formatDeadline(deadline))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(deadlineColor(for: deadline))
                }
                .opacity(task.isCompleted ? 0.5 : 1.0)
            }
        }
    }
    
    private var priorityIndicator: some View {
        VStack(spacing: 1) {
            ForEach(0..<task.priority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 2)
            }
        }
    }
    
    private var taskBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.9, green: 0.9, blue: 0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(priorityBorderColor, lineWidth: task.priority != .none ? 1.5 : 0)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Private Properties
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        case .none: return .gray
        }
    }
    
    private var priorityBorderColor: Color {
        switch task.priority {
        case .high: return Color.red.opacity(0.6)
        case .medium: return Color.orange.opacity(0.5)
        case .low: return Color.green.opacity(0.4)
        case .none: return Color.clear
        }
    }
    
    // MARK: - Deadline Functions
    
    // Форматирование даты крайнего срока (адаптированно для timeline)
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
                return timeFormatter.string(from: deadline)
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
            weekdayFormatter.dateFormat = "EEE"
            
            if hasSpecificTime {
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                return "\(weekdayFormatter.string(from: deadline)) \(timeFormatter.string(from: deadline))"
            } else {
                return weekdayFormatter.string(from: deadline)
            }
        }
        
        // Обычное форматирование для более отдаленных дат (короткий формат для timeline)
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
    
    // MARK: - Private Methods
    
    private func handleTap() {
        hapticsManager.triggerLightFeedback()
        onToggle?()
    }
}

#Preview {
    ToDoTaskRow(
        task: ToDoItem(
            title: "Test task with deadline", 
            priority: .high, 
            deadline: Date().addingTimeInterval(3600) // Deadline через час
        ), 
        categoryColor: .red
    )
}