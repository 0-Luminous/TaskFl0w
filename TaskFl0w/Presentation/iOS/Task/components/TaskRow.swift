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
    @Binding var selectedTasks: Set<UUID>
    
    @State private var isLongPressed: Bool = false
    
    var body: some View {
        ZStack {
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
                    
                    Text(item.title)
                        .strikethrough(item.isCompleted && !isSelectionMode)
                        .foregroundColor(item.isCompleted && !isSelectionMode ? .gray : .white)
                    
                    Spacer()
                    
                    // Отображаем индикатор приоритета, если он не .none
                    if item.priority != .none {
                        priorityIndicator(for: item.priority)
                    }
                }
                .padding(.horizontal, -10)
            }
        }
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
    
    // Метод для отображения индикатора приоритета
    private func priorityIndicator(for priority: TaskPriority) -> some View {
        let color: Color
        let text: String
        
        switch priority {
        case .high:
            color = .red
            text = "!"
        case .medium:
            color = .orange
            text = "!"
        case .low:
            color = .green
            text = "!"
        case .none:
            color = .clear
            text = ""
        }
        
        return Text(text)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(color)
    }
}
