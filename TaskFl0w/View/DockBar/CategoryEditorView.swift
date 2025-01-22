//
//  CategoryEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct CategoryEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @Binding var isPresented: Bool
    @State var editingCategory: TaskCategoryModel?
    @State private var selectedDockCategory: TaskCategoryModel?
    
    @State private var categoryName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIcon: String = "star.fill"
    @State private var showingColorPicker = false
    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false
    @State private var hexColor: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    // Массив доступных системных иконок
    private let availableIcons = [
        "star.fill", "heart.fill", "house.fill", "person.fill", "book.fill",
        "briefcase.fill", "cart.fill", "gift.fill", "hammer.fill", "leaf.fill",
        "lightbulb.fill", "music.note", "paintbrush.fill", "pencil", "phone.fill",
        "plus", "scissors", "trash.fill", "wrench.fill", "xmark",
        "circle.fill", "square.fill", "triangle.fill", "diamond.fill", "heart.fill",
        "star.circle.fill", "flag.fill", "bell.fill", "tag.fill", "bookmark.fill",
        "doc.fill", "folder.fill", "paperplane.fill", "tray.fill", "archivebox.fill",
        "calendar", "clock.fill", "stopwatch.fill", "timer", "gauge",
        "speedometer", "heart.text.square.fill", "doc.text.fill", "list.bullet",
        "camera.fill", "video.fill", "mic.fill", "speaker.fill", "music.mic",
        "photo.fill", "rectangle.fill.on.rectangle.fill", "person.2.fill",
        "gamecontroller.fill", "headphones", "tv.fill", "display", "laptopcomputer",
        "iphone", "ipad", "apps.iphone", "command", "keyboard", "printer.fill",
        "network", "wifi", "antenna.radiowaves.left.and.right", "battery.100",
        "location.fill", "map.fill", "pin.fill", "safari.fill", "globe",
        "cloud.fill", "cloud.rain.fill", "sun.max.fill", "moon.fill", "star.fill",
        "sparkles", "snow", "flame.fill", "bolt.fill", "drop.fill"
    ]
    
    // Выносим кнопки в отдельные представления
    private var colorButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            showingColorPicker = true
        }) {
            HStack {
                Text("Цвет")
                    .foregroundColor(Color(hex: "474747"))
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
                    .shadow(color: Color(hex: "474747")!.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
        .sheet(isPresented: $showingColorPicker) {
            NavigationView {
                VStack(spacing: 15) {
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .padding()
                    
                    Divider()
                    
                    TextField("HEX цвет (например, FF0000)", text: $hexColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: hexColor) { newValue in
                            if let color = Color(hex: newValue) {
                                selectedColor = color
                            }
                        }
                        .onChange(of: selectedColor) { _ in
                            hexColor = selectedColor.toHex()
                        }
                    
                    Spacer()
                }
                .navigationTitle("Выбор цвета")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            showingColorPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            feedbackGenerator.impactOccurred()
                            showingColorPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    } 
    
    // Кнопка добавления/удаления
    private var actionButton: some View {
        Button(action: {
            feedbackGenerator.impactOccurred()
            if editingCategory == nil {
                // Сохранение новой категории
                saveCategory()
                isPresented = false
            } else {
                // Показать алерт удаления
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
                                Color.blue.opacity(0.3) : 
                                Color.red.opacity(0.2),
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
                    .foregroundColor(Color(hex: "474747"))
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
                    .shadow(color: Color(hex: "474747")!.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                // DockBar с обновленным binding для выбранной категории
                CategoryDockBar(
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
                .padding(.top)
                .id(previewCategory.id)
                
                // Кнопки выбора цвета и иконки
                HStack(spacing: 20) {
                    colorButton
                    actionButton // Заменяем deleteButton на actionButton
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
                
                Spacer()
            }
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
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.7)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showingColorPicker) {
            NavigationView {
                VStack(spacing: 15) {
                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                        .padding()
                    
                    Divider()
                    
                    TextField("HEX цвет (например, FF0000)", text: $hexColor)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: hexColor) { newValue in
                            if let color = Color(hex: newValue) {
                                selectedColor = color
                            }
                        }
                        .onChange(of: selectedColor) { _ in
                            hexColor = selectedColor.toHex()
                        }
                    
                    Spacer()
                }
                .navigationTitle("Выбор цвета")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            showingColorPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") {
                            feedbackGenerator.impactOccurred()
                            showingColorPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingIconPicker) {
            NavigationView {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 20) {
                        ForEach(availableIcons, id: \.self) { icon in
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
    
    return CategoryEditorView(
        viewModel: viewModel,
        isPresented: .constant(true)
    )
}


