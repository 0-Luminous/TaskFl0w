//
//  SearchBar.swift
//  ToDoList
//
//  Created by Yan on 23/3/25.
//
import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @Binding var isActive: Bool
    
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 6)
            
            ZStack(alignment: .trailing) {
                TextField("Search", text: $text)
                    .padding(.vertical, 10)
                    .font(.system(size: 17))
                    .focused($isFocused)
                    .onChange(of: isFocused) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isActive = newValue || !text.isEmpty
                        }
                    }
                    .onChange(of: text) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isActive = isFocused || !newValue.isEmpty
                        }
                    }
                
                // Показываем кнопку очистки, только если есть текст
                if !text.isEmpty {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                }
            }
            
            // Показываем кнопку "Отмена", когда поле активно
            if isActive {
                Button("Отмена") {
                    text = ""
                    isFocused = false
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isActive = false
                    }
                }
                .padding(.trailing, 8)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(Color(red: 0.2, green: 0.2, blue: 0.2))
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .onAppear {
            // При появлении проверяем, есть ли текст
            if !text.isEmpty {
                isActive = true
            }
        }
    }
}

// Конструктор для обратной совместимости
extension SearchBar {
    init(text: Binding<String>) {
        self._text = text
        self._isActive = .constant(false)
    }
}
