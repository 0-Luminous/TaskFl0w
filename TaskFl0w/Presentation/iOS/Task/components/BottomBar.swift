//
// BottomBar.swift
// ToDoList
//
// Created by Yan on 21/3/25.

import SwiftUI

struct BottomBar: View {
    let itemCount: Int
    let onAddTap: () -> Void
    @Binding var isSelectionMode: Bool
    @Binding var selectedTasks: Set<UUID>
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                Button(action: onAddTap) {
                    Image(systemName: "archivebox.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(22)
                }
                Spacer()
                Text("\(itemCount) задач")
                    .foregroundColor(.gray)
                    .font(.system(size: 17))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                Spacer()
                Button(action: {
                    if isSelectionMode {
                        // Сбрасываем выбор при выходе из режима выбора
                        selectedTasks.removeAll()
                    }
                    isSelectionMode.toggle()
                }) {
                    Text(isSelectionMode ? "Готово" : "Выбрать")
                        .foregroundColor(.gray)
                        .font(.system(size: 17))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
                Spacer()
                Button(action: onAddTap) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 22))
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(22)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    // Используем StateObject для хранения состояния в превью
    struct PreviewWrapper: View {
        @State private var isSelectionMode = false
        @State private var selectedTasks: Set<UUID> = []
        
        var body: some View {
            BottomBar(
                itemCount: 5, 
                onAddTap: {
                    print("Add tapped")
                }, 
                isSelectionMode: $isSelectionMode,
                selectedTasks: $selectedTasks
            )
        }
    }
    
    return PreviewWrapper()
}
