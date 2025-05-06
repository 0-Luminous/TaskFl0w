//
//  TimelineBar.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

struct TimelineBar: View {
    // MARK: - Properties
    let onTodayTap: () -> Void
    let onAddTaskTap: () -> Void
    let onInfoTap: () -> Void
    
    @State private var isAddButtonPressed = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 0) {
                Spacer()
                
                // Используем фиксированные фреймы для гарантии стабильного положения
                HStack {
                    // Левая кнопка (Сегодня)
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        todayButton
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Центральная кнопка (Добавить задачу)
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        addTaskButton
                    }
                    .frame(width: 38, height: 38)
                    
                    Spacer()
                        .frame(width: 25) // Уменьшенное расстояние между кнопками
                    
                    // Правая кнопка (Информация)
                    ZStack {
                        // Контейнер фиксированного размера
                        Color.clear
                            .frame(width: 38, height: 38)
                        
                        infoButton
                    }
                    .frame(width: 38, height: 38)
                }
                .frame(width: 165) // Уменьшенная ширина для всей группы кнопок
                
                Spacer()
            }
            .padding(.horizontal, 6) // Уменьшенный внутренний отступ для более короткого бара
            .padding(.vertical, 8)
            .frame(height: 52) // Немного уменьшаем высоту
            .frame(maxWidth: 220) // Еще больше ограничиваем максимальную ширину 
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
        .padding(.horizontal, 75) // Еще больше увеличиваем боковые отступы для более короткого бара
        .padding(.bottom, 8)
    }
    
    // MARK: - UI Components
    
    private var todayButton: some View {
        Button(action: onTodayTap) {
            toolbarIcon(systemName: "calendar.day.timeline.left", color: .gray)
        }
    }
    
    private var addTaskButton: some View {
        Button(action: onAddTaskTap) {
            toolbarIcon(systemName: "checkmark.circle", color: .gray)
        }
    }
    
    private var infoButton: some View {
        Button(action: onInfoTap) {
            toolbarIcon(systemName: "info.circle", color: .gray)
        }
    }
    
    // MARK: - Helper Methods
    
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
                    TimelineBar(
                        onTodayTap: { print("Today tapped") },
                        onAddTaskTap: { print("Add task tapped") },
                        onInfoTap: { print("Info tapped") }
                    )
                }
            }
        }
    }
    
    return PreviewWrapper()
}

