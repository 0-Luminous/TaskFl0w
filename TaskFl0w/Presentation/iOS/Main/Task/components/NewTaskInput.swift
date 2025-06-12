//
//  NewTaskInput.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

struct NewTaskInput: View {
    @Binding var newTaskTitle: String
    @Binding var newTaskNotes: String
    @FocusState var isNewTaskFocused: Bool
    @FocusState var isNotesFocused: Bool
    @Binding var selectedPriority: TaskPriority
    var onSave: () -> Void

    @ObservedObject private var themeManager = ThemeManager.shared
    
    
    var body: some View {
        VStack(spacing: 8) {
            // Основное поле ввода задачи
            HStack(alignment: .center) {
                TextField("task.newTask".localized(), text: $newTaskTitle, axis: .vertical)
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .lineLimit(3) // Разрешить до 3 строк
                    .onSubmit {
                        // При нажатии Done переходим к заметкам или сохраняем
                        if newTaskNotes.isEmpty {
                            isNotesFocused = true
                        } else {
                            onSave()
                        }
                    }
                    .submitLabel(.next)
                    .focused($isNewTaskFocused)
                    .keyboardType(.default)
                    .autocapitalization(.sentences)
                    .disableAutocorrection(false)
                    .padding(.leading, 5)
                    .padding(.vertical, 2)
                    .onChange(of: newTaskTitle) { oldValue, newValue in
                        if newValue.contains("\n") {
                            newTaskTitle = newValue.replacingOccurrences(of: "\n", with: "")
                            // Переходим к заметкам вместо сохранения
                            isNotesFocused = true
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                
                // Иконка приоритета, если приоритет выбран
                if selectedPriority != .none {
                    priorityIcon
                }
            }
            
            // Поле для заметок
            TextField("Заметки (необязательно)", text: $newTaskNotes, axis: .vertical)
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.8) : .black.opacity(0.7))
                .font(.system(size: 14))
                .lineLimit(2)
                .onSubmit {
                    onSave()
                }
                .submitLabel(.done)
                .focused($isNotesFocused)
                .keyboardType(.default)
                .autocapitalization(.sentences)
                .disableAutocorrection(false)
                .padding(.leading, 5)
                .padding(.vertical, 2)
                .onChange(of: newTaskNotes) { oldValue, newValue in
                    if newValue.contains("\n") {
                        newTaskNotes = newValue.replacingOccurrences(of: "\n", with: "")
                        onSave()
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 6)
        .listRowBackground(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                
                // Добавляем бордер для выбранного приоритета
                if selectedPriority != .none {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(getPriorityColor(for: selectedPriority), lineWidth: 1.5)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
        )
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
        // .padding(.trailing, 5)
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
    @State var notes = ""
    @State var priority: TaskPriority = .none
    @FocusState var focus
    @FocusState var notesFocus
    
    NewTaskInput(
        newTaskTitle: $text,
        newTaskNotes: $notes,
        isNewTaskFocused: _focus,
        isNotesFocused: _notesFocus,
        selectedPriority: $priority,
        onSave: {}
    )
    .background(Color(red: 0.098, green: 0.098, blue: 0.098))
}

