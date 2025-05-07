//
//  DockBarEditorIOS.swift
//  TaskFl0w
//
//  Created by Yan on 1/4/25.
//
import SwiftUI

struct DockBarEditorIOS: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedCategory: TaskCategoryModel?
    var editingCategory: TaskCategoryModel? = nil

    @State private var currentPage = 0
    let categoriesPerPage = 8
    let categoryWidth: CGFloat = 70

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 5) {
            pageIndicator
            categoryGrid
                .padding(.horizontal, 15)
        }
        .padding(.top, 5)
    }

    // Выносим индикатор страниц в отдельное представление
    private var pageIndicator: some View {
        Group {
            if numberOfPages > 1 {
                HStack {
                    ForEach(0..<numberOfPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.bottom, 5)
            }
        }
    }

    // Выносим сетку категорий в отдельное представление
    private var categoryGrid: some View {
        CategoryGridContent(
            currentPage: $currentPage,
            numberOfPages: numberOfPages,
            backgroundColorForTheme: backgroundColorForTheme,
            shadowColorForTheme: shadowColorForTheme
        ) { page in
            categoryPage(for: page)
        }
    }

    // Выносим страницу категорий в отдельное представление
    private func categoryPage(for page: Int) -> some View {
        CategoryPageContent(
            categories: categoriesForPage(page),
            categoryWidth: categoryWidth,
            selectedCategory: $selectedCategory,
            editingCategory: editingCategory,
            isNewCategory: editingCategory != nil && selectedCategory == nil
        )
    }

    // Структура для содержимого сетки
    private struct CategoryGridContent<Content: View>: View {
        @Binding var currentPage: Int
        let numberOfPages: Int
        let backgroundColorForTheme: Color
        let shadowColorForTheme: Color
        let content: (Int) -> Content

        var body: some View {
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<numberOfPages, id: \.self) { page in
                        content(page)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundColorForTheme)
            .cornerRadius(24)
            .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
        }
    }

    // Структура для содержимого страницы
    private struct CategoryPageContent: View {
        let categories: [TaskCategoryModel]
        let categoryWidth: CGFloat
        @Binding var selectedCategory: TaskCategoryModel?
        let editingCategory: TaskCategoryModel?
        let isNewCategory: Bool

        var body: some View {
            VStack {
                // Создаем сетку с 4 колонками и 2 строками (4x2)
                LazyVGrid(
                    columns: Array(repeating: GridItem(.fixed(categoryWidth), spacing: 10), count: 4),
                    spacing: 15
                ) {
                    // Отображаем все существующие категории в их обычном порядке
                    ForEach(categories) { category in
                        if let editingCategory = editingCategory, selectedCategory?.id == editingCategory.id, category.id == editingCategory.id {
                            // Если это выбранная категория, которая редактируется, показываем её текущую версию с изменениями
                            CategoryButton(
                                category: editingCategory,
                                isSelected: true
                            )
                            .frame(width: categoryWidth, height: 70)
                            .scaleEffect(1.1)
                            .opacity(editingCategory.isHidden ? 0.5 : 1.0)
                            .id(editingCategory.id.uuidString + editingCategory.iconName + (editingCategory.color.toHex() ?? ""))
                        } else {
                            // Обычные категории показываем как есть
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            )
                            .frame(width: categoryWidth, height: 70)
                            .scaleEffect(selectedCategory == category ? 1.1 : 1.0)
                            .opacity(category.isHidden ? 0.5 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: selectedCategory == category)
                            .onTapGesture {
                                withAnimation {
                                    if selectedCategory?.id == category.id {
                                        selectedCategory = nil
                                    } else {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }
                    
                    // Показываем новую категорию в конце, только если это добавление новой (а не редактирование)
                    if isNewCategory, let previewCategory = editingCategory {
                        CategoryButton(
                            category: previewCategory,
                            isSelected: true
                        )
                        .frame(width: categoryWidth, height: 70)
                        .scaleEffect(1.1)
                        .opacity(previewCategory.isHidden ? 0.5 : 1.0)
                        .id(previewCategory.id.uuidString + previewCategory.iconName + (previewCategory.color.toHex() ?? ""))
                    }
                    
                    // Добавляем кнопку с плюсиком, когда выбрана категория в докбаре
                    if selectedCategory != nil && !isNewCategory {
                        Button(action: {
                            // Действие при нажатии кнопки - снимаем выделение с текущей категории
                            selectedCategory = nil
                        }) {
                            VStack(spacing: 5) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .foregroundColor(.white)
                                            .font(.system(size: 24))
                                    )
                                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                                
                                Text("Добавить")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: categoryWidth, height: 70)
                    }
                }
                .padding(.top, 15)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    // MARK: - Вспомогательные

    private var backgroundColorForTheme: Color {
        colorScheme == .dark ? Color(white: 0.2) : Color.white.opacity(0.9)
    }

    private var shadowColorForTheme: Color {
        colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1)
    }

    private var numberOfPages: Int {
        let count = viewModel.categories.count + (editingCategory != nil && selectedCategory == nil ? 1 : 0)
        return max((count + categoriesPerPage - 1) / categoriesPerPage, 1)
    }

    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        let startIndex = page * categoriesPerPage
        guard startIndex < viewModel.categories.count else { return [] }
        let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
        return Array(viewModel.categories[startIndex..<endIndex])
    }
}
