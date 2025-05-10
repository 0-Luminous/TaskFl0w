//
//  CategoryDockBar.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct DockBarIOS: View {
    @ObservedObject var viewModel: DockBarViewModel
    @Environment(\.colorScheme) var colorScheme

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
            if viewModel.numberOfPages > 1 {
                HStack {
                    ForEach(0..<viewModel.numberOfPages, id: \.self) { index in
                        Circle()
                            .fill(
                                viewModel.currentPage == index
                                    ? Color.blue : Color.gray.opacity(0.5)
                            )
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.bottom, 5)
            }
        }
    }

    // Эти методы больше не используются, так как вместо них используются
    // соответствующие методы из viewModel

    // Выносим сетку категорий в отдельное представление
    private var categoryGrid: some View {
        CategoryGridContent(
            currentPage: $viewModel.currentPage,
            numberOfPages: viewModel.numberOfPages,
            backgroundColorForTheme: viewModel.backgroundColorForTheme(in: colorScheme),
            shadowColorForTheme: viewModel.shadowColorForTheme(in: colorScheme)
        ) { page in
            categoryPage(for: page)
        }
    }

    // Выносим страницу категорий в отдельное представление
    private func categoryPage(for page: Int) -> some View {
        CategoryPageContent(
            categories: viewModel.categoriesForPage(page),
            categoryWidth: viewModel.categoryWidth,
            selectedCategory: $viewModel.selectedCategory,
            draggedCategory: $viewModel.draggedCategory,
            moveCategory: viewModel.moveCategory,
            themeManager: ThemeManager.shared
        )
    }

    // Выносим жест длительного нажатия в отдельное свойство
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleEditMode()
                }
            }
    }
}
