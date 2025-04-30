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
    var onChangePriorityForSelectedTasks: () -> Void
    var onArchiveTapped: () -> Void
    var onUnarchiveSelectedTasks: () -> Void
    @Binding var showCompletedTasksOnly: Bool
    
    // Добавляем состояние для отслеживания нажатий
    @State private var isAddButtonPressed = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 16) {
                if !isSelectionMode {
                    normalModeButtons
                } else {
                    selectionModeButtons
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: 56)
            .background {
                // Размытый фон
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .animation(nil, value: isAddButtonPressed)
    }
    
    // MARK: - UI Components
    
    /// Кнопки в обычном режиме
    private var normalModeButtons: some View {
        HStack(spacing: 24) {
            archiveButton
            selectionModeToggleButton
            addButton
        }
    }
    
    /// Кнопки в режиме выбора
    private var selectionModeButtons: some View {
        HStack(spacing: 24) {
            // Показываем разные кнопки в зависимости от режима
            if showCompletedTasksOnly {
                // В режиме архива показываем кнопку архивации
                archiveActionButton
            } else {
                // В обычном режиме показываем кнопку изменения приоритета
                priorityButton
            }
            
            exitSelectionModeButton
            
            // Разные кнопки в зависимости от режима
            if showCompletedTasksOnly {
                // В режиме архива показываем кнопку возврата из архива
                unarchiveButton
            } else {
                // В обычном режиме показываем кнопку удаления
                deleteButton
            }
        }
    }
    
    private var archiveButton: some View {
        Button(action: onArchiveTapped) {
            toolbarIcon(systemName: "archivebox.fill", 
                       color: showCompletedTasksOnly ? .blue : .gray)
        }
    }
    
    private var selectionModeToggleButton: some View {
        Button(action: toggleSelectionMode) {
            toolbarIcon(systemName: "checkmark.circle", color: .gray)
        }
    }
    
    
    private var deleteButton: some View {
        Button(action: {
            onDeleteSelectedTasks()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "trash", color: .red)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var priorityButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                onChangePriorityForSelectedTasks()
            }
        }) {
            toolbarIcon(systemName: "arrow.up.arrow.down", color: .gray)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var exitSelectionModeButton: some View {
        Button(action: toggleSelectionMode) {
            toolbarIcon(systemName: "xmark", color: .blue)
        }
    }
    
    private var unarchiveButton: some View {
        Button(action: {
            onUnarchiveSelectedTasks()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "arrow.uturn.backward", color: .green)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var archiveActionButton: some View {
        Button(action: {
            onArchiveTapped()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "archivebox", color: .blue)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            if !showCompletedTasksOnly {
                onAddTap()
            }
        }) {
            toolbarIcon(systemName: "plus", color: showCompletedTasksOnly ? .gray : .blue)
        }
        .disabled(showCompletedTasksOnly)
        .opacity(showCompletedTasksOnly ? 0.5 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelectionMode() {
        if isSelectionMode {
            selectedTasks.removeAll()
        }
        isSelectionMode.toggle()
    }
    
    private func toolbarIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 22))
            .foregroundColor(color)
            .frame(width: 36, height: 36)
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var isSelectionMode = false
        @State private var selectedTasks: Set<UUID> = []
        @State private var showCompletedTasksOnly = false
        
        var body: some View {
            ZStack {
                // Добавляем градиентный фон для лучшей визуализации эффекта размытия
                LinearGradient(
                    colors: [.blue.opacity(0.6), Color(uiColor: .systemBackground)],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    BottomBar(
                        onAddTap: { print("Add tapped") }, 
                        isSelectionMode: $isSelectionMode,
                        selectedTasks: $selectedTasks,
                        onDeleteSelectedTasks: { print("Delete selected tasks") },
                        onChangePriorityForSelectedTasks: { print("Change priority for selected tasks") },
                        onArchiveTapped: { print("Archive completed tasks") },
                        onUnarchiveSelectedTasks: { print("Unarchive selected tasks") },
                        showCompletedTasksOnly: $showCompletedTasksOnly
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}
