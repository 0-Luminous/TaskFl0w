//
// BottomBar.swift
// ToDoList
//
// Created by Yan on 21/3/25.

import SwiftUI
import UIKit

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
    
    // Обновляем порядок обработчиков для дополнительных кнопок
    var onFlagSelectedTasks: () -> Void
    var onCalendarSelectedTasks: () -> Void
    var onChecklistSelectedTasks: () -> Void = {}

    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Добавляем состояние для отслеживания нажатий
    @State private var isAddButtonPressed = false
    
    // Генератор обратной связи для виброотдачи
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    // MARK: - Body
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Spacer()
                
                if !isSelectionMode {
                    HStack {
                        ZStack {
                            Color.clear
                            archiveButton
                        }

                        
                        Spacer()
                            .frame(width: 25)
                        
                        ZStack {
                            Color.clear
                            selectionModeToggleButton
                        }
                        
                        Spacer()
                            .frame(width: 25)
                        
                        ZStack {
                            Color.clear
                            addButton
                        }
                    }
                    .frame(width: 165)
                } else {
                    HStack(spacing: 16) {

                        ZStack {
                            Color.clear
                            calendarButton     
                        }
                    
                        ZStack {
                            Color.clear
                            flagButton
                        }

                        // ZStack {
                        //     Color.clear
                        //     checklistButton
                        // }
                        
                        ZStack {
                            Color.clear
                            exitSelectionModeButton
                        }

                        ZStack {
                            Color.clear
                            if showCompletedTasksOnly {
                                unarchiveButton
                            } else {
                                deleteButton
                            }
                        }

                        ZStack {
                            Color.clear
                            if showCompletedTasksOnly {
                                archiveActionButton
                            } else {
                                priorityButton
                            }
                        }
                        
                    }
                    .frame(width: 308)
                }
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(height: 52)
            .frame(maxWidth: isSelectionMode ? 340 : 220)
            .background {
                ZStack {
                    // Размытый фон
                    Capsule()
                        .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95))
                    
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
        .padding(.horizontal, isSelectionMode ? 30 : 75)
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
    private var archiveButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            onArchiveTapped()
        }) {
            toolbarIcon(systemName: "archivebox", 
                        color: themeManager.isDarkMode ? showCompletedTasksOnly ? .coral1 : .gray : showCompletedTasksOnly ? .red1 : .black)
        }
    }
    
    private var selectionModeToggleButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "checkmark.circle", color: themeManager.isDarkMode ? .gray : .black)
        }
    }
    
    
    private var deleteButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
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
                feedbackGenerator.impactOccurred()
                onChangePriorityForSelectedTasks()
            }
        }) {
            toolbarIcon(content: {
                priorityIconContent
            }, color: .gray)
        }
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    // Отображение иконки приоритета в виде столбцов
    private var priorityIconContent: some View {
        VStack(spacing: 2) {
            // Показываем три столбца для общей иконки приоритета
            ForEach(0..<3, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 12, height: 3)
            }
        }
        .frame(width: 24, height: 24)
    }
    
    private var exitSelectionModeButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "checkmark.circle", color: themeManager.isDarkMode ? .coral1 : .red1)
        }
        .frame(width: 38, height: 38)
    }
    
    private var unarchiveButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            onUnarchiveSelectedTasks()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "arrow.uturn.backward", color: .green)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var archiveActionButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            onArchiveTapped()
            toggleSelectionMode()
        }) {
            toolbarIcon(systemName: "archivebox", color: themeManager.isDarkMode ? .coral1 : .red1)
        }
    }
    
    private var addButton: some View {
        Button(action: {
            if !showCompletedTasksOnly {
                feedbackGenerator.impactOccurred()
                onAddTap()
            }
        }) {
            toolbarIcon(systemName: "plus", color: themeManager.isDarkMode ? showCompletedTasksOnly ? .gray : .coral1 : showCompletedTasksOnly ? .gray : .red1)
        }
        .frame(width: 38, height: 38)
        .disabled(showCompletedTasksOnly)
        .opacity(showCompletedTasksOnly ? 0.5 : 1.0)
    }
    
    // Новые кнопки для режима выбора
    private var flagButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                feedbackGenerator.impactOccurred()
                onFlagSelectedTasks()
            }
        }) {
            toolbarIcon(systemName: "flag.fill", color: .purple)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var checklistButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                feedbackGenerator.impactOccurred()
                onChecklistSelectedTasks()
            }
        }) {
            toolbarIcon(systemName: "checklist", color: .green)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    private var calendarButton: some View {
        Button(action: {
            if !selectedTasks.isEmpty {
                feedbackGenerator.impactOccurred()
                onCalendarSelectedTasks()
            }
        }) {
            toolbarIcon(systemName: "calendar", color: .blue)
        }
        .frame(width: 38, height: 38)
        .disabled(selectedTasks.isEmpty)
        .opacity(selectedTasks.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func toggleSelectionMode() {
        if isSelectionMode {
            selectedTasks.removeAll()
        }
        isSelectionMode.toggle()
    }
    
    private func toolbarIcon<Content: View>(content: @escaping () -> Content, color: Color) -> some View {
        content()
            .foregroundColor(color)
            .padding(6)
            .background(
                Circle()
                    .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
    
    // Оригинальная версия toolbarIcon для других кнопок
    private func toolbarIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 20))
            .foregroundColor(color)
            .padding(6)
            .background(
                Circle()
                    .fill(themeManager.isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : Color(red: 0.95, green: 0.95, blue: 0.95))
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
