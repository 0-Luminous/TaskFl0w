//
//  ArchivedTasksGroupView.swift
//  TaskFl0w
//
//  Created by Yan on 6/5/25.
//

import SwiftUI

// Обновленная версия ArchivedTasksGroupView.swift
struct ArchivedTasksGroupView: View {
    let items: [ToDoItem]
    let categoryColor: Color
    let isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    let onToggle: (UUID) -> Void
    let onEdit: (ToDoItem) -> Void
    let onDelete: (UUID) -> Void
    let onShare: (UUID) -> Void

    @ObservedObject private var viewModel = ClockViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared

    // Группировка задач по датам завершения
    private var groupedTasks: [Date: [ToDoItem]] {
        Dictionary(grouping: items) { item in
            // Извлекаем только дату, игнорируя время
            Calendar.current.startOfDay(for: item.date)
        }
    }
    
    // Получаем отсортированные даты (от новых к старым)
    private var sortedDates: [Date] {
        groupedTasks.keys.sorted(by: >)
    }
    
    
    var body: some View {
        ForEach(sortedDates, id: \.self) { date in
            if let tasksForDate = groupedTasks[date] {
                VStack(spacing: 0) {
                    // Заголовок группы с датой
                    HStack {
                        Text(date.formattedForClockDateLocalized())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        // Количество задач
                        Text("\(tasksForDate.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(themeManager.isDarkMode ? .gray : .black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    // Контейнер для задач группы
                    VStack(spacing: 8) {
                        ForEach(tasksForDate) { item in
                            TaskRow(
                                item: item,
                                onToggle: { onToggle(item.id) },
                                onEdit: { onEdit(item) },
                                onDelete: { onDelete(item.id) },
                                onShare: { onShare(item.id) },
                                categoryColor: categoryColor,
                                isSelectionMode: isSelectionMode,
                                isInArchiveMode: true,
                                selectedTasks: $selectedTasks
                            )
                            .padding(.horizontal, 5)
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                            // Явно добавляем обработчики нажатий
                            .onTapGesture {
                                if isSelectionMode {
                                    if selectedTasks.contains(item.id) {
                                        selectedTasks.remove(item.id)
                                    } else {
                                        selectedTasks.insert(item.id)
                                    }
                                } else {
                                    onToggle(item.id)
                                }
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    .padding(.vertical, 16)
                    
                }
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.isDarkMode ? Color(red: 0.13, green: 0.13, blue: 0.13) : Color(red: 0.9, green: 0.9, blue: 0.9))
                            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        // Градиентный бордер
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [categoryColor.opacity(0.7), Color.gray.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    }
                )
                .padding(.vertical, 8)
                .simultaneousGesture(TapGesture().onEnded {}) // Перехватываем нажатия на группу, но ничего не делаем
            }
        }
    }
    
    // Вспомогательные функции
    private func getPriorityColor(for priority: TaskPriority) -> Color {
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
}

