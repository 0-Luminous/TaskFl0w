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
            // Удаляем фоновую полосу для обозначения приоритета, так как теперь
            // задачи будут сгруппированы по приоритету
            // if item.priority != .none {
            //     HStack {
            //         Rectangle()
            //             .fill(priorityColor(for: item.priority))
            //             .frame(width: 4)
            //             .opacity(0.8)
            //         Spacer()
            //     }
            // }
            
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
                    
                    // Название задачи без отображения приоритета
                    Text(item.title)
                        .strikethrough(item.isCompleted && !isSelectionMode && !isInArchiveMode)
                        .foregroundColor(item.isCompleted && !isSelectionMode && !isInArchiveMode ? .gray : .white)
                        .fontWeight(getFontWeight(for: item.priority))
                    
                    Spacer()
                    
                    // Можно оставить иконку приоритета для визуальной индикации
                    if item.priority != .none {
                        priorityIcon(for: item.priority)
                    }
                }
                .padding(.horizontal, -5)
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
