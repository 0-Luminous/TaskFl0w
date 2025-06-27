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

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 0) {
            // ЗОНА ЗАДАЧИ: Основной контент + приоритет
            taskContentZone
                .background(taskBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // РАЗДЕЛИТЕЛЬ между зонами
            Spacer()
                .frame(width: 16)
            
            // ЗОНА ДЕЙСТВИЙ: Completion Indicator вне зоны задачи
            actionZone
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: item.priority)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
    }
    
    // MARK: - Task Content Zone
    
    private var taskContentZone: some View {
        HStack(spacing: 12) {
            // Основной контент задачи
            TaskContentView(
                item: item,
                isSelectionMode: isSelectionMode,
                isInArchiveMode: isInArchiveMode
            )
            .padding(.leading, 16)
            
            Spacer()
            
            // Индикатор приоритета (остается внутри зоны задачи)
            if item.priority != .none {
                TaskPriorityIndicator(
                    priority: item.priority,
                    isCompleted: item.isCompleted,
                    isSelectionMode: isSelectionMode,
                    isInArchiveMode: isInArchiveMode
                )
                .padding(.trailing, 16)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Action Zone (Completion Indicator)
    
    private var actionZone: some View {
        VStack {
            TaskCompletionIndicator(
                isCompleted: item.isCompleted,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode,
                categoryColor: categoryColor,
                onToggle: isSelectionMode ? toggleSelection : onToggle
            )
        }
        .frame(width: 24, height: 24)
        .clipShape(Circle())
    }
    
    // MARK: - Background Styles
    
    private var taskBackground: some View {
        ZStack {
            // Основной фон задачи
            RoundedRectangle(cornerRadius: 12)
                .fill(taskBackgroundColor)
                .shadow(
                    color: themeManager.isDarkMode ? .black.opacity(0.4) : .gray.opacity(0.15),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            
            // Рамка приоритета
            if item.priority != .none {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priorityBorderColor, lineWidth: 1.5)
                    .opacity(priorityBorderOpacity)
            }
        }
    }
    
    private var actionZoneBackground: some View {
        Circle()
            .fill(actionZoneBackgroundColor)
            .overlay(
                Circle()
                    .stroke(actionZoneBorderColor, lineWidth: 1)
                    .opacity(0.1)
            )
    }
    
    // MARK: - Color Computed Properties
    
    private var taskBackgroundColor: Color {
        if themeManager.isDarkMode {
            return Color(red: 0.18, green: 0.18, blue: 0.18)
        } else {
            return Color(red: 0.98, green: 0.98, blue: 0.98)
        }
    }
    
    private var actionZoneBackgroundColor: Color {
        if isSelectionMode && isSelected {
            return categoryColor.opacity(0.15)
        }
        
        if themeManager.isDarkMode {
            return Color(red: 0.22, green: 0.22, blue: 0.22)
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }
    
    private var actionZoneBorderColor: Color {
        if isSelectionMode && isSelected {
            return categoryColor
        }
        
        return themeManager.isDarkMode ? .white.opacity(0.1) : .black.opacity(0.05)
    }
    
    private var priorityBorderColor: Color {
        switch item.priority {
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
    
    private var priorityBorderOpacity: Double {
        let isCompletedAndNotInteractive = item.isCompleted && !isSelectionMode && !isInArchiveMode
        return isCompletedAndNotInteractive || isInArchiveMode ? 0.3 : 1.0
    }
    
    // MARK: - Private Computed Properties
    
    private var isSelected: Bool {
        selectedTasks.contains(item.id)
    }
    
    // MARK: - Private Methods
    
    private func toggleSelection() {
        if selectedTasks.contains(item.id) {
            selectedTasks.remove(item.id)
        } else {
            selectedTasks.insert(item.id)
        }
    }
}

// MARK: - Preview
struct TaskRow_Previews: PreviewProvider {
    @State static var selectedTasks: Set<UUID> = []
    
    static var previews: some View {
        VStack(spacing: 16) {
            // Обычная задача
            TaskRow(
                item: ToDoItem(
                    title: "Обычная задача",
                    isCompleted: false,
                    priority: .medium,
                    deadline: Date().addingTimeInterval(3600)
                ),
                onToggle: {},
                onEdit: {},
                onDelete: {},
                onShare: {},
                categoryColor: .blue,
                isSelectionMode: false,
                isInArchiveMode: false,
                selectedTasks: $selectedTasks
            )
            
            // Завершенная задача
            TaskRow(
                item: ToDoItem(
                    title: "Завершенная задача с длинным названием",
                    isCompleted: true,
                    priority: .high
                ),
                onToggle: {},
                onEdit: {},
                onDelete: {},
                onShare: {},
                categoryColor: .blue,
                isSelectionMode: false,
                isInArchiveMode: false,
                selectedTasks: $selectedTasks
            )
            
            // Задача в режиме выбора
            TaskRow(
                item: ToDoItem(
                    title: "Выбранная задача",
                    isCompleted: false,
                    priority: .low,
                    deadline: Calendar.current.date(byAdding: .day, value: 1, to: Date())
                ),
                onToggle: {},
                onEdit: {},
                onDelete: {},
                onShare: {},
                categoryColor: .green,
                isSelectionMode: true,
                isInArchiveMode: false,
                selectedTasks: .constant([UUID()])
            )
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .environment(\.colorScheme, .light)
    }
}
