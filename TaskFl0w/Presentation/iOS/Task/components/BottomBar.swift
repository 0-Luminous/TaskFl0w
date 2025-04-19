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
        // Оборачиваем весь BottomBar в ZStack с фиксированной высотой
        ZStack {
            // Фоновый слой - неизменяемый
            Color.clear
                .frame(height: 60) // Высота фиксирована
            
            // Контент - все наши кнопки
            HStack(spacing: 0) {
                if !isSelectionMode {
                    normalModeButtons
                } else {
                    selectionModeButtons
                }
            }
            .padding(.horizontal)
        }
        // Делаем фрейм фиксированным!
        .frame(height: 60)
        // Отключаем анимации для BottomBar
        .animation(nil, value: isAddButtonPressed)
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
            
            // Для кнопки добавления используем другой подход
            addButton
            
            Spacer()
        }
    }
    
    /// Кнопки в режиме выбора
    private var selectionModeButtons: some View {
        HStack {
            Spacer()
            
            // Показываем разные кнопки в зависимости от режима
            if showCompletedTasksOnly {
                // В режиме архива показываем кнопку архивации
                archiveActionButton
            } else {
                // В обычном режиме показываем кнопку изменения приоритета
                priorityButton
            }
            
            Spacer()
            
            exitSelectionModeButton
            
            Spacer()
            
            // Разные кнопки в зависимости от режима
            if showCompletedTasksOnly {
                // В режиме архива показываем кнопку возврата из архива
                unarchiveButton
            } else {
                // В обычном режиме показываем кнопку удаления
                deleteButton
            }
            
            Spacer()
        }
    }
    
    private var archiveButton: some View {
        Button(action: onArchiveTapped) {
            circleIconImage(
                systemName: "archivebox.circle.fill", 
                color: showCompletedTasksOnly ? .blue : .gray
            )
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
            if !selectedTasks.isEmpty {
                onChangePriorityForSelectedTasks()
            }
        }) {
            circleIconImage(systemName: "arrow.uturn.up.circle.fill", color: selectedTasks.isEmpty ? .gray : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var exitSelectionModeButton: some View {
        Button(action: toggleSelectionMode) {
            circleIconImage(systemName: "checkmark.circle.badge.xmark.fill", color: .blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
    }
    
    // Кнопка для возврата задач из архива
    private var unarchiveButton: some View {
        Button(action: {
            onUnarchiveSelectedTasks()
            // После возврата из архива выходим из режима выбора
            toggleSelectionMode()
        }) {
            circleIconImage(systemName: "arrow.uturn.backward.circle.fill", color: .green)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    // Кнопка для архивных действий
    private var archiveActionButton: some View {
        Button(action: {
            // Просто переключаем режим архива (так же, как и обычная кнопка архива)
            onArchiveTapped()
            // После действия выходим из режима выбора
            toggleSelectionMode()
        }) {
            circleIconImage(
                systemName: "archivebox.circle.fill", 
                color: .blue  // Всегда активная, синего цвета
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // Вместо стандартного Button используем наш собственный компонент
    private func customButton(_ icon: String, color: Color, action: @escaping () -> Void, disabled: Bool = false) -> some View {
        Color.clear
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 40))
            )
            .onTapGesture {
                if !disabled {
                    action()
                }
            }
            .opacity(disabled ? 0.5 : 1.0)
    }
    
    private var addButton: some View {
        Color.clear
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(showCompletedTasksOnly ? .gray : .blue)
                    .font(.system(size: 40))
            )
            .onTapGesture {
                if !showCompletedTasksOnly {
                    onAddTap()
                }
            }
            .opacity(showCompletedTasksOnly ? 0.5 : 1.0)
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
        @State private var showCompletedTasksOnly = false
        
        var body: some View {
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
    
    return PreviewWrapper()
}
