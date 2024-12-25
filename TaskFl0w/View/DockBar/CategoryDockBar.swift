import SwiftUI

struct CategoryDockBar: View {
    @ObservedObject var viewModel: ClockViewModel
    
    @Binding var showingAddTask: Bool
    @Binding var draggedCategory: TaskCategoryModel?
    @Binding var showingCategoryEditor: Bool
    @Binding var selectedCategory: TaskCategoryModel?
    
    @State private var isEditMode = false
    @State private var currentPage = 0
    @State private var lastNonEditPage = 0
    
    let categoriesPerPage = 4
    let categoryWidth: CGFloat = 80
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 5) {
            TabView(selection: $currentPage) {
                ForEach(0..<numberOfPages, id: \.self) { page in
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: categoryWidth))], spacing: 10) {
                        
                        // Отрисовка кнопок категорий
                        ForEach(categoriesForPage(page)) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category
                            )
                            .frame(width: categoryWidth, height: 80)
                            .onTapGesture {
                                selectedCategory = category
                            }
                            .onDrag {
                                self.draggedCategory = category
                                return NSItemProvider(object: category.id.uuidString as NSString)
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
                        
                        // Кнопка "Добавить категорию" (в режиме редактирования)
                        if isEditMode && shouldShowAddButton(on: page) {
                            Button(action: {
                                showingCategoryEditor = true
                            }) {
                                VStack {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                    Text("Добавить")
                                        .font(.caption)
                                }
                                .foregroundColor(.blue)
                                .frame(width: categoryWidth, height: 80)
                            }
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
        .padding(.horizontal, 10)
        .padding(.top, 5)
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation {
                        if !isEditMode {
                            lastNonEditPage = currentPage
                        }
                        isEditMode.toggle()
                        if isEditMode {
                            currentPage = pageWithAddButton
                        } else {
                            currentPage = min(lastNonEditPage, numberOfPages - 1)
                        }
                    }
                }
        )
        
        // Пэйдж-контрол
        if numberOfPages > 1 {
            HStack {
                ForEach(0..<numberOfPages, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.5))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.top, 5)
            .padding(.bottom, 10)
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
        if isEditMode {
            return max((count + categoriesPerPage) / categoriesPerPage, 2)
        } else {
            return max((count + categoriesPerPage - 1) / categoriesPerPage, 1)
        }
    }
    
    private func categoriesForPage(_ page: Int) -> [TaskCategoryModel] {
        let startIndex = page * categoriesPerPage
        let endIndex = min(startIndex + categoriesPerPage, viewModel.categories.count)
        return Array(viewModel.categories[startIndex..<endIndex])
    }
    
    private var pageWithAddButton: Int {
        let fullPages = viewModel.categories.count / categoriesPerPage
        return fullPages
    }
    
    private func shouldShowAddButton(on page: Int) -> Bool {
        return page == pageWithAddButton
    }
}
