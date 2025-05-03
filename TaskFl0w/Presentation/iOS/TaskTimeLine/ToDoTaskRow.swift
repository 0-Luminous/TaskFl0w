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
    
    var body: some View {
        HStack(spacing: 12) {
            // Индикатор выполнения
            Circle()
                .fill(task.isCompleted ? Color.green : Color.clear)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(task.isCompleted ? Color.green : categoryColor.opacity(0.7), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .strikethrough(task.isCompleted)
            }
            
            Spacer()
            
            // Индикатор приоритета
            if task.priority != .none {
                priorityIndicator(for: task.priority)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(getPriorityBorderColor(for: task.priority), lineWidth: task.priority != .none ? 1.5 : 0)
                )
        )
    }
    
    // Индикатор приоритета
    private func priorityIndicator(for priority: TaskPriority) -> some View {
        VStack(spacing: 1) {
            ForEach(0..<priority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(getPriorityColor(for: priority))
                    .frame(width: 8, height: 2)
            }
        }
    }
    
    // Цвет приоритета
    private func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return Color.green
        case .none:
            return Color.gray
        }
    }
    
    // Цвет рамки для приоритета
    private func getPriorityBorderColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return Color.red.opacity(0.6)
        case .medium:
            return Color.orange.opacity(0.5)
        case .low:
            return Color.green.opacity(0.4)
        case .none:
            return Color.clear
        }
    }
}

#Preview {
    ToDoTaskRow(task: ToDoItem(title: "Test", priority: .high), categoryColor: .red)
}