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
            taskContentZone
                .background(taskBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
            
            Spacer()
            
            actionZone
        }
        .animation(.easeInOut(duration: 0.3), value: item.priority)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
    }
    
    private var taskContentZone: some View {
        HStack(spacing: 12) {

            if item.priority != .none {
                TaskPriorityIndicator(
                    priority: item.priority,
                    isCompleted: item.isCompleted,
                    isSelectionMode: isSelectionMode,
                    isInArchiveMode: isInArchiveMode
                )
                .padding(.leading, 10)
            }

            TaskContentView(
                item: item,
                isSelectionMode: isSelectionMode,
                isInArchiveMode: isInArchiveMode
            )
            .padding(.leading, item.priority != .none ? 0 : 10)
            
            Spacer()
            
        }
        .padding(.vertical, 10)
    }
    
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
    
    private var taskBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(taskBackgroundColor)
            
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
    
    private var taskBackgroundColor: Color {
        if themeManager.isDarkMode {
            return Color(red: 0.2, green: 0.2, blue: 0.2)
        } else {
            return Color(red: 0.9, green: 0.9, blue: 0.9)
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
    
    private var isSelected: Bool {
        selectedTasks.contains(item.id)
    }
    
    private func toggleSelection() {
        if selectedTasks.contains(item.id) {
            selectedTasks.remove(item.id)
        } else {
            selectedTasks.insert(item.id)
        }
    }
}
