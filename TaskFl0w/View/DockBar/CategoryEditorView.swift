//
//  CategoryEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    // Примерно как в вашем коде
    @Binding var clockOffset: CGFloat
    
    // Локальные поля для новой категории
    @State private var categoryName: String = ""
    @State private var categoryColor: Color = .blue
    @State private var categoryIconName: String = "star.fill"
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Название")) {
                    TextField("Введите название категории", text: $categoryName)
                }
                
                Section(header: Text("Цвет")) {
                    ColorPicker("Цвет категории", selection: $categoryColor)
                }
                
                Section(header: Text("Системное имя иконки")) {
                    TextField("Напр. star.fill", text: $categoryIconName)
                }
            }
            .navigationTitle("Редактор категорий")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        closeEditor()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveCategory()
                        closeEditor()
                    }
                }
            }
        }
    }
    
    // MARK: - Методы
    
    private func closeEditor() {
        if isPresented {
            isPresented = false
        } else {
            dismiss()
        }
    }
    
    private func saveCategory() {
        let newCategory = TaskCategoryModel(
            id: UUID(),
            rawValue: categoryName,
            iconName: categoryIconName,
            color: categoryColor
        )
        viewModel.addCategory(newCategory)
    }
}


