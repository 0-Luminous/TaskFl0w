//
//  ClockFaceEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 20/2/25.
//

import SwiftUI

struct ClockFaceEditorViewIOS: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("clockStyle") private var clockStyle: ClockStyle = .classic
    @AppStorage("isDarkMode") private var isDarkMode = false {
        didSet {
            // При изменении isDarkMode через AppStorage обновляем и ThemeManager
            themeManager.setTheme(isDarkMode)
        }
    }
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white
        .toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black
        .toHex()
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray
        .toHex()
    @AppStorage("showHourNumbers") private var showHourNumbers: Bool = true
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("markersOffset") private var markersOffset: Double = 40.0
    @AppStorage("numbersSize") private var numbersSize: Double = 12.0

    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Предпросмотр циферблата
                clockPreviewSection

                // Настройки
                settingsList
            }
            .padding(.top)
            .navigationTitle("Настройка циферблата")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        feedbackGenerator.impactOccurred()
                        // Гарантируем синхронизацию Theme и AppStorage перед закрытием
                        themeManager.setTheme(isDarkMode)
                        dismiss()
                    }
                }
            }
            .interactiveDismissDisabled(true)
            .onAppear {
                // Гарантируем, что isDarkMode синхронизирован с ThemeManager при появлении
                isDarkMode = themeManager.isDarkMode
                viewModel.isDarkMode = themeManager.isDarkMode
                markersViewModel.isDarkMode = themeManager.isDarkMode
                // Принудительно обновляем UI для правильного отображения
                updateColorsForCurrentTheme()
            }
        }
        // Применяем цветовую схему для всего представления
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }

    // MARK: - UI Components

    private var clockPreviewSection: some View {
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
                markersViewModel: markersViewModel,
                draggedCategory: .constant(nil),
                zeroPosition: viewModel.zeroPosition
            )
        }
        .frame(height: UIScreen.main.bounds.width * 0.8)
        .padding(.vertical, 20)
        // Используем текущую тему для предпросмотра, а не сохраненное значение
        .environment(\.colorScheme, themeManager.isDarkMode ? .dark : .light)
        .onAppear(perform: setupInitialValues)
        .onChange(of: showHourNumbers) { _, newValue in
            markersViewModel.showHourNumbers = newValue
        }
        .onChange(of: markersWidth) { _, newValue in
            markersViewModel.markersWidth = newValue
        }
        .onChange(of: markersOffset) { _, newValue in
            markersViewModel.markersOffset = newValue
        }
        .onChange(of: numbersSize) { _, newValue in
            markersViewModel.numbersSize = newValue
        }
        .onChange(of: lightModeMarkersColor) { _, newValue in
            markersViewModel.lightModeMarkersColor = newValue
            updateMarkersViewModel()
        }
        .onChange(of: darkModeMarkersColor) { _, newValue in
            markersViewModel.darkModeMarkersColor = newValue
            updateMarkersViewModel()
        }
        .onChange(of: themeManager.isDarkMode) { _, newValue in
            // Немедленно обновляем предпросмотр при изменении темы
            markersViewModel.isDarkMode = newValue
            viewModel.isDarkMode = newValue
            isDarkMode = newValue
            updateMarkersViewModel()
            updateColorsForCurrentTheme()
        }
    }

    private var settingsList: some View {
        List {
            // Секция стиля циферблата
            clockStyleSection

            // Секция цветов
            colorsSection

            // Секция маркеров
            markersSection
        }
    }

    private var clockStyleSection: some View {
        Section(header: Text("СТИЛЬ ЦИФЕРБЛАТА")) {
            HStack {
                Text("Стиль")
                Spacer()
                Text(clockStyle.rawValue.capitalized)
                    .foregroundColor(.gray)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                switch clockStyle {
                case .classic:
                    clockStyle = .minimal
                case .minimal:
                    clockStyle = .modern
                case .modern:
                    clockStyle = .classic
                }
            }

            Toggle("Тёмная тема", isOn: Binding(
                get: { themeManager.isDarkMode },
                set: { newValue in
                    // Используем themeManager напрямую для переключения темы
                    if newValue != themeManager.isDarkMode {
                        // Переключаем тему напрямую
                        themeManager.toggleDarkMode()
                        
                        // Синхронизируем локальное состояние
                        DispatchQueue.main.async {
                            // Обновляем isDarkMode для AppStorage
                            isDarkMode = themeManager.isDarkMode
                            
                            // Синхронизируем ViewModel
                            viewModel.isDarkMode = themeManager.isDarkMode
                            markersViewModel.isDarkMode = themeManager.isDarkMode
                            
                            // Применяем эффект вибрации
                            feedbackGenerator.impactOccurred()
                            
                            // Принудительно обновляем UI для правильного отображения
                            updateColorsForCurrentTheme()
                        }
                    }
                }
            ))
        }
    }

    private var colorsSection: some View {
        Section(header: Text("ЦВЕТА")) {
            clockFaceColorPicker
            outerRingColorPicker
            markersColorPicker
        }
    }

    private var clockFaceColorPicker: some View {
        ColorPicker(
            "Цвет циферблата",
            selection: Binding(
                get: {
                    Color(
                        hex: isDarkMode
                            ? darkModeClockFaceColor : lightModeClockFaceColor)
                        ?? (isDarkMode ? .black : .white)
                },
                set: { newColor in
                    if isDarkMode {
                        darkModeClockFaceColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
                    } else {
                        lightModeClockFaceColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
                    }
                    // Принудительно обновляем UI
                    updateColorsForCurrentTheme()
                }
            ))
    }

    private var outerRingColorPicker: some View {
        ColorPicker(
            "Цвет внешнего круга",
            selection: Binding(
                get: {
                    Color(
                        hex: isDarkMode
                            ? darkModeOuterRingColor : lightModeOuterRingColor)
                        ?? .gray.opacity(0.3)
                },
                set: { newColor in
                    if isDarkMode {
                        darkModeOuterRingColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.darkModeOuterRingColorKey)
                    } else {
                        lightModeOuterRingColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.lightModeOuterRingColorKey)
                    }
                    // Принудительно обновляем UI
                    updateColorsForCurrentTheme()
                }
            ))
    }

    private var markersColorPicker: some View {
        ColorPicker(
            "Цвет маркеров",
            selection: Binding(
                get: {
                    Color(
                        hex: isDarkMode
                            ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
                },
                set: { newColor in
                    if isDarkMode {
                        darkModeMarkersColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.darkModeMarkersColorKey)
                        // Обновляем markersViewModel
                        markersViewModel.darkModeMarkersColor = newColor.toHex()
                    } else {
                        lightModeMarkersColor = newColor.toHex()
                        // Обновляем цвет в ThemeManager
                        themeManager.updateColor(newColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
                        // Обновляем markersViewModel
                        markersViewModel.lightModeMarkersColor = newColor.toHex()
                    }
                    // Принудительно обновляем UI
                    updateColorsForCurrentTheme()
                    updateMarkersViewModel()
                }
            ))
    }

    private var markersSection: some View {
        Section(header: Text("МАРКЕРЫ")) {
            Toggle("Показывать цифры часов", isOn: $showHourNumbers)

            zeroPositionSlider

            if showHourNumbers {
                numbersSizeSlider
            }

            markersWidthSlider

            markersOffsetSlider
        }
    }

    private var zeroPositionSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Положение нуля")
            Slider(
                value: Binding(
                    get: { viewModel.zeroPosition },
                    set: { viewModel.updateZeroPosition($0) }
                ),
                in: 0...360,
                step: 15
            )
            .onChange(of: viewModel.zeroPosition) { oldValue, newValue in
                feedbackGenerator.impactOccurred()
            }
            HStack {
                Text("0°")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("360°")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("Текущее положение: \(Int(viewModel.zeroPosition))°")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }

    private var numbersSizeSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Размер цифр")
            Slider(value: $numbersSize, in: 8...16, step: 1.0)
                .onChange(of: numbersSize) { oldValue, newValue in
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            HStack {
                Text("8")
                    .font(.system(size: 8))
                    .foregroundColor(.gray)
                Spacer()
                Text("16")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private var markersWidthSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Толщина маркеров")
            Slider(value: $markersWidth, in: 1...4, step: 0.5)
                .onChange(of: markersWidth) { oldValue, newValue in
                    feedbackGenerator.impactOccurred()
                }
            HStack {
                Text("Тонкие")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Жирные")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    private var markersOffsetSlider: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Отступ маркеров")
            Slider(value: $markersOffset, in: 0...60, step: 5)
                .onChange(of: markersOffset) { oldValue, newValue in
                    feedbackGenerator.impactOccurred()
                }
            HStack {
                Text("Ближе")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("Дальше")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helper Methods

    private func setupInitialValues() {
        // Инициализируем начальные значения
        markersViewModel.showHourNumbers = showHourNumbers
        markersViewModel.markersWidth = markersWidth
        markersViewModel.markersOffset = markersOffset
        markersViewModel.numbersSize = numbersSize
        markersViewModel.lightModeMarkersColor = lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = darkModeMarkersColor
        markersViewModel.isDarkMode = isDarkMode
        updateMarkersViewModel()
    }

    private var currentClockFaceColor: Color {
        let hexColor = isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        return Color(hex: hexColor) ?? (isDarkMode ? .black : .white)
    }

    private var currentOuterRingColor: Color {
        let hexColor = isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }

    private func updateMarkersViewModel() {
        // Создаем временное обновление для принудительного обновления вида
        // Этот небольшой трюк заставит SwiftUI перерисовать представление
        DispatchQueue.main.async {
            let tempValue = markersViewModel.markersWidth
            markersViewModel.markersWidth = tempValue + 0.01
            DispatchQueue.main.async {
                markersViewModel.markersWidth = tempValue
            }
        }
    }

    // Дополнительный метод для принудительного обновления цветов
    private func updateColorsForCurrentTheme() {
        DispatchQueue.main.async {
            // Принудительно вызываем обновления UI
            viewModel.objectWillChange.send()
            markersViewModel.objectWillChange.send()
            themeManager.objectWillChange.send()
        }
    }
}

#Preview {
    ClockFaceEditorViewIOS()
}
