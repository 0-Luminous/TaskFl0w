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

    // Состояния для панелей управления
    @State private var activeTab: CategorySettingsTab = .settings

    // Добавьте эти состояния в начало структуры CategoryEditorViewIOS
    @State private var showingInlineColorPicker = false
    @State private var sliderBrightnessPosition: CGFloat = 0.5
    @State private var currentBaseColor: Color = .blue
    @State private var selectedColorHex: String = ""

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // Перечисление для вкладок
    enum CategorySettingsTab {
        case settings, appearance, visibility
    }

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
            rawValue: categoryName.isEmpty ? "categoryEditor.name".localized : categoryName,
            iconName: selectedIcon,
            color: selectedColor,
            isHidden: isHidden
        )
    }

    // Модификатор для кнопок
    private struct ButtonModifier: ViewModifier {
        let isSelected: Bool
        let isDisabled: Bool
        let color: Color
        @ObservedObject private var themeManager = ThemeManager.shared

        init(isSelected: Bool = false, isDisabled: Bool = false, color: Color = .yellow) {
            self.isSelected = isSelected
            self.isDisabled = isDisabled
            self.color = color
        }

        func body(content: Content) -> some View {
            content
                .font(.subheadline)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .foregroundColor(
                    isSelected
                        ? color : (isDisabled ? .gray : (themeManager.isDarkMode ? .white : .black))
                )
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                                ? (themeManager.isDarkMode
                                    ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                    : Color(red: 0.95, green: 0.95, blue: 0.95))
                                : (themeManager.isDarkMode
                                    ? Color(red: 0.184, green: 0.184, blue: 0.184)
                                    : Color(red: 0.9, green: 0.9, blue: 0.9))
                        )
                        .opacity(isDisabled ? 0.5 : 1)
                )
                .overlay(
                    Group {
                        if isSelected {
                            Capsule()
                                .stroke(color.opacity(0.7), lineWidth: 1.5)
                        } else {
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(isDisabled ? 0.3 : 0.7),
                                            Color.gray.opacity(isDisabled ? 0.1 : 0.3),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isDisabled ? 0.5 : 1.0
                                )
                        }
                    }
                )
                .shadow(
                    color: isSelected ? color.opacity(0.3) : .black.opacity(0.1), radius: 3, x: 0,
                    y: 1
                )
                .opacity(isDisabled ? 0.6 : 1)
        }
    }

    // Модификатор для табов
    private struct TabButtonModifier: ViewModifier {
        let isSelected: Bool
        @ObservedObject private var themeManager = ThemeManager.shared

        func body(content: Content) -> some View {
            content
                .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .yellow : (themeManager.isDarkMode ? .white : .black))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    isSelected
                        ? RoundedRectangle(cornerRadius: 12)
                            .fill(
                                themeManager.isDarkMode
                                    ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                    : Color(red: 0.95, green: 0.95, blue: 0.95)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                        : nil
                )
        }
    }

    // Модификатор для декоративных кнопок
    private struct IconButtonModifier: ViewModifier {
        let color: Color
        @ObservedObject private var themeManager = ThemeManager.shared

        func body(content: Content) -> some View {
            content
                .font(.system(size: 22))
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                )
                .overlay(
                    Circle()
                        .stroke(
                            themeManager.isDarkMode
                                ? Color.white.opacity(0.2) : Color.black.opacity(0.1), lineWidth: 1)
                )
                .shadow(color: color.opacity(0.3), radius: 3, x: 0, y: 1)
        }
    }

    // Панель с аватаром категории и названием
    private var categoryPreviewCard: some View {
        VStack(spacing: 0) {
            // Аватар категории
            VStack(spacing: 16) {
                Image(systemName: selectedIcon)
                    .font(.system(size: 40))
                    .frame(width: 84, height: 84)
                    .background(
                        Circle()
                            .fill(selectedColor)
                    )
                    .shadow(color: selectedColor.opacity(0.5), radius: 8, x: 0, y: 4)
                    .padding(.top, 12)

                // Название категории
                TextField("",
                    text: $categoryName,
                    prompt: Text("categoryEditor.categoryNamePlaceholder".localized)
                        .foregroundColor(themeManager.isDarkMode ? .gray : .gray.opacity(0.7))
                )
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(themeManager.isDarkMode ? .white : .black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                themeManager.isDarkMode
                                    ? Color(red: 0.18, green: 0.18, blue: 0.18)
                                    : Color(red: 0.95, green: 0.95, blue: 0.95)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedColor.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .focused($isTextFieldFocused)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    themeManager.isDarkMode
                        ? Color(red: 0.16, green: 0.16, blue: 0.16)
                        : Color(red: 0.98, green: 0.98, blue: 0.98))
                .shadow(color: themeManager.isDarkMode ? .black.opacity(0.2) : .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    // Панель настроек категории
    private var settingsTab: some View {
        VStack(spacing: 16) {
            // Основные настройки
            if !showingInlineColorPicker {
                VStack(spacing: 12) {
                    // Выбор иконки
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                        showingIconPicker = true
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "square.grid.2x2")
                                .modifier(IconButtonModifier(color: Color.blue))

                            Text("categoryEditor.changeIcon".localized)
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    themeManager.isDarkMode
                                        ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                        : Color(red: 0.95, green: 0.95, blue: 0.95))
                        )
                    }

                    // Выбор цвета
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                        showingInlineColorPicker = true
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: "paintpalette")
                                .modifier(IconButtonModifier(color: Color.Apricot1))

                            Text("categoryEditor.changeColor".localized)
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)

                            Spacer()

                            Circle()
                                .fill(selectedColor)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            themeManager.isDarkMode
                                                ? Color.white.opacity(0.3) : Color.black.opacity(0.1),
                                            lineWidth: 1)
                                )

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    themeManager.isDarkMode
                                        ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                        : Color(red: 0.95, green: 0.95, blue: 0.95))
                        )
                    }

                    // Видимость категории
                    Button(action: {
                        feedbackGenerator.impactOccurred()
                        isHidden.toggle()
                    }) {
                        HStack(spacing: 14) {
                            Image(systemName: isHidden ? "eye.slash" : "eye")
                                .modifier(IconButtonModifier(color: Color.teal))

                            Text(isHidden ? "categoryEditor.categoryHidden".localized : "categoryEditor.categoryVisible".localized)
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.isDarkMode ? .white : .black)

                            Spacer()

                            Text(isHidden ? "categoryEditor.show".localized : "categoryEditor.hide".localized)
                                .font(.system(size: 14))
                                .foregroundColor(
                                    isHidden
                                        ? .yellow
                                        : (themeManager.isDarkMode ? .gray : .gray.opacity(0.7)))
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    themeManager.isDarkMode
                                        ? Color(red: 0.22, green: 0.22, blue: 0.22)
                                        : Color(red: 0.95, green: 0.95, blue: 0.95))
                        )
                    }
                    .disabled(editingCategory == nil)
                    .opacity(editingCategory == nil ? 0.5 : 1.0)
                }
                .padding(.horizontal, 16)

                // Кнопки действий
                VStack(spacing: 12) {
                    if editingCategory == nil {
                        // Кнопка добавления категории
                        Button(action: {
                            feedbackGenerator.impactOccurred()
                            saveCategory(autoClose: false)
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("categoryEditor.addCategory".localized)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .modifier(ButtonModifier(color: .blue))
                        .padding(.horizontal, 50)
                        .disabled(categoryName.isEmpty)
                    } else {
                        // Кнопка удаления категории
                        Button(action: {
                            feedbackGenerator.impactOccurred()
                            showingDeleteAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18))
                                Text("categoryEditor.deleteCategory".localized)
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .modifier(ButtonModifier(color: .red))
                        .padding(.horizontal, 50)
                    }
                }
                .padding(.top, 20)
            }
            
            // Панель выбора цвета
            if showingInlineColorPicker {
                VStack(spacing: 16) {
                    HStack {
                        Text("categoryEditor.colorPickerTitle".localized)
                            .font(.headline)
                            .foregroundColor(themeManager.isDarkMode ? .white : .black)
                        
                        Spacer()
                        
                        Button(action: {
                            showingInlineColorPicker = false
                        }) {
                            Text("categoryEditor.done".localized)
                                .font(.caption)
                                .foregroundColor(themeManager.isDarkMode ? .yellow : .red1)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(themeManager.isDarkMode ? Color.yellow : Color.red1, lineWidth: 1)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Градиентный слайдер для выбора яркости цвета
                    ZStack(alignment: .center) {
                        // Градиент от светлого к темному
                        LinearGradient(
                            gradient: Gradient(colors: [
                                ColorUtils.brightenColor(currentBaseColor, factor: 1.3),
                                currentBaseColor,
                                ColorUtils.darkenColor(currentBaseColor, factor: 0.7)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(height: 26)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Ползунок слайдера
                        GeometryReader { geometry in
                            let paddingHorizontal: CGFloat = 30
                            let width = geometry.size.width - paddingHorizontal*2
                            let minX = paddingHorizontal
                            let currentX = minX + (width * sliderBrightnessPosition)
                            
                            Circle()
                                .fill(.white)
                                .frame(width: 36, height: 36)
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                                .overlay(
                                    Circle()
                                        .fill(ColorUtils.getColorAt(position: sliderBrightnessPosition, baseColor: currentBaseColor))
                                        .frame(width: 24, height: 24)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                                .position(x: currentX, y: geometry.size.height / 2)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let maxX = minX + width
                                            let xPosition = min(max(value.location.x, minX), maxX)
                                            sliderBrightnessPosition = (xPosition - minX) / width
                                            
                                            let newColor = ColorUtils.getColorAt(
                                                position: sliderBrightnessPosition, 
                                                baseColor: currentBaseColor
                                            )
                                            selectedColor = newColor
                                            selectedColorHex = newColor.toHex() ?? ""
                                        }
                                )
                        }
                    }
                    .frame(height: 50)
                    .padding(.bottom, 10)
                    .padding(.horizontal)
                    .onAppear {
                        initializeSliderPosition()
                    }
                    
                    // Скролл с готовыми цветами
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            
                            let standardColors: [Color] = [
                                .Lilac1, .Pink1, .red1, .Peony1, .Rose1, .coral1, .Orange1, .yellow1, .green0, .green1,
                                .Clover1, .Mint1, .Teal1, .Blue1, .LightBlue1, .BlueJay1, .OceanBlue1,
                                .StormBlue1, .Indigo1, .Purple1 
                            ]
                            
                            ForEach(0..<standardColors.count, id: \.self) { index in
                                colorButton(color: standardColors[index], index: index)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .frame(height: 50)
                }
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeManager.isDarkMode ? Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98) : Color(red: 0.95, green: 0.95, blue: 0.95).opacity(0.98))
                        .shadow(radius: 8)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 16)
        .animation(.easeInOut(duration: 0.2), value: showingInlineColorPicker)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Отображаем DockBarEditorIOS только когда TextField НЕ в фокусе
                    if !isTextFieldFocused {
                        DockBarEditorIOS(
                            viewModel: viewModel,
                            selectedCategory: Binding(
                                get: { selectedDockCategory },
                                set: { newCategory in
                                    if newCategory != selectedDockCategory {
                                        // Сохраняем изменения предыдущей категории
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
                                            // Сбрасываем значения для новой категории
                                            editingCategory = nil
                                            categoryName = ""
                                            selectedColor = .blue
                                            selectedIcon = "star.fill"
                                            isHidden = false
                                        }
                                    }
                                }
                            ),
                            editingCategory: editingCategory != nil
                                ? TaskCategoryModel(
                                    id: editingCategory!.id,
                                    rawValue: categoryName.isEmpty
                                        ? editingCategory!.rawValue : categoryName,
                                    iconName: selectedIcon,
                                    color: selectedColor,
                                    isHidden: isHidden
                                )
                                : (selectedDockCategory == nil ? previewCategory : nil)
                        )
                        .padding(.top, 30)
                        .id("dockBarEditor")
                        .transition(.opacity)
                    } else {
                        // Когда DockBarEditorIOS скрыт, добавляем пустое пространство с отступом 150
                        Spacer()
                            .frame(height: 150)
                            .transition(.opacity)
                    }

                    categoryPreviewCard

                    if activeTab == .settings {
                        settingsTab
                    } else if activeTab == .appearance {
                        // Здесь можно добавить другие вкладки, если необходимо
                        settingsTab  // Временно используем тот же контент
                    } else if activeTab == .visibility {
                        settingsTab  // Временно используем тот же контент
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    themeManager.isDarkMode
                        ? Color(red: 0.098, green: 0.098, blue: 0.098)
                        : Color(red: 0.98, green: 0.98, blue: 0.98)
                )
                .navigationTitle(
                    editingCategory == nil ? "categoryEditor.newCategory".localized : "categoryEditor.editCategory".localized
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(
                    themeManager.isDarkMode
                        ? Color(red: 0.098, green: 0.098, blue: 0.098)
                        : Color(red: 0.95, green: 0.95, blue: 0.95), for: .navigationBar
                )
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(themeManager.isDarkMode ? .dark : .light, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("categoryEditor.cancel".localized) {
                            feedbackGenerator.impactOccurred()
                            isPresented = false
                        }
                        .foregroundColor(.red1)
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("categoryEditor.done".localized) {
                            feedbackGenerator.impactOccurred()
                            saveCategory(autoClose: true)
                        }
                        .disabled(categoryName.isEmpty)
                    }

                    // Добавляем кнопку для скрытия клавиатуры, если поле в фокусе
                    ToolbarItem(placement: .keyboard) {
                        Button("categoryEditor.done".localized) {
                            isTextFieldFocused = false
                        }
                        .foregroundColor(.coral1)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)  // Анимация изменения состояния фокуса
            }
        }
        .presentationDetents([.height(UIScreen.main.bounds.height * 0.8)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showingIconPicker) {
            NavigationView {
                IconPickerView(
                    selectedIcon: $selectedIcon, iconColor: selectedColor,
                    isPresented: $showingIconPicker)
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    // Палитра стандартных цветов
                    VStack(alignment: .leading) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                            let standardColors: [Color] = [
                                .coral1, .red1, .Orange1, .Apricot1, .yellow1, .Clover1, .green0,
                                .green1, .Mint1,
                                .Teal1, .Blue1, .LightBlue1, .BlueJay1, .OceanBlue1,
                                .StormBlue1, .Indigo1, .Purple1, .Lilac1, .Pink1,
                                .Peony1, .Rose1,
                            ]

                            ColorPicker("categoryEditor.selectColor".localized, selection: $selectedColor)
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
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    Color.white,
                                                    lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .navigationTitle("categoryEditor.colorPickerTitle".localized)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("categoryEditor.done".localized) {
                            feedbackGenerator.impactOccurred()
                            showingColorPicker = false
                        }
                        .foregroundColor(.coral1)
                    }
                }
            }
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.visible)
        }
        .alert("categoryEditor.deleteAlertTitle".localized, isPresented: $showingDeleteAlert) {
            Button("categoryEditor.cancel".localized, role: .cancel) {}
            Button("categoryEditor.deleteCategory".localized, role: .destructive) {
                if let category = editingCategory {
                    viewModel.categoryManagement.removeCategory(category)
                    // Удаляем строку isPresented = false
                    // Устанавливаем значения для создания новой категории
                    editingCategory = nil
                    selectedDockCategory = nil
                    categoryName = ""
                    selectedColor = .blue
                    selectedIcon = "star.fill"
                    isHidden = false
                }
            }
        } message: {
            Text("categoryEditor.deleteAlertMessage".localized)
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
            // При добавлении новой категории просто добавляем её
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

    // Добавьте эти функции в структуру CategoryEditorViewIOS
    func colorButton(color: Color, index: Int? = nil) -> some View {
        // Определяем, выбрана ли эта кнопка
        let isSelected = selectedColor.toHex() == color.toHex()
        
        return Button(action: {
            selectedColor = color
            selectedColorHex = color.toHex() ?? ""
            currentBaseColor = ColorUtils.getBaseColor(forColor: color)
            updateSliderPosition()
            feedbackGenerator.impactOccurred()
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                        )
                        .shadow(color: Color.yellow.opacity(0.6), radius: 4, x: 0, y: 0)
                }
                
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: isSelected ? 1.5 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ColorUtils.isLightColor(color) ? .black : .white)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Инициализирует положение слайдера на основе текущей яркости цвета
    func initializeSliderPosition() {
        currentBaseColor = ColorUtils.getBaseColor(forColor: selectedColor)
        
        let brightness = ColorUtils.getBrightness(of: selectedColor) / ColorUtils.getBrightness(of: currentBaseColor)
        
        if brightness <= 0.7 {
            sliderBrightnessPosition = 1.0
        } else if brightness >= 1.3 {
            sliderBrightnessPosition = 0.0
        } else {
            sliderBrightnessPosition = 1.0 - ((brightness - 0.7) / 0.6)
        }
    }

    // Обновляет положение слайдера
    func updateSliderPosition() {
        let brightness = ColorUtils.getBrightness(of: selectedColor) / ColorUtils.getBrightness(of: currentBaseColor)
        
        if brightness <= 0.7 {
            sliderBrightnessPosition = 1.0
        } else if brightness >= 1.3 {
            sliderBrightnessPosition = 0.0
        } else {
            sliderBrightnessPosition = 1.0 - ((brightness - 0.7) / 0.6)
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
