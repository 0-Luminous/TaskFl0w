//
//  NewTaskInput.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

struct NewTaskInput: View {
    @Binding var newTaskTitle: String
    @FocusState var isNewTaskFocused: Bool
    @Binding var selectedPriority: TaskPriority
    var onSave: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    
    
    var body: some View {
        HStack(alignment: .center) {
            TextField("task.newTask".localized(), text: $newTaskTitle, axis: .vertical)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .lineLimit(3) // Разрешить до 3 строк
                .onSubmit {
                    onSave()
                }
                .submitLabel(.done)
                .focused($isNewTaskFocused)
                .keyboardType(.default)
                .autocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.leading, 5) // Добавляем отступ слева 5 пикселей
                .padding(.vertical, 8) // Добавляем вертикальный отступ
                // Специальный модификатор для обработки ввода
                .onChange(of: newTaskTitle) { oldValue, newValue in
                    // Если в тексте есть символ новой строки, значит была нажата кнопка Return
                    if newValue.contains("\n") {
                        // Удаляем символ новой строки
                        newTaskTitle = newValue.replacingOccurrences(of: "\n", with: "")
                        // Сохраняем задачу
                        onSave()
                    }
                }
                .fixedSize(horizontal: false, vertical: true) // Позволяет расширяться по вертикали
            
            // Иконка приоритета, если приоритет выбран
            if selectedPriority != .none {
                priorityIcon
            }
        }
        .padding(.horizontal, 10)
        .listRowBackground(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                
                // Добавляем бордер для выбранного приоритета
                if selectedPriority != .none {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(getPriorityColor(for: selectedPriority), lineWidth: 1.5)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                }
            }
        )
        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) // Добавляем верхний и нижний отступы для строки
        .listRowSeparator(.hidden)
    }
    
    // Индикатор приоритета
    private var priorityIcon: some View {
        // Используем тот же индикатор приоритета, что и в TaskRow
        VStack(spacing: 2) {
            ForEach(0..<selectedPriority.rawValue, id: \.self) { _ in
                Rectangle()
                    .fill(getPriorityColor(for: selectedPriority))
                    .frame(width: 12, height: 3)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 3)
        .padding(.trailing, 12)
    }
    
    // Цвет для приоритета
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

#Preview {
    @State var text = ""
    @State var priority: TaskPriority = .none
    @FocusState var focus
    
    NewTaskInput(
        newTaskTitle: $text,
        isNewTaskFocused: _focus,
        selectedPriority: $priority,
        onSave: {}
    )
    .background(Color(red: 0.098, green: 0.098, blue: 0.098))
}

