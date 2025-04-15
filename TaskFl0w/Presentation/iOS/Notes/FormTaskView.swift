//
//  FormTaskView.swift
//  ToDoList
//
//  Created by Yan on 21/3/25.
//

import SwiftUI
import Foundation

struct FormTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ListViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    var onDismiss: (() -> Void)?

    var editingItem: ToDoItem?

    @State private var title: String = ""
    @State private var content: String = ""
    @State private var date: Date = Date()
    @FocusState private var fieldInFocus: Field?
    
    enum Field {
        case title
        case content
    }

    // Инициализатор для создания новой задачи
    init(viewModel: ListViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.editingItem = nil
    }

    // Инициализатор для редактирования существующей задачи
    init(viewModel: ListViewModel, item: ToDoItem, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.editingItem = item
        self._title = State(initialValue: item.title)
        self._content = State(initialValue: item.content)
        self._date = State(initialValue: item.date)
        
        // Если у задачи есть категория, устанавливаем её в viewModel (если она еще не установлена)
        if let categoryID = item.categoryID, let categoryName = item.categoryName, viewModel.selectedCategory == nil {
            // Попробуем найти существующую категорию в списке категорий
            let categoryManager = CategoryManagement(context: PersistenceController.shared.container.viewContext)
            if let existingCategory = categoryManager.categories.first(where: { $0.id == categoryID }) {
                viewModel.selectedCategory = existingCategory
            } else {
                // Если категория не найдена в списке, создаем временную модель
                viewModel.selectedCategory = TaskCategoryModel(
                    id: categoryID,
                    rawValue: categoryName,
                    iconName: "tag.fill",
                    color: .blue
                )
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {    
                // Основное содержимое
                VStack(spacing: 0) {
                    TextField("Название задачи", text: $title)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .focused($fieldInFocus, equals: .title)
                        .onAppear {
                            // Откладываем установку фокуса, чтобы представление полностью загрузилось
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                fieldInFocus = .title
                            }
                        }
                    
                    ZStack(alignment: .topLeading) {    
                        TextEditor(text: $content)
                            .font(.system(size: 17))
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .focused($fieldInFocus, equals: .content)
                            .opacity(content.isEmpty ? 0.85 : 1) // Более мягкая прозрачность для предотвращения проблем с отрисовкой
                            .overlay(
                                Group {
                                    if content.isEmpty {
                                        Text("Описание задачи...")
                                            .foregroundColor(.gray.opacity(0.7))
                                            .padding(.horizontal, 16)
                                            .padding(.top, 8)
                                            .allowsHitTesting(false)
                                    }
                                }
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(themeManager.isDarkMode ? Color.black : Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                // При скрытии представления убеждаемся, что фокус сброшен
                fieldInFocus = nil
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Сначала сбрасываем фокус с клавиатуры перед закрытием
                        fieldInFocus = nil
                        onDismiss?()
                        dismiss()
                    } label: {
                        Text("Назад")
                            .foregroundColor(Color.accentColor)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Сначала сбрасываем фокус с клавиатуры
                        fieldInFocus = nil
                        
                        if let item = editingItem {
                            // Режим редактирования
                            viewModel.presenter?.editItem(
                                id: item.id, title: title, content: content)
                        } else {
                            // Режим добавления
                            if let selectedCategory = viewModel.selectedCategory {
                                // Добавление задачи с выбранной категорией
                                viewModel.presenter?.addItemWithCategory(title: title, content: content, category: selectedCategory)
                            } else {
                                // Обычное добавление без категории
                                viewModel.presenter?.addItem(title: title, content: content)
                            }
                        }
                        onDismiss?()
                        dismiss()
                    } label: {
                        Text("Сохранить")
                            .bold()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? Color.secondary : Color.accentColor)
                }
            }
        }
    }
}


