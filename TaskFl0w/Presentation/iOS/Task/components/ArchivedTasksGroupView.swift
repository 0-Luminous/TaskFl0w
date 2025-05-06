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
    
    // Форматтер для отображения даты
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    var body: some View {
        ForEach(sortedDates, id: \.self) { date in
            if let tasksForDate = groupedTasks[date] {
                VStack(spacing: 0) {
                    // Заголовок группы с датой
                    HStack {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Количество задач
                        Text("\(tasksForDate.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
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
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                                    
                                    // Добавляем внешний бордер для задач с приоритетом
                                    if item.priority != .none {
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(getPriorityColor(for: item.priority), lineWidth: 1.5)
                                            .opacity(0.3)
                                    }
                                }
                            )
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
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.13))
                        
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
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
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

