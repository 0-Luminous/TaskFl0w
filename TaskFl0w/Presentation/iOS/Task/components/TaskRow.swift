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
    
    var body: some View {
        ZStack {
        
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isSelectionMode {
                        Button(action: {
                            toggleSelection()
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : (item.isCompleted ? "checkmark.circle" : "circle"))
                                .foregroundColor(isSelected ? categoryColor : (item.isCompleted ? .black : .white))
                                .font(.system(size: 22))
                        }
                    } else {
                        Button(action: onToggle) {
                            Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                                .foregroundColor(item.isCompleted ? .black : .white)
                                .font(.system(size: 22))
                        }
                    }
                    
                    // Название задачи без отображения приоритета
                    Text(item.title)
                        .strikethrough(item.isCompleted && !isSelectionMode && !isInArchiveMode)
                        .foregroundColor(item.isCompleted && !isSelectionMode && !isInArchiveMode ? .gray : .white)
                        .fontWeight(getFontWeight(for: item.priority))
                    
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
}
