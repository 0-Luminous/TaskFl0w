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
    var onSave: () -> Void
    var onCancel: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 0) {
                Spacer()
                
                // Используем фиксированные фреймы для гарантии стабильного положения
                HStack {
                    
                    // Центральная кнопка - низкий приоритет
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        priorityButtonLow
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Правая кнопка - средний приоритет
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        priorityButtonMedium
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Крайняя правая кнопка - высокий приоритет
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        priorityButtonHigh
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(width: 215) // Увеличиваем ширину для 4-х кнопок
                
                Spacer()
            }
            .padding(.horizontal, 6) // Уменьшенный внутренний отступ для более короткого бара
            .padding(.vertical, 8)
            .frame(height: 52) // Немного уменьшаем высоту
            .frame(maxWidth: 270) // Увеличиваем ширину для 4-х кнопок
            .background {
                ZStack {
                    // Размытый фон с уменьшенной шириной
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
        .padding(.horizontal, 50) // Немного уменьшаем боковые отступы для бара с 4 кнопками
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
    private var priorityButtonLow: some View {
        Button(action: {
            generateFeedback()
            if selectedPriority == .low {
                selectedPriority = .none
            } else {
                selectedPriority = .low
            }
            onSave()
        }) {
            priorityIconView(priority: .low)
        }
    }
    
    private var priorityButtonMedium: some View {
        Button(action: {
            generateFeedback()
            if selectedPriority == .medium {
                selectedPriority = .none
            } else {
                selectedPriority = .medium
            }
            onSave()
        }) {
            priorityIconView(priority: .medium)
        }
    }
    
    private var priorityButtonHigh: some View {
        Button(action: {
            generateFeedback()
            if selectedPriority == .high {
                selectedPriority = .none
            } else {
                selectedPriority = .high
            }
            onSave()
        }) {
            priorityIconView(priority: .high)
        }
    }
    
    // MARK: - Helper Methods
    
    private func priorityIconView(priority: TaskPriority) -> some View {
        let color = getPriorityColor(for: priority)
        let isSelected = selectedPriority == priority
        
        return toolbarIcon(content: {
            VStack(spacing: 2) {
                ForEach(0..<priority.rawValue, id: \.self) { _ in
                    Rectangle()
                        .fill(isSelected ? color : Color.gray)
                        .frame(width: 12, height: 3)
                }
            }
            .frame(width: 20, height: 20)
        }, color: isSelected ? color : .gray, isSelected: isSelected)
    }
    
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
    
    private func generateFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Preview
#Preview {
    struct PreviewWrapper: View {
        @State private var selectedPriority: TaskPriority = .none
        
        var body: some View {
            ZStack {
                // Добавляем темный фон для лучшей визуализации
                Color(red: 0.098, green: 0.098, blue: 0.098)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    NewTaskPriorityBar(
                        selectedPriority: $selectedPriority,
                        onSave: { print("Save task") },
                        onCancel: { print("Cancel") }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}

