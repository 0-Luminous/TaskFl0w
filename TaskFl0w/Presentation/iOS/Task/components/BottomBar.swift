//
// BottomBar.swift
// ToDoList
//
// Created by Yan on 21/3/25.

import SwiftUI

struct BottomBar: View {
    // MARK: - Properties
    let onAddTap: () -> Void
    @Binding var isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    var onDeleteSelectedTasks: () -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 0) {
            if !isSelectionMode {
                normalModeButtons
            } else {
                selectionModeButtons
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - UI Components
    
    /// Кнопки в обычном режиме
    private var normalModeButtons: some View {
        HStack {
            Spacer()
            
            archiveButton
            
            Spacer()
            
            selectionModeToggleButton
            
            Spacer()
            
            addButton
            
            Spacer()
        }
    }
    
    /// Кнопки в режиме выбора
    private var selectionModeButtons: some View {
        HStack {
            Spacer()
            
            priorityButton

            Spacer()
            
            groupButton
            
            Spacer()
            
            exitSelectionModeButton
            
            Spacer()
            
            deleteButton
            
            Spacer()
        }
    }
    
    private var archiveButton: some View {
        Button(action: onAddTap) {
            circleIconImage(systemName: "archivebox.circle.fill", color: .gray)
                .frame(width: 44, height: 44)
        }
    }
    
    private var selectionModeToggleButton: some View {
        Button(action: toggleSelectionMode) {
            circleIconImage(systemName: "checkmark.circle.fill", color: .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
    
    private var addButton: some View {
        Button(action: onAddTap) {
            circleIconImage(systemName: "plus.circle.fill", color: .blue)
                .frame(width: 44, height: 44)
        }
    }
    
    private var deleteButton: some View {
        Button(action: {
            onDeleteSelectedTasks()
            // После удаления выходим из режима выбора
            toggleSelectionMode()
        }) {
            circleIconImage(systemName: "trash.circle.fill", color: .red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var priorityButton: some View {
        Button(action: {
            // Действие для изменения приоритета задач
        }) {
            circleIconImage(systemName: "arrow.uturn.up.circle.fill", color: .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
    
    private var groupButton: some View {
        Button(action: {
            // Действие для удаления выбранных задач
        }) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.098, green: 0.098, blue: 0.098))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Circle().fill(Color.gray))
                .cornerRadius(20)
        }
    }
    
    private var exitSelectionModeButton: some View {
        Button(action: toggleSelectionMode) {
            circleIconImage(systemName: "checkmark.circle.badge.xmark.fill", color: .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelectionMode() {
        if isSelectionMode {
            selectedTasks.removeAll()
        }
        isSelectionMode.toggle()
    }
    
    private func circleIconImage(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .foregroundColor(color)
            .font(.system(size: 40))
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var isSelectionMode = false
        @State private var selectedTasks: Set<UUID> = []
        
        var body: some View {
            BottomBar(
                onAddTap: { print("Add tapped") }, 
                isSelectionMode: $isSelectionMode,
                selectedTasks: $selectedTasks,
                onDeleteSelectedTasks: { print("Delete selected tasks") }
            )
        }
    }
    
    return PreviewWrapper()
}
