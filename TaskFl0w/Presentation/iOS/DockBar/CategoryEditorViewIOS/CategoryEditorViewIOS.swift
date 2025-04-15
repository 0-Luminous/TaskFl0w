//
//  CategoryEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

enum CategoryType {
    case list, notes
}

struct CategoryEditorViewIOS: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var isPresented: Bool
    @State var editingCategory: TaskCategoryModel?
    @State private var selectedDockCategory: TaskCategoryModel?
    

    @Environment(\.colorScheme) var colorScheme

    @State private var categoryName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "star.fill"
    @State private var showingColorPicker = false
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false
    @State private var hexColor: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var categoryType: CategoryType = .list

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // Инициализатор для настройки начальных значений
    init(
        viewModel: ClockViewModel, isPresented: Binding<Bool>,
        editingCategory: TaskCategoryModel? = nil
    ) {
        self.viewModel = viewModel
        self._isPresented = isPresented
        self._editingCategory = State(initialValue: editingCategory)
        self._selectedDockCategory = State(initialValue: editingCategory)

        // Установка начальных значений
        if let category = editingCategory {
            _categoryName = State(initialValue: category.rawValue)
            _selectedColor = State(initialValue: category.color)
            _selectedIcon = State(initialValue: category.iconName)
        } else {
            // Значения по умолчанию для новой категории
            _categoryName = State(initialValue: "")
            _selectedColor = State(initialValue: .blue)
            _selectedIcon = State(initialValue: "star.fill")
        }
    }

    // Обновленный previewCategory для отображения текущих изменений
    private var previewCategory: TaskCategoryModel {
        TaskCategoryModel(
            id: editingCategory?.id ?? UUID(),
            rawValue: categoryName.isEmpty ? "Новая категория" : categoryName,
            iconName: selectedIcon,
            color: selectedColor
        )
    }

    // Общая функция для расчета цвета тени в зависимости от темы
    private func shadowColor() -> Color {
        // Возвращаем темный цвет тени независимо от темы
        return Color.black
    }

    // Выносим кнопки в отдельные представления
    private var colorButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            showingColorPicker = true
        }) {
            HStack {
                Text("Цвет")
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(selectedColor)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.737, green: 0.737, blue: 0.737), lineWidth: 2)
                    )
                    .frame(width: 30, height: 30)
                    
            }
            .padding()
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.357, green: 0.357, blue: 0.357))
                    .shadow(
                        color: shadowColor().opacity(0.5),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
        }
        .sheet(isPresented: $showingColorPicker) {
            NavigationView {
                ColorPicker("Выберите цвет", selection: $selectedColor)
                    .labelsHidden()
                    .padding()
                    .navigationTitle("Выбор цвета")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Готово") {
                                feedbackGenerator.impactOccurred()
                                showingColorPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
    }

    // Кнопка добавления/удаления
    private var actionButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            if editingCategory == nil {
                saveCategory()
                isPresented = false
            } else {
                showingDeleteAlert = true
            }
        }) {
            HStack {
                Spacer()
                Image(systemName: editingCategory == nil ? "plus" : "trash.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
                Text(editingCategory == nil ? "Добавить категорию" : "Удалить категорию")
                    .foregroundColor(.white)
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(editingCategory == nil ? Color.blue : Color.red)
                    .shadow(
                        color: shadowColor().opacity(0.5),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
    }

    private var iconButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            showingIconPicker = true
        }) {
            HStack {
                Text("Иконка")
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: selectedIcon)
                    .foregroundColor(selectedColor)
                    .font(.system(size: 20))
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 0.737, green: 0.737, blue: 0.737))
                    )
            }
            .padding()
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.357, green: 0.357, blue: 0.357))
                    .shadow(
                        color: shadowColor().opacity(0.5),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
            )
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {

                // DockBar с обновленным binding для выбранной категории
                DockBarEditorIOS(
                    viewModel: viewModel,
                    selectedCategory: Binding(
                        get: { selectedDockCategory },
                        set: { newCategory in
                            if newCategory != selectedDockCategory {
                                selectedDockCategory = newCategory
                                if let category = newCategory {
                                    editingCategory = category
                                    categoryName = category.rawValue
                                    selectedColor = category.color
                                    selectedIcon = category.iconName
                                    feedbackGenerator.impactOccurred()
                                }
                            }
                        }
                    ),
                    editingCategory: previewCategory
                )
                .id(previewCategory.id)

                // Настройки категории
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        colorButton
                        iconButton
                    }
                    .padding(.horizontal)

                    TextField("Название категории", text: $categoryName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedColor, lineWidth: 3)
                        )
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Тип категории")
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "474747"))
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        HStack(spacing: 15) {
                            GeometryReader { geometry in
                                Button(action: {
                                    categoryType = .list
                                    feedbackGenerator.impactOccurred()
                                }) {
                                    VStack {
                                        Image(systemName: "list.bullet")
                                            .foregroundColor(.white)
                                            .font(.system(size: 50))
                                            .padding(.bottom, 5)
                                        
                                        Text("Список")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(categoryType == .list ? 
                                                  Color.blue : Color(red: 0.357, green: 0.357, blue: 0.357))
                                            .shadow(
                                                color: shadowColor().opacity(0.5),
                                                radius: 5, x: 0, y: 2
                                            )
                                    )
                                }
                            }
                            
                            GeometryReader { geometry in
                                Button(action: {
                                    categoryType = .notes
                                    feedbackGenerator.impactOccurred()
                                }) {
                                    VStack {
                                        Image(systemName: "note.text")
                                            .foregroundColor(.white)
                                            .font(.system(size: 50))
                                            .padding(.bottom, 5)
                                        
                                        Text("Заметки")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(categoryType == .notes ? 
                                                  Color.orange : Color(red: 0.357, green: 0.357, blue: 0.357))
                                            .shadow(
                                                color: shadowColor().opacity(0.5),
                                                radius: 5, x: 0, y: 2
                                            )
                                    )
                                }
                            }
                        }
                        .frame(height: 150)
                        .padding(.horizontal)
                    }
                    
                    Spacer() 
                    actionButton
                        .padding(.top, 20)
                    
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                        // Добавьте здесь логику архивирования
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "archivebox.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                            Text("Архив")
                                .foregroundColor(.white)
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(red: 0.357, green: 0.357, blue: 0.357))
                                .shadow(
                                    color: shadowColor().opacity(0.5),
                                    radius: 5, x: 0, y: 2
                                )
                        )
                        .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle(editingCategory == nil ? "Новая категория" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        feedbackGenerator.impactOccurred()
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        saveCategory()
                        isPresented = false
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingIconPicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 60))
                        ], spacing: 20
                    ) {
                        ForEach(SystemIcons.available, id: \.self) { icon in
                            Button(action: {
                                selectedIcon = icon
                                showingIconPicker = false
                            }) {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .foregroundColor(selectedColor)
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(UIColor.systemBackground))
                                            .shadow(
                                                color: Color.black.opacity(0.1), radius: 5, x: 0,
                                                y: 2)
                                    )
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Выбор иконки")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            showingIconPicker = false
                        }
                    }
                }
            }
        }
        .alert("Удалить категорию?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                if let category = editingCategory {
                    viewModel.categoryManagement.removeCategory(category)
                    isPresented = false
                }
            }
        } message: {
            Text("Все задачи в этой категории также будут удалены")
        }
    }

    private func saveCategory() {
        let newCategory = TaskCategoryModel(
            id: editingCategory?.id ?? UUID(),
            rawValue: categoryName,
            iconName: selectedIcon,
            color: selectedColor
        )

        if editingCategory != nil {
            viewModel.categoryManagement.updateCategory(newCategory)
        } else {
            viewModel.categoryManagement.addCategory(newCategory)
        }
        isPresented = false
    }
}

#Preview {
    let viewModel = ClockViewModel()

    // Добавляем тестовую категорию через categoryManagement
    let testCategory = TaskCategoryModel(
        id: UUID(),
        rawValue: "Тестовая категория",
        iconName: "star.fill",
        color: .blue
    )
    viewModel.categoryManagement.addCategory(testCategory)

    return CategoryEditorViewIOS(
        viewModel: viewModel,
        isPresented: .constant(true)
    )
}
