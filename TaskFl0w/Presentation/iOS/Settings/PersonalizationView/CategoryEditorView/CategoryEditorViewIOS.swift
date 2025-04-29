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
    @State private var isHidden: Bool = false

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
            _isHidden = State(initialValue: category.isHidden)
        } else {
            // Значения по умолчанию для новой категории
            _categoryName = State(initialValue: "")
            _selectedColor = State(initialValue: .blue)
            _selectedIcon = State(initialValue: "star.fill")
            _isHidden = State(initialValue: false)
        }
    }

    // Обновленный previewCategory для отображения текущих изменений
    private var previewCategory: TaskCategoryModel {
        TaskCategoryModel(
            id: editingCategory?.id ?? UUID(),
            rawValue: categoryName.isEmpty ? "Новая категория" : categoryName,
            iconName: selectedIcon,
            color: selectedColor,
            isHidden: isHidden
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
                RoundedRectangle(cornerRadius: 24)
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
                VStack(spacing: 20) {
                    // Палитра стандартных цветов
                    VStack(alignment: .leading) {
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                            let standardColors: [Color] = [
                                .coral1, .red1, .Orange1, .Apricot1, .yellow1, .Clover1, .green0, .green1, .Mint1, 
                                .Teal1, .Blue1, .LightBlue1, .BlueJay1, .OceanBlue1, 
                                .StormBlue1, .Indigo1, .Purple1, .Lilac1, .Pink1, 
                                .Peony1, .Rose1, 
                            ]
                            
                            ColorPicker("Выберите цвет", selection: $selectedColor)
                            .labelsHidden()
                            .padding()
                            
                            ForEach(0..<standardColors.count, id: \.self) { index in
                                let color = standardColors[index]
                                Button(action: {
                                    selectedColor = color
                                    feedbackGenerator.impactOccurred()
                                }) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }                
                }
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
            .presentationDetents([.height(300)])
            .presentationDragIndicator(.visible)
        }
    }

    // Кнопка добавления/удаления
    private var actionButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            if editingCategory == nil {
                saveCategory(autoClose: false)
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
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
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.737, green: 0.737, blue: 0.737))
                    )
            }
            .padding()
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 24)
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
                                // Сохраняем изменения предыдущей категории, если она была выбрана
                                if let currentCategory = editingCategory {
                                    saveCategory(autoClose: false)
                                }
                                    
                                selectedDockCategory = newCategory
                                if let category = newCategory {
                                    editingCategory = category
                                    categoryName = category.rawValue
                                    selectedColor = category.color
                                    selectedIcon = category.iconName
                                    isHidden = category.isHidden
                                    feedbackGenerator.impactOccurred()
                                } else {
                                    // Когда снимаем выделение с категории
                                    editingCategory = nil
                                    // Сбрасываем значения к значениям по умолчанию
                                    categoryName = ""
                                    selectedColor = .blue 
                                    selectedIcon = "star.fill"
                                    isHidden = false
                                }
                            }
                        }
                    ),
                    // Передаем текущую редактируемую категорию
                    editingCategory: editingCategory != nil 
                        ? TaskCategoryModel(
                            id: editingCategory!.id, 
                            rawValue: categoryName.isEmpty ? editingCategory!.rawValue : categoryName, 
                            iconName: selectedIcon, 
                            color: selectedColor,
                            isHidden: isHidden
                          ) 
                        : (selectedDockCategory == nil ? previewCategory : nil)
                )
                .id("\(previewCategory.id)-\(selectedDockCategory?.id ?? UUID())-\(selectedColor.toHex() ?? "")-\(selectedIcon)")
                .opacity(isTextFieldFocused ? 0 : 1)
                .frame(height: isTextFieldFocused ? 0 : nil)

                // Настройки категории
                VStack(spacing: 15) {
                    HStack(spacing: 20) {
                        colorButton
                        iconButton
                    }
                    .padding(.horizontal)
                    .opacity(isTextFieldFocused ? 0 : 1)
                    .frame(height: isTextFieldFocused ? 0 : nil)

                    TextField("Название категории", text: $categoryName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(selectedColor, lineWidth: 3)
                        )
                        .padding(.horizontal)
                        .focused($isTextFieldFocused)
                        .padding(.top, isTextFieldFocused ? 100 : 0)
                        .animation(.easeInOut, value: isTextFieldFocused)
                    
                    if !isTextFieldFocused {
                        actionButton
                        
                        Button(action: {
                            feedbackGenerator.impactOccurred()
                            isHidden.toggle()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: isHidden ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                                Text(isHidden ? "Показать" : "Скрыть")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(red: 0.357, green: 0.357, blue: 0.357))
                                    .shadow(
                                        color: shadowColor().opacity(0.5),
                                        radius: 5, x: 0, y: 2
                                    )
                            )
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(editingCategory == nil)
                        .opacity(editingCategory == nil ? 0.5 : 1.0)
                    }
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
                        saveCategory(autoClose: true)
                    }
                    .disabled(categoryName.isEmpty)
                }
            }
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showingIconPicker) {
            NavigationView {
                IconPickerView(selectedIcon: $selectedIcon, iconColor: selectedColor, isPresented: $showingIconPicker)
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

    private func saveCategory(autoClose: Bool = true) {
        let newCategory = TaskCategoryModel(
            id: editingCategory?.id ?? UUID(),
            rawValue: categoryName,
            iconName: selectedIcon,
            color: selectedColor,
            isHidden: isHidden
        )

        if editingCategory != nil {
            viewModel.categoryManagement.updateCategory(newCategory)
            // Сохраняем текущую выбранную категорию после обновления
            selectedDockCategory = newCategory
            editingCategory = newCategory
        } else {
            viewModel.categoryManagement.addCategory(newCategory)
            // Подготавливаем для добавления следующей категории
            categoryName = ""
            isHidden = false
            // Сбрасываем текущую выбранную категорию
            selectedDockCategory = nil
            editingCategory = nil
        }
        
        // Закрываем только если явно запрошено
        if autoClose {
            isPresented = false
        }
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
