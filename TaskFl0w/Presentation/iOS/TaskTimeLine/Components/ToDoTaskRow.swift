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
            .fill(task.isCompleted ? Color.green : Color.clear)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(task.isCompleted ? Color.green : categoryColor.opacity(0.7), lineWidth: 1)
            )
    }
    
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .strikethrough(task.isCompleted)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
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
            .fill(themeManager.isDarkMode ? Color(red: 0.25, green: 0.25, blue: 0.25) : Color(red: 0.9, green: 0.9, blue: 0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(priorityBorderColor, lineWidth: task.priority != .none ? 1.5 : 0)
            )
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
    
    // MARK: - Private Methods
    
    private func handleTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        onToggle?()
    }
}

#Preview {
    ToDoTaskRow(task: ToDoItem(title: "Test", priority: .high), categoryColor: .red)
}