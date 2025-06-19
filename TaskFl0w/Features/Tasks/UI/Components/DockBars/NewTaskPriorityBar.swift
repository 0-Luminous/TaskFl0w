//
//  NewTaskPriorityBar.swift
//  TaskFl0w
//
//  Created by Yan on 13/5/25.
//

import SwiftUI
import UIKit

struct NewTaskPriorityBar: View {
    @Binding var selectedPriority: TaskPriority
    @Binding var showPrioritySelection: Bool
    var onSave: () -> Void
    var onCancel: () -> Void
    let hapticsManager = HapticsManager.shared

    @ObservedObject private var themeManager = ThemeManager.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 0) {
                Spacer()
                
                // Четыре основные кнопки
                HStack {
                    // Кнопка календаря
                    ZStack {
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        calendarButton
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 15)
                    
                    // Кнопка флага
                    ZStack {
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        flagButton
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 15)
                    
                    // Кнопка чек-листа
                    ZStack {
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        checklistButton
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 15)
                    
                    // Кнопка приоритета
                    ZStack {
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        priorityButton
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(width: 245) // Увеличиваем ширину для четырех кнопок
                
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(height: 52)
            .frame(maxWidth: 300) // Увеличиваем максимальную ширину
            .background {
                ZStack {
                    Capsule()
                        .fill(themeManager.isDarkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.95))
                    
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
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
    private var calendarButton: some View {
        Button(action: {
            hapticsManager.triggerLightFeedback()
        }) {
            toolbarIcon(content: {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
            }, color: themeManager.isDarkMode ? Color(red: 1.0, green: 0.3, blue: 0.3) : Color(red: 1.0, green: 0.5, blue: 0.3), isSelected: false)
        }
    }
    
    private var flagButton: some View {
        Button(action: {
            hapticsManager.triggerLightFeedback()
        }) {
            toolbarIcon(content: {
                Image(systemName: "flag.fill")
                    .font(.system(size: 16, weight: .medium))
            }, color: .yellow, isSelected: false)
        }
    }
    
    private var checklistButton: some View {
        Button(action: {
            hapticsManager.triggerLightFeedback()
        }) {
            toolbarIcon(content: {
                Image(systemName: "checklist")
                    .font(.system(size: 16, weight: .medium))
            }, color: .green, isSelected: false)
        }
    }
    
    private var priorityButton: some View {
        Button(action: {
            hapticsManager.triggerLightFeedback()
            showPrioritySelection.toggle()
        }) {
            toolbarIcon(content: {
                priorityIconContent
            }, color: selectedPriority != .none ? getPriorityColor(for: selectedPriority) : .gray, isSelected: selectedPriority != .none)
        }
    }
    
    // Отображение иконки приоритета в виде столбцов
    private var priorityIconContent: some View {
        VStack(spacing: 2) {
            if selectedPriority == .none {
                // Если приоритет не выбран, показываем три серых столбца
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 12, height: 3)
                }
            } else {
                // Показываем столбцы в соответствии с выбранным приоритетом
                ForEach(0..<selectedPriority.rawValue, id: \.self) { _ in
                    Rectangle()
                        .fill(getPriorityColor(for: selectedPriority))
                        .frame(width: 12, height: 3)
                }
            }
        }
        .frame(width: 20, height: 20)
    }
    
    // MARK: - Helper Methods
    
    private func toolbarIcon<Content: View>(content: @escaping () -> Content, color: Color, isSelected: Bool = false) -> some View {
        content()
            .foregroundColor(color)
            .frame(width: 20, height: 20)
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
            .shadow(color: isSelected ? color.opacity(0.5) : .black.opacity(0.3), radius: isSelected ? 5 : 3, x: 0, y: 1)
    }
    
    private func getPriorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .high:
            return .red
        case .medium:
            return .orange
        case .low:
            return .green
        case .none:
            return .gray
        }
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedPriority: TaskPriority = .none
        @State private var showPrioritySelection: Bool = false
        
        var body: some View {
            ZStack {
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    NewTaskPriorityBar(
                        selectedPriority: $selectedPriority,
                        showPrioritySelection: $showPrioritySelection,
                        onSave: { print("Save task") },
                        onCancel: { print("Cancel") }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}

