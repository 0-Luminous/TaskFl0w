//
//  CategoryEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CategoryEditorViewIOS: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State var editingCategory: TaskCategoryModel?
    @State private var selectedDockCategory: TaskCategoryModel?
    
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    @AppStorage("zeroPosition") private var zeroPosition: Double = 0.0
    
    @State private var categoryName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "star.fill"
    @State private var showingColorPicker = false
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false
    @State private var hexColor: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // Инициализатор для настройки начальных значений
    init(viewModel: ClockViewModel, isPresented: Binding<Bool>, editingCategory: TaskCategoryModel? = nil) {
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
    
    // Добавляем вычисляемые свойства для цветов
    private var currentClockFaceColor: Color {
        let hexColor = colorScheme == .dark
            ? viewModel.darkModeClockFaceColor
            : viewModel.lightModeClockFaceColor
        return Color(hex: hexColor) ?? .white
    }
    
    private var currentOuterRingColor: Color {
        let hexColor = colorScheme == .dark ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
    
    // Выносим кнопки в отдельные представления
    private var colorButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            showingColorPicker = true
        }) {
            HStack {
                Text("Цвет")
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "474747"))
                Spacer()
                Circle()
                    .fill(selectedColor)
                    .frame(width: 30, height: 30)
            }
            .padding()
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(
                        color: editingCategory == nil ? 
                            (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)) : 
                            selectedColor.opacity(0.3),
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
            Image(systemName: editingCategory == nil ? "plus" : "trash.fill")
                .foregroundColor(editingCategory == nil ? .blue : .red)
                .font(.system(size: 20))
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(
                            color: editingCategory == nil ? 
                                (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)) : 
                                selectedColor.opacity(0.3),
                            radius: 5,
                            x: 0,
                            y: 2
                    )
                )
        }
    }
    
    private var iconButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            showingIconPicker = true
        }) {
            HStack {
                Text("Иконка")
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "474747"))
                Spacer()
                Image(systemName: selectedIcon)
                    .foregroundColor(selectedColor)
                    .font(.system(size: 20))
            }
            .padding()
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(
                        color: editingCategory == nil ? 
                            (colorScheme == .dark ? Color.white.opacity(0.2) : Color.black.opacity(0.1)) : 
                            selectedColor.opacity(0.3),
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
                // Циферблат
                ZStack {
                    // Внешнее кольцо
                    Circle()
                        .stroke(currentOuterRingColor, lineWidth: 20)
                        .frame(
                            width: UIScreen.main.bounds.width * 0.8,
                            height: UIScreen.main.bounds.width * 0.8
                        )
                    
                    // Сам циферблат
                    GlobleClockFaceViewIOS(
                        currentDate: viewModel.selectedDate,
                        tasks: viewModel.tasks,
                        viewModel: viewModel,
                        draggedCategory: $viewModel.draggedCategory,
                        clockFaceColor: currentClockFaceColor,
                        zeroPosition: zeroPosition
                    )
                }
                .padding(.top, 30)
                .padding(.bottom, 30)
                
                // DockBar с обновленным binding для выбранной категории
                DockBarIOS(
                    viewModel: viewModel,
                    showingAddTask: .constant(false),
                    draggedCategory: .constant(nil),
                    showingCategoryEditor: .constant(false),
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
                        actionButton
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
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle(editingCategory == nil ? "Новая категория" : "Редактирование")
            .navigationBarTitleDisplayMode(.inline)
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
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
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
                                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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


