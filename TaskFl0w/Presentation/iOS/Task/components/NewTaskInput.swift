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
    var onSave: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            TextField("Новая задача", text: $newTaskTitle, axis: .vertical)
                .foregroundColor(.white)
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
        }
        .padding(.horizontal, 10)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.darkGray))
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
        )
        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0)) // Добавляем верхний и нижний отступы для строки
        .listRowSeparator(.hidden)
    }
}

#Preview {
    @State var text = ""
    @FocusState var focus
    
    NewTaskInput(
        newTaskTitle: $text,
        isNewTaskFocused: _focus,
        onSave: {}
    )
    .background(Color(red: 0.098, green: 0.098, blue: 0.098))
}

