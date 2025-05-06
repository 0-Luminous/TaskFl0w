//
//  ArchivedTasksGroupView.swift
//  TaskFl0w
//
//  Created by Yan on 6/5/25.
//

import SwiftUI

// Новый компонент для отображения задач в архиве, сгруппированных по датам
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
                Section(header: 
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                        )
                        .padding(.top, 12)
                        .padding(.bottom, 4)
                ) {
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
                        .padding(.trailing, 5)
                        .listRowBackground(
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                                
                                // Добавляем внешний бордер для задач с приоритетом
                                if item.priority != .none {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(getPriorityColor(for: item.priority), lineWidth: 1.5)
                                }
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 12)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if isSelectionMode {
                                toggleTaskSelection(taskId: item.id)
                            } else {
                                onToggle(item.id)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
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
            return .blue
        case .none:
            return .clear
        }
    }
    
    private func toggleTaskSelection(taskId: UUID) {
        if selectedTasks.contains(taskId) {
            selectedTasks.remove(taskId)
        } else {
            selectedTasks.insert(taskId)
        }
    }
}

