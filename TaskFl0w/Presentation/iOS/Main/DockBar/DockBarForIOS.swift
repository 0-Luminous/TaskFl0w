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

    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 5) {
            pageIndicator
            categoryGrid
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .gesture(longPressGesture)
    }

    private var pageIndicator: some View {
        Group {
            if viewModel.numberOfPages > 1 {
                HStack {
                    ForEach(0..<viewModel.numberOfPages, id: \.self) { index in
                        Circle()
                            .fill(
                                viewModel.currentPage == index
                                    ? themeManager.isDarkMode ? Color.coral1 : Color.red1 : Color.gray.opacity(0.5)
                            )
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.bottom, 2)
            }
        }
    }

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

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.toggleEditMode()
                }
            }
    }
}
