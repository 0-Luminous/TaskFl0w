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
            HStack(spacing: 0) {
                Spacer()
                
                // Используем фиксированные фреймы для гарантии стабильного положения
                HStack {
                    // Левая кнопка
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        // Содержимое в зависимости от режима
                        if !isSelectionMode {
                            archiveButton
                        } else if showCompletedTasksOnly {
                            archiveActionButton
                        } else {
                            priorityButton
                        }
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Центральная кнопка
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        // Содержимое в зависимости от режима
                        if !isSelectionMode {
                            selectionModeToggleButton
                        } else {
                            exitSelectionModeButton
                        }
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Правая кнопка
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        // Содержимое в зависимости от режима
                        if !isSelectionMode {
                            addButton
                        } else if showCompletedTasksOnly {
                            unarchiveButton
                        } else {
                            deleteButton
                        }
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(width: 165) // Уменьшенная ширина для всей группы кнопок
                
                Spacer()
            }
            .padding(.horizontal, 6) // Уменьшенный внутренний отступ для более короткого бара
            .padding(.vertical, 8)
            .frame(height: 52) // Немного уменьшаем высоту
            .frame(maxWidth: 220) // Еще больше ограничиваем максимальную ширину BottomBar
            .background {
                ZStack {
                    // Размытый фон с уменьшенной шириной
                    Capsule()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                    
                    // Добавляем градиентный бордер
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.5, green: 0.5, blue: 0.5, opacity: 0.5),
                                    Color(red: 0.3, green: 0.3, blue: 0.3, opacity: 0.3),
                                    Color(red: 0.1, green: 0.1, blue: 0.1, opacity: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
            }
        }
        .padding(.horizontal, 75) // Еще больше увеличиваем боковые отступы для более короткого BottomBar
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
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
            toolbarIcon(systemName: "checkmark.circle", color: .blue)
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
            .font(.system(size: 20))
            .foregroundColor(color)
            .padding(6)
            .background(
                Circle()
                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
            )
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.7), Color.gray.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
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
