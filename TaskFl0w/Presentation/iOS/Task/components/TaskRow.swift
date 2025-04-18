//
//  TaskRow.swift
//  ToDoList
//
//  Created by Yan on 23/3/25.
//
import SwiftUI
import UIKit

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
    
    @State private var isLongPressed: Bool = false
    
    var body: some View {
        ZStack {
            // Фоновая полоса для обозначения приоритета
            if item.priority != .none {
                HStack {
                    Rectangle()
                        .fill(priorityColor(for: item.priority))
                        .frame(width: 4)
                        .opacity(0.8)
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if isSelectionMode {
                        Button(action: {
                            toggleSelection()
                        }) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? categoryColor : .white)
                                .font(.system(size: 22))
                        }
                    } else {
                        Button(action: onToggle) {
                            Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                                .foregroundColor(item.isCompleted ? .black : .white)
                                .font(.system(size: 22))
                        }
                    }
                    
                    // Название задачи с отображением приоритета
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .strikethrough(item.isCompleted && !isSelectionMode && !isInArchiveMode)
                            .foregroundColor(item.isCompleted && !isSelectionMode && !isInArchiveMode ? .gray : .white)
                            .fontWeight(getFontWeight(for: item.priority))
                        
                        // Строка с приоритетом
                        if item.priority != .none {
                            Text(getPriorityText(for: item.priority))
                                .font(.system(size: 12))
                                .foregroundColor(priorityColor(for: item.priority))
                                .opacity(0.9)
                        }
                    }
                    
                    Spacer()
                    
                    // Иконка приоритета
                    if item.priority != .none {
                        priorityIcon(for: item.priority)
                    }
                }
                .padding(.horizontal, -5)
                .padding(.leading, item.priority != .none ? 5 : 0)
            }
            .padding(.horizontal, 10)
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
    
    // Иконка приоритета
    private func priorityIcon(for priority: TaskPriority) -> some View {
        let systemName: String
        let color = priorityColor(for: priority)
        
        switch priority {
        case .high:
            systemName = "exclamationmark.triangle.fill"
        case .medium:
            systemName = "exclamationmark.circle.fill"
        case .low:
            systemName = "arrow.up.circle.fill"
        case .none:
            systemName = ""
        }
        
        return Image(systemName: systemName)
            .foregroundColor(color)
            .font(.system(size: 18))
    }
    
    // Текстовое представление приоритета
    private func getPriorityText(for priority: TaskPriority) -> String {
        return "Приоритет: \(priority.description)"
    }
    
    // Настройка жирности шрифта в зависимости от приоритета
    private func getFontWeight(for priority: TaskPriority) -> Font.Weight {
        switch priority {
        case .high:
            return .bold
        case .medium:
            return .semibold
        case .low, .none:
            return .regular
        }
    }
}
