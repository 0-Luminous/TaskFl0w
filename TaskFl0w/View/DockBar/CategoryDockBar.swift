//
//  CategoryDockBar.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CategoryDockBar: View {
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
            // Индикатор страниц показываем отдельно, вне основного контейнера
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
            
            // Основной контейнер DockBar
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<numberOfPages, id: \.self) { page in
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: categoryWidth))], spacing: 10) {
                            ForEach(categoriesForPage(page)) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category
                                )
                                .frame(width: categoryWidth, height: 80)
                                .scaleEffect(selectedCategory == category ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedCategory == category)
                                .onTapGesture {
                                    selectedCategory = category
                                }
                                .onDrag {
                                    self.draggedCategory = category
                                    return NSItemProvider(object: category.id.uuidString as NSString)
                                } preview: {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: category.iconName)
                                                .foregroundColor(.white)
                                                .font(.system(size: 24))
                                        )
                                }
                                .onDrop(
                                    of: [.text],
                                    delegate: DropViewDelegate(
                                        item: category,
                                        items: $viewModel.categories,
                                        draggedItem: $draggedCategory
                                    )
                                )
                            }
                        }
                        .tag(page)
                    }
                }
                .frame(height: 100)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(backgroundColorForTheme)
            .cornerRadius(20)
            .shadow(color: shadowColorForTheme, radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation {
                        // Подготавливаем и запускаем вибрацию
                        feedbackGenerator.prepare()
                        feedbackGenerator.impactOccurred()
                        
                        if !isEditMode {
                            lastNonEditPage = currentPage
                        }
                        isEditMode.toggle()
                        
                        // При входе в режим редактирования сразу открываем CategoryEditorView
                        if isEditMode {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showingCategoryEditor = true
                                isEditMode = false // Сбрасываем режим редактирования
                            }
                        }
                    }
                }
        )
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
}

#Preview {
    let viewModel = ClockViewModel()
    
    // Добавляем тестовые категории
    viewModel.categories = [
        TaskCategoryModel(
            id: UUID(),
            rawValue: "Работа",
            iconName: "macbook",
            color: .blue
        ),
        TaskCategoryModel(
            id: UUID(),
            rawValue: "Спорт",
            iconName: "figure.strengthtraining.traditional",
            color: .green
        ),
        TaskCategoryModel(
            id: UUID(),
            rawValue: "Отдых",
            iconName: "gamecontroller",
            color: .orange
        ),
        TaskCategoryModel(
            id: UUID(),
            rawValue: "Учёба",
            iconName: "book.fill",
            color: .red
        )
    ]
    
    return CategoryDockBar(
        viewModel: viewModel,
        showingAddTask: .constant(false),
        draggedCategory: .constant(nil),
        showingCategoryEditor: .constant(false),
        selectedCategory: .constant(nil)
    )
    .frame(height: 150)
    .background(Color.gray.opacity(0.1))
}
