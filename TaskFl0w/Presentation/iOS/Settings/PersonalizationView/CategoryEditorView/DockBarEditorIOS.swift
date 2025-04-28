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
    let categoriesPerPage = 16
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
            editingCategory: editingCategory
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
                .frame(height: 360)
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

        var body: some View {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(categoryWidth), spacing: 10), count: 4),
                spacing: 20
            ) {
                ForEach(categories) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    )
                    .frame(width: categoryWidth, height: 70)
                    .scaleEffect(selectedCategory == category ? 1.1 : 1.0)
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
            .padding(.top, 20)
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
        let count = viewModel.categories.count
        return max((count + categoriesPerPage - 1) / categoriesPerPage, 1)
    }

    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        let startIndex = page * categoriesPerPage
        guard startIndex < viewModel.categories.count else { return [] }
        let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
        return Array(viewModel.categories[startIndex..<endIndex])
    }
}
