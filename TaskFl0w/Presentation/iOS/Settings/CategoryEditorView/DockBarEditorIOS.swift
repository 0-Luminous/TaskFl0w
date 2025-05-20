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
    
    // Добавляем состояние для запоминания текущей страницы
    @State private var lastVisitedPage: Int = 0
    
    let categoriesPerPage = 8  // Для всех страниц кроме первой
    let firstPageCategoriesCount = 7  // Только для первой страницы
    let categoryWidth: CGFloat = 70

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 5) {
            CategoryCarouselView(
                viewModel: viewModel,
                selectedCategory: $selectedCategory,
                editingCategory: editingCategory,
                categoriesPerPage: categoriesPerPage,
                firstPageCategoriesCount: firstPageCategoriesCount,
                categoryWidth: categoryWidth,
                rememberedPage: $lastVisitedPage  // Передаем привязку
            )
            .padding(.horizontal, 15)
        }
        .padding(.top, 5)
    }
}

// Новая структура, которая полностью инкапсулирует карусель категорий
struct CategoryCarouselView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var selectedCategory: TaskCategoryModel?
    var editingCategory: TaskCategoryModel? = nil
    
    let categoriesPerPage: Int
    let firstPageCategoriesCount: Int
    let categoryWidth: CGFloat
    
    // Добавляем возможность передать и сохранить текущую страницу
    @State private var currentPage: Int
    @Binding var rememberedPage: Int
    
    // Создаем инициализатор для настройки @State свойства
    init(viewModel: ClockViewModel, selectedCategory: Binding<TaskCategoryModel?>, 
         editingCategory: TaskCategoryModel? = nil, categoriesPerPage: Int, 
         firstPageCategoriesCount: Int, categoryWidth: CGFloat,
         rememberedPage: Binding<Int> = .constant(0)) {
        self.viewModel = viewModel
        self._selectedCategory = selectedCategory
        self.editingCategory = editingCategory
        self.categoriesPerPage = categoriesPerPage
        self.firstPageCategoriesCount = firstPageCategoriesCount
        self.categoryWidth = categoryWidth
        self._rememberedPage = rememberedPage
        self._currentPage = State(initialValue: rememberedPage.wrappedValue)
    }
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 5) {
            // Индикатор страниц
            if numberOfPages > 1 {
                HStack {
                    ForEach(0..<numberOfPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                            .frame(width: 7, height: 7)
                            // Добавляем возможность перейти на страницу по тапу на индикатор
                            .onTapGesture {
                                withAnimation {
                                    currentPage = index
                                    rememberedPage = index
                                }
                            }
                    }
                }
                .padding(.bottom, 5)
            }
            
            // TabView с категориями
            TabView(selection: Binding<Int>(
                get: { self.currentPage },
                set: { newValue in 
                    self.currentPage = newValue
                    self.rememberedPage = newValue
                }
            )) {
                ForEach(0..<numberOfPages, id: \.self) { page in
                    CategoryPageView(
                        categories: categoriesForPage(page),
                        categoryWidth: categoryWidth,
                        selectedCategory: $selectedCategory,
                        editingCategory: editingCategory,
                        isNewCategory: shouldShowNewCategoryOnPage(page),
                        showAddButton: shouldShowAddButtonOnPage(page),
                        showNewCategory: shouldShowNewCategoryOnPage(page),
                        onAddButtonTap: {
                            // При создании новой категории не меняем страницу
                            selectedCategory = nil
                            // Если мы на странице 0, оставляем всё как есть
                            // Иначе, программно переключаемся на страницу 0
                            if currentPage != 0 {
                                withAnimation {
                                    currentPage = 0
                                    rememberedPage = 0
                                }
                            }
                        }
                    )
                    .tag(page)
                    .id("page_\(page)_\(viewModel.categories.count)")  // Обновлено
                }
            }
            .frame(height: 200)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(
                themeManager.isDarkMode ? Color(white: 0.2) : Color.white.opacity(0.95)
            )
            .cornerRadius(24)
            .shadow(color: themeManager.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            .id("carousel_\(numberOfPages)_\(viewModel.categories.count)")  // Обновлено
            // Добавляем жесты для перелистывания
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        let threshold: CGFloat = 50
                        if gesture.translation.width > threshold && currentPage > 0 {
                            withAnimation {
                                currentPage -= 1
                                rememberedPage = currentPage
                            }
                        } else if gesture.translation.width < -threshold && currentPage < numberOfPages - 1 {
                            withAnimation {
                                currentPage += 1
                                rememberedPage = currentPage
                            }
                        }
                    }
            )
        }
        .onAppear {
            // Гарантируем действительную страницу
            if rememberedPage >= numberOfPages {
                rememberedPage = max(0, numberOfPages - 1)
            }
            
            // Если создается новая категория (editingCategory != nil && selectedCategory == nil),
            // и мы на странице отличной от 0, переключимся на страницу 0
            if editingCategory != nil && selectedCategory == nil && currentPage != 0 {
                withAnimation {
                    currentPage = 0
                    rememberedPage = 0
                }
            } else {
                // В остальных случаях используем запомненную страницу
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        self.currentPage = self.rememberedPage
                    }
                }
            }
        }
    }
    
    // Все методы и свойства, связанные со страницами, перемещаем сюда
    private var numberOfPages: Int {
        // Учитываем только существующие категории для расчета количества страниц,
        // независимо от того, редактируется новая категория или нет
        let effectiveCount = viewModel.categories.count
        
        if effectiveCount <= firstPageCategoriesCount {
            return 1
        }
        
        let remainingCategories = effectiveCount - firstPageCategoriesCount
        let additionalPages = (remainingCategories + categoriesPerPage - 1) / categoriesPerPage
        return 1 + additionalPages
    }
    
    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        // Возвращаем категории для текущей страницы с измененным порядком
        if page == 0 {
            let endIndex = min(firstPageCategoriesCount, viewModel.categories.count)
            return Array(viewModel.categories[0..<endIndex])
        } else {
            let startIndex = firstPageCategoriesCount + (page - 1) * categoriesPerPage
            guard startIndex < viewModel.categories.count else { return [] }
            let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
            return Array(viewModel.categories[startIndex..<endIndex])
        }
    }
    
    private func shouldShowAddButtonOnPage(_ page: Int) -> Bool {
        return page == 0 && selectedCategory != nil && !(editingCategory != nil && selectedCategory == nil)
    }
    
    private func shouldShowNewCategoryOnPage(_ page: Int) -> Bool {
        // Новую категорию показываем только на первой странице
        return page == 0 && editingCategory != nil && selectedCategory == nil
    }
}

// Отдельная структура для содержимого страницы
struct CategoryPageView: View {
    let categories: [TaskCategoryModel]
    let categoryWidth: CGFloat
    @Binding var selectedCategory: TaskCategoryModel?
    let editingCategory: TaskCategoryModel?
    let isNewCategory: Bool
    let showAddButton: Bool
    let showNewCategory: Bool
    let onAddButtonTap: () -> Void
    
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack {
            // Создаем сетку с 4 колонками и 2 строками (4x2)
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(categoryWidth), spacing: 10), count: 4),
                spacing: 15
            ) {
                // Добавляем кнопку "Добавить" в левый верхний угол, на первой странице
                if showAddButton {
                    Button(action: onAddButtonTap) {
                        VStack(spacing: 5) {
                            Circle()
                                .fill(themeManager.isDarkMode ? Color.blue : Color.blue.opacity(0.8))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                        .font(.system(size: 24))
                                )
                                .shadow(color: .black.opacity(themeManager.isDarkMode ? 0.25 : 0.10), radius: 4, y: 2)
                            
                            Text("categoryEditor.add".localized)
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: categoryWidth, height: 70)
                }
                
                // Показываем новую категорию в верхнем левом углу (или после кнопки добавления), если активно создание
                if isNewCategory && showNewCategory, let previewCategory = editingCategory {
                    CategoryButton(
                        category: previewCategory,
                        isSelected: true,
                        themeManager: themeManager
                    )
                    .frame(width: categoryWidth, height: 70)
                    .scaleEffect(1.1)
                    .opacity(previewCategory.isHidden ? 0.5 : 1.0)
                    .id(previewCategory.id.uuidString + previewCategory.iconName + (previewCategory.color.toHex() ?? ""))
                }
                
                // Отображаем все существующие категории после кнопки добавления и/или новой категории
                ForEach(categories) { category in
                    if let editingCategory = editingCategory, selectedCategory?.id == editingCategory.id, category.id == editingCategory.id {
                        CategoryButton(
                            category: editingCategory,
                            isSelected: true,
                            themeManager: themeManager
                        )
                        .frame(width: categoryWidth, height: 70)
                        .scaleEffect(1.1)
                        .opacity(editingCategory.isHidden ? 0.5 : 1.0)
                        .id(editingCategory.id.uuidString + editingCategory.iconName + (editingCategory.color.toHex() ?? ""))
                    } else {
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            themeManager: themeManager
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
            }
            .padding(.top, 15)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Вспомогательные

private var backgroundColorForTheme: Color {
    ThemeManager.shared.isDarkMode ? Color(white: 0.2) : Color.white.opacity(0.95)
}

private var shadowColorForTheme: Color {
    ThemeManager.shared.isDarkMode ? Color.black.opacity(0.3) : Color.black.opacity(0.08)
}
