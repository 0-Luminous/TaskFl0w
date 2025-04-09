//
//  CategoryDockBar.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI
import UIKit

// Импортируем необходимые компоненты и модели
import SwiftUI
import UIKit

struct DockBarIOS: View {
    @ObservedObject var viewModel: ClockViewModel

    @Binding var showingAddTask: Bool
    @Binding var draggedCategory: TaskCategoryModel?
    @Binding var showingCategoryEditor: Bool
    @Binding var selectedCategory: TaskCategoryModel?
    var editingCategory: TaskCategoryModel? = nil

    @State private var isEditMode = false
    @State private var currentPage = 0
    @State private var lastNonEditPage = 0

    let categoriesPerPage = 4
    let categoryWidth: CGFloat = 80

    @Environment(\.colorScheme) var colorScheme

    // Добавляем генератор обратной связи
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack(spacing: 5) {
            pageIndicator
            categoryGrid
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .gesture(longPressGesture)
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
            draggedCategory: $draggedCategory,
            moveCategory: moveCategory
        )
    }

    // Новая структура для содержимого сетки
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
                .frame(height: 100)
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                #else
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
            }
            .background(backgroundColorForTheme)
            .cornerRadius(20)
            .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
        }
    }

    // Новая структура для содержимого страницы
    private struct CategoryPageContent: View {
        let categories: [TaskCategoryModel]
        let categoryWidth: CGFloat
        @Binding var selectedCategory: TaskCategoryModel?
        @Binding var draggedCategory: TaskCategoryModel?
        let moveCategory: (Int, Int) -> Void

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: categoryWidth))], spacing: 10) {
                ForEach(categories) { category in
                    CategoryButtonContent(
                        category: category,
                        categories: categories,
                        isSelected: selectedCategory == category,
                        categoryWidth: categoryWidth,
                        selectedCategory: $selectedCategory,
                        draggedCategory: $draggedCategory,
                        moveCategory: moveCategory
                    )
                }
            }
        }
    }

    // Новая структура для содержимого кнопки категории
    private struct CategoryButtonContent: View {
        let category: TaskCategoryModel
        let categories: [TaskCategoryModel]
        let isSelected: Bool
        let categoryWidth: CGFloat
        @Binding var selectedCategory: TaskCategoryModel?
        @Binding var draggedCategory: TaskCategoryModel?
        let moveCategory: (Int, Int) -> Void

        var body: some View {
            CategoryButton(
                category: category,
                isSelected: isSelected
            )
            .frame(width: categoryWidth, height: 80)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .onTapGesture {
                withAnimation {
                    // Если выбрана та же категория - убираем её
                    if selectedCategory?.id == category.id {
                        selectedCategory = nil
                    } else {
                        // Если выбрана другая категория - показываем её
                        selectedCategory = category
                    }
                }
            }
            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
            .onDrag {
                draggedCategory = category
                return NSItemProvider(object: category.id.uuidString as NSString)
            } preview: {
                categoryDragPreview(for: category)
            }
            .onDrop(
                of: [.text],
                delegate: CategoryDropDelegate(
                    item: category,
                    items: categories,
                    draggedItem: draggedCategory,
                    moveAction: moveCategory
                )
            )
        }

        private func categoryDragPreview(for category: TaskCategoryModel) -> some View {
            RoundedRectangle(cornerRadius: 12)
                .fill(category.color)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.iconName)
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                )
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        }
    }

    // Новый делегат для обработки перетаскивания
    private struct CategoryDropDelegate: DropDelegate {
        let item: TaskCategoryModel
        let items: [TaskCategoryModel]
        let draggedItem: TaskCategoryModel?
        let moveAction: (Int, Int) -> Void

        func performDrop(info: DropInfo) -> Bool {
            guard let draggedItem = draggedItem else { return false }

            let fromIndex = items.firstIndex(of: draggedItem) ?? 0
            let toIndex = items.firstIndex(of: item) ?? 0

            if fromIndex != toIndex {
                moveAction(fromIndex, toIndex)
            }

            return true
        }

        func dropUpdated(info: DropInfo) -> DropProposal? {
            return DropProposal(operation: .move)
        }

        func validateDrop(info: DropInfo) -> Bool {
            return true
        }
    }

    // Выносим жест длительного нажатия в отдельное свойство
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation {
                    feedbackGenerator.prepare()
                    feedbackGenerator.impactOccurred()

                    if !isEditMode {
                        lastNonEditPage = currentPage
                    }
                    isEditMode.toggle()

                    if isEditMode {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showingCategoryEditor = true
                            isEditMode = false
                        }
                    }
                }
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
        let count = viewModel.categories.count
        // Просто делим количество категорий на categoriesPerPage и округляем вверх
        return max((count + categoriesPerPage - 1) / categoriesPerPage, 1)
    }

    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        let startIndex = page * categoriesPerPage

        // Проверяем, что startIndex не выходит за пределы массива
        guard startIndex < viewModel.categories.count else {
            return []
        }

        let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
        return Array(viewModel.categories[startIndex..<endIndex])
    }

    private var pageWithAddButton: Int {
        // Если у нас ровно 4 категории или больше, кнопка добавления должна быть на второй странице
        return viewModel.categories.count >= categoriesPerPage ? 1 : 0
    }

    private func shouldShowAddButton(on page: Int) -> Bool {
        if !isEditMode { return false }

        // Для 4 или более категорий показываем кнопку на второй странице
        if viewModel.categories.count >= categoriesPerPage {
            return page == 1
        }

        // Для менее 4 категорий показываем на первой странице
        return page == 0
    }

    private func isEditing(_ category: TaskCategoryModel) -> Bool {
        return editingCategory?.id == category.id
    }

    private func deleteCategory(_ category: TaskCategoryModel) {
        viewModel.categoryManagement.removeCategory(category)
    }

    private func moveCategory(from source: Int, to destination: Int) {
        guard let draggedCategory = draggedCategory else { return }

        // Создаем новую категорию с обновленным порядком
        let updatedCategory = TaskCategoryModel(
            id: draggedCategory.id,
            rawValue: draggedCategory.rawValue,
            iconName: draggedCategory.iconName,
            color: draggedCategory.color
                // Добавьте другие необходимые свойства
        )

        viewModel.categoryManagement.updateCategory(updatedCategory)

        // Сбрасываем состояние перетаскивания
        self.draggedCategory = nil as TaskCategoryModel?
    }
}
