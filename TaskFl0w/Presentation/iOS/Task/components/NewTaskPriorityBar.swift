//
//  NewTaskPriorityBar.swift
//  TaskFl0w
//
//  Created by Yan on 13/5/25.
//

import SwiftUI

struct NewTaskPriorityBar: View {
    @Binding var selectedPriority: TaskPriority
    var onSave: () -> Void
    var onCancel: () -> Void
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Основной контейнер с размытым фоном
            HStack(spacing: 16) {
                // Кнопка "без приоритета" вместо кнопки отмены
                Button(action: {
                    selectedPriority = .none
                }) {
                    // Пустая панель приоритета
                    VStack {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 12))
                            .foregroundColor(selectedPriority == .none ? .white : .gray)
                    }
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .stroke(selectedPriority == .none ? Color.gray : .clear, lineWidth: 1.5)
                    )
                }
                
                // Кнопки приоритета
                priorityButton(priority: .low)
                priorityButton(priority: .medium)
                priorityButton(priority: .high)
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
    }
    
    // MARK: - UI Components
    
    private func priorityButton(priority: TaskPriority) -> some View {
        let color: Color = getPriorityColor(for: priority)
        
        return Button(action: {
            // Устанавливаем выбранный приоритет и сразу сохраняем задачу
            selectedPriority = priority
        }) {
            // Используем тот же индикатор приоритета, что и в TaskRow
            VStack(spacing: 2) {
                ForEach(0..<priority.rawValue, id: \.self) { _ in
                    Rectangle()
                        .fill(selectedPriority == priority ? color : Color.gray)
                        .frame(width: 12, height: 3)
                }
            }
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .stroke(selectedPriority == priority ? color : .clear, lineWidth: 1.5)
            )
        }
    }
    
    // MARK: - Helper Methods
    
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

