//
//  ClockEditorView.swift
//  TaskFl0w
//
//  Created by Yan on 27/4/25.
//

import SwiftUI

struct ClockEditorView: View {
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    let taskArcLineWidth: CGFloat

    @AppStorage("lightModeOuterRingColor") private var lightModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("darkModeOuterRingColor") private var darkModeOuterRingColor: String = Color.gray
        .opacity(0.3).toHex()
    @AppStorage("lightModeClockFaceColor") private var lightModeClockFaceColor: String = Color.white
        .toHex()
    @AppStorage("darkModeClockFaceColor") private var darkModeClockFaceColor: String = Color.black
        .toHex()
    @AppStorage("lightModeMarkersColor") private var lightModeMarkersColor: String = Color.black
        .toHex()
    @AppStorage("darkModeMarkersColor") private var darkModeMarkersColor: String = Color.gray
        .toHex()

    @AppStorage("showMarkers") private var showMarkers: Bool = true
    @AppStorage("fontName") private var fontName: String = "SF Pro"
    @AppStorage("showTimeOnlyForActiveTask") private var showTimeOnlyForActiveTask: Bool = false

    @Environment(\.presentationMode) var presentationMode
    @State private var showClockControls = false
    @State private var showColorControls = false
    @State private var showOuterRingWidthControls = false
    @State private var showArcAnalogToggle = false
    @State private var showMarkersControls = false
    @State private var showFontPicker = false
    @State private var showSizeSettings = false
    @State private var showIntervalSettings = false
    @State private var showColorPickerSheet = false
    @State private var colorPickerType = ""
    @State private var sliderBrightnessPosition: CGFloat = 0.5

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    clockPreviewSection
                        .padding(
                            .bottom,
                            (showClockControls || showColorControls || showOuterRingWidthControls
                                || showArcAnalogToggle || showMarkersControls) ? 180 : 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.098, green: 0.098, blue: 0.098))
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                    }
                }

                VStack(spacing: 0) {
                    if showClockControls {
                        clockControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showColorControls {
                        colorControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showOuterRingWidthControls {
                        outerRingWidthControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showArcAnalogToggle {
                        arcAnalogTogglePanel
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showMarkersControls {
                        markersControls
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    dockBar
                }
                .animation(.spring(), value: showClockControls)
                .animation(.spring(), value: showColorControls)
            }
        }
        .onAppear {
            syncMarkersViewModelWithAppStorage()
        }
        .onDisappear {
            saveMarkersViewModelToAppStorage()
        }
    }

    private var clockPreviewSection: some View {
        ZStack {
            // Внешнее кольцо
            Circle()
                .stroke(currentOuterRingColor, lineWidth: viewModel.outerRingLineWidth)
                .frame(
                    width: UIScreen.main.bounds.width * 0.8,
                    height: UIScreen.main.bounds.width * 0.8
                )

            // Сам циферблат
            GlobleClockFaceViewIOS(
                currentDate: viewModel.selectedDate,
                tasks: viewModel.tasks,
                viewModel: viewModel,
                markersViewModel: viewModel.markersViewModel,
                draggedCategory: .constant(nil),
                zeroPosition: viewModel.zeroPosition,
                taskArcLineWidth: viewModel.isAnalogArcStyle
                    ? viewModel.outerRingLineWidth : viewModel.taskArcLineWidth,
                outerRingLineWidth: viewModel.outerRingLineWidth
            )
        }
        .frame(height: UIScreen.main.bounds.width * 0.8)
        .padding(.vertical, 20)
    }

    private var currentOuterRingColor: Color {
        let isDarkMode = themeManager.isDarkMode
        let hexColor = isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }

    // Создаем расширение для модификатора кнопок
    private struct ButtonModifier: ViewModifier {
        let isSelected: Bool
        let isDisabled: Bool
        
        init(isSelected: Bool = false, isDisabled: Bool = false) {
            self.isSelected = isSelected
            self.isDisabled = isDisabled
        }
        
        func body(content: Content) -> some View {
            content
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundColor(isSelected ? .yellow : (isDisabled ? .gray : .white))
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(Color(red: 0.184, green: 0.184, blue: 0.184)
                            .opacity(isDisabled ? 0.5 : 1))
                )
                .overlay(
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
                )
                .shadow(
                    color: isSelected ? Color.yellow.opacity(0.2) : .black.opacity(0.5), radius: 3,
                    x: 0,
                    y: isSelected ? 0 : 2
                )
                .opacity(isDisabled ? 0.6 : 1)
        }
    }
    
    // Модификатор для декоративных кнопок панели инструментов
    private struct DockButtonModifier: ViewModifier {
        let isSelected: Bool
        
        func body(content: Content) -> some View {
            content
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .yellow : .white)
                .padding(6)
                .background(
                    Circle()
                        .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.7), Color.gray.opacity(0.3),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
        }
    }
    
    // Модификатор для кнопок навигации
    private struct NavigationButtonModifier: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .foregroundColor(.white)
                .background(
                    Capsule()
                        .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.7),
                                    Color.gray.opacity(0.3),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
        }
    }
    
    // Применяем модификаторы к View
    private func styleButton(_ content: some View, isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        content.modifier(ButtonModifier(isSelected: isSelected, isDisabled: isDisabled))
    }
    
    private func styleDockButton(_ content: some View, isSelected: Bool = false) -> some View {
        content.modifier(DockButtonModifier(isSelected: isSelected))
    }
    
    private func styleNavigationButton(_ content: some View) -> some View {
        content.modifier(NavigationButtonModifier())
    }

    private var dockBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                withAnimation {
                    showClockControls.toggle()
                    if showClockControls {
                        showArcAnalogToggle = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                    }
                }
            }) {
                Image(systemName: "clock")
                    .modifier(DockButtonModifier(isSelected: showClockControls))
            }

            Button(action: {
                withAnimation {
                    showMarkersControls.toggle()
                    if showMarkersControls {
                        showClockControls = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showArcAnalogToggle = false
                    }
                }
            }) {
                Image(systemName: "slowmo")
                    .modifier(DockButtonModifier(isSelected: showMarkersControls))
            }

            Button(action: {
                withAnimation {
                    showColorControls.toggle()
                    if showColorControls {
                        showClockControls = false
                        showArcAnalogToggle = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                    }
                }
            }) {
                Image(systemName: "paintpalette")
                    .modifier(DockButtonModifier(isSelected: showColorControls))
            }

            Button(action: {
                withAnimation {
                    showOuterRingWidthControls.toggle()
                    if showOuterRingWidthControls {
                        showClockControls = false
                        showColorControls = false
                        showArcAnalogToggle = false
                        showMarkersControls = false
                    }
                }
            }) {
                Image(systemName: "clock.circle")
                    .modifier(DockButtonModifier(isSelected: showOuterRingWidthControls))
            }

            Button(action: {
                // Действие 4
            }) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .modifier(DockButtonModifier(isSelected: false))
            }

            Button(action: {
                withAnimation {
                    showArcAnalogToggle.toggle()
                    if showArcAnalogToggle {
                        showClockControls = false
                        showColorControls = false
                        showOuterRingWidthControls = false
                        showMarkersControls = false
                    }
                }
            }) {
                Image(systemName: "gearshape")
                    .modifier(DockButtonModifier(isSelected: showArcAnalogToggle))
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 16)
        .frame(width: UIScreen.main.bounds.width * 0.95)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15).opacity(0.95))
                .shadow(radius: 8)
        )
        .padding(.bottom, 24)
    }

    private var clockControls: some View {
        VStack(spacing: 16) {
            Text("Настройки циферблата")
                .font(.headline)
                .foregroundColor(.white)

            if showFontPicker {
                HStack {
                    Text("Выберите шрифт")
                        .font(.headline)
                        .foregroundColor(.white)
                        

                    Spacer()

                    Button(action: {
                        withAnimation {
                            showFontPicker = false
                        }
                    }) {
                        Text("Готово")
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                    }
                }
                .padding(.bottom, 8)

                Picker(
                    "",
                    selection: Binding(
                        get: { markersViewModel.fontName },
                        set: {
                            markersViewModel.fontName = $0
                            fontName = $0
                        }
                    )
                ) {
                    ForEach(markersViewModel.customFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.wheel)
                .foregroundColor(.white)
            } else if showSizeSettings {
                // Настройки размера цифр
                HStack {
                    Text("Размер цифр")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            showSizeSettings = false
                        }
                    }) {
                        Text("Готово")
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                    }
                }
                .padding(.bottom, 8)
                
                HStack(spacing: 10) {
                    Button(action: {
                        if markersViewModel.numbersSize > 14 {
                            markersViewModel.numbersSize -= 1
                            viewModel.numbersSize = markersViewModel.numbersSize
                        }
                    }) {
                        Text("Меньше")
                            .modifier(ButtonModifier())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("\(Int(markersViewModel.numbersSize))")
                        .font(.system(size: 23))
                        .foregroundColor(.yellow)
                        .frame(width: 30)
                    
                    Button(action: {
                        if markersViewModel.numbersSize < 21 {
                            markersViewModel.numbersSize += 1
                            viewModel.numbersSize = markersViewModel.numbersSize
                        }
                    }) {
                        Text("Больше")
                            .modifier(ButtonModifier())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else if showIntervalSettings {
                // Настройки интервала цифр
                HStack {
                    Text("Интервал цифр")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation {
                            showIntervalSettings = false
                        }
                    }) {
                        Text("Готово")
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                    }
                }
                .padding(.bottom, 8)
                
                HStack(spacing: 10) {
                    Button(action: {
                        viewModel.numberInterval = 2
                        markersViewModel.numberInterval = 2
                    }) {
                        Text("2 часа")
                            .modifier(ButtonModifier(isSelected: viewModel.numberInterval == 2))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.numberInterval = 3
                        markersViewModel.numberInterval = 3
                    }) {
                        Text("3 часа")
                            .modifier(ButtonModifier(isSelected: viewModel.numberInterval == 3))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        viewModel.numberInterval = 6
                        markersViewModel.numberInterval = 6
                    }) {
                        Text("6 часов")
                            .modifier(ButtonModifier(isSelected: viewModel.numberInterval == 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // Показываем настройки цифр только для стиля "Минимализм"
                if viewModel.clockStyle == "Минимализм" {
                    // Первая строка: показать/скрыть и интервал
                    HStack(spacing: 10) {
                        // Кнопка показать/скрыть цифры
                        Button(action: {
                            markersViewModel.showHourNumbers.toggle()
                            viewModel.showHourNumbers = markersViewModel.showHourNumbers
                        }) {
                            HStack {
                                Text(markersViewModel.showHourNumbers ? "Скрыть" : "Показать")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(systemName: markersViewModel.showHourNumbers ? "eye.slash" : "eye")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Для стиля "Минимализм" сохраняем настройки интервала
                        Button(action: {
                            withAnimation {
                                showIntervalSettings = true
                            }
                        }) {
                            HStack {
                                Text("Интервал")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(viewModel.numberInterval) ч")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.leading, 2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 6)
                    
                    // Вторая строка: шрифт и размер для Минимализма
                    HStack(spacing: 10) {
                        // Кнопка изменения шрифта
                        Button(action: {
                            withAnimation {
                                showFontPicker = true
                            }
                        }) {
                            HStack {
                                Text("Шрифт")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(systemName: "textformat")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Кнопка размера цифр
                        Button(action: {
                            withAnimation {
                                showSizeSettings = true
                            }
                        }) {
                            HStack {
                                Text("Размер")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(Int(markersViewModel.numbersSize))")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.leading, 2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 6)
                }

                // Кнопки шрифта и размера для классического стиля
                if viewModel.clockStyle == "Классический" {
                    HStack(spacing: 10) {
                        // Кнопка изменения шрифта
                        Button(action: {
                            withAnimation {
                                showFontPicker = true
                            }
                        }) {
                            HStack {
                                Text("Шрифт")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Image(systemName: "textformat")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Кнопка размера цифр
                        Button(action: {
                            withAnimation {
                                showSizeSettings = true
                            }
                        }) {
                            HStack {
                                Text("Размер")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Text("\(Int(markersViewModel.numbersSize))")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.leading, 2)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.gray.opacity(0.7),
                                                Color.gray.opacity(0.3),
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.0
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.bottom, 6)
                }

                Text("Стиль")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: {
                            viewModel.clockStyle = "Классический"
                            if viewModel.numberInterval > 1 {
                                viewModel.numberInterval = 1
                                markersViewModel.numberInterval = 1
                            }
                            // При выходе из "Минимализм" включаем отображение цифр
                            viewModel.showHourNumbers = true
                            markersViewModel.showHourNumbers = true
                        }) {
                            Text("Классический")
                                .modifier(ButtonModifier(isSelected: viewModel.clockStyle == "Классический"))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            // Отключаем действие кнопки - оставляем пустой блок
                        }) {
                            Text("Контур")
                                .modifier(ButtonModifier(isDisabled: true))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(true) 
                        .overlay(
                            // Добавляем индикатор "скоро будет доступно"
                            Text("скоро")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.yellow.opacity(0.8))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(4)
                                .offset(x: 0, y: -12), 
                            alignment: .top
                        )
                    }

                    HStack(spacing: 10) {
                        Button(action: {
                            viewModel.clockStyle = "Цифровой"
                            if viewModel.numberInterval > 1 {
                                viewModel.numberInterval = 1
                                markersViewModel.numberInterval = 1
                            }
                            // При переходе на "Цифровой" стиль отключаем отображение цифр
                            viewModel.showHourNumbers = false
                            markersViewModel.showHourNumbers = false
                        }) {
                            Text("Цифровой")
                                .modifier(ButtonModifier(isSelected: viewModel.clockStyle == "Цифровой"))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            viewModel.clockStyle = "Минимализм"
                            // При переходе в "Минимализм" устанавливаем интервал 2 часа
                            viewModel.numberInterval = 2
                            markersViewModel.numberInterval = 2
                            // При переходе в "Минимализм" включаем отображение цифр
                            viewModel.showHourNumbers = true
                            markersViewModel.showHourNumbers = true
                        }) {
                            Text("Минимализм")
                                .modifier(ButtonModifier(isSelected: viewModel.clockStyle == "Минимализм"))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private var colorControls: some View {
        VStack(spacing: 16) {
            Text("Цвета циферблата")
                .font(.headline)
                .foregroundColor(.white)
            
            // Основная секция выбора цвета для циферблата
            VStack(alignment: .leading, spacing: 10) {
                Text("Циферблат")
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                // Градиентный слайдер для выбора яркости цвета
                ZStack(alignment: .center) {
                    // Получаем текущий цвет
                    let currentColor = Color(
                            hex: themeManager.isDarkMode
                            ? darkModeClockFaceColor : lightModeClockFaceColor
                    ) ?? .red
                    
                    // Получаем чистый оттенок для слайдера (без учета текущей яркости)
                    let baseColor = getBaseColor(forColor: currentColor)
                    
                    // Градиент от светлого к темному для выбранного цвета с уменьшенным диапазоном
                    LinearGradient(
                        gradient: Gradient(colors: [
                            brightenColor(baseColor, factor: 1.3),  // Умеренно светлый
                            baseColor,                              // Оригинальный цвет
                            darkenColor(baseColor, factor: 0.7)     // Умеренно темный
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
                    
                    // Текстовые метки
                    HStack {
                        Text("Светлее")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("Темнее")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 32)
                    
                    // Ползунок слайдера
                    GeometryReader { geometry in
                        let paddingHorizontal: CGFloat = 30
                        let width = geometry.size.width - paddingHorizontal*2
                        let minX = paddingHorizontal
                        
                        // Вычисляем текущую X-позицию на основе значения sliderBrightnessPosition
                        let currentX = minX + (width * sliderBrightnessPosition)
                        
                        Circle()
                            .fill(.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                            .overlay(
                                // Внутреннее кольцо показывает цвет на текущей позиции слайдера
                                Circle()
                                    .fill(getColorAt(position: sliderBrightnessPosition, baseColor: baseColor))
                                    .frame(width: 24, height: 24)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            )
                            .position(x: currentX, y: 13)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        // Определяем границы перемещения
                                        let maxX = minX + width
                                        
                                        // Ограничиваем X в пределах слайдера
                                        let xPosition = min(max(value.location.x, minX), maxX)
                                        
                                        // Вычисляем процент от 0 до 1
                                        sliderBrightnessPosition = (xPosition - minX) / width
                                        
                                        // Применяем новый цвет с соответствующей яркостью, 
                                        // используя базовый цвет (без учета текущей яркости)
                                        let newColor = getColorAt(position: sliderBrightnessPosition, baseColor: baseColor)
                                        
                                        if themeManager.isDarkMode {
                                            darkModeClockFaceColor = newColor.toHex()
                                        } else {
                                            lightModeClockFaceColor = newColor.toHex()
                                        }
                                    }
                            )
                    }
                }
                .frame(height: 50)
                .padding(.bottom, 10)
                .onAppear {
                    // При появлении определяем текущее положение ползунка
                    // на основе яркости сохраненного цвета
                    initializeSliderPosition()
                }
                
                // Скролл с готовыми цветами циферблата
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Добавляем базовые нейтральные цвета в начало
                        colorButton(color: .white, forType: "clockFace")
                        colorButton(color: Color(red: 0.1, green: 0.1, blue: 0.1), forType: "clockFace")
                        colorButton(color: Color(red: 0.85, green: 0.85, blue: 0.85), forType: "clockFace")
                        colorButton(color: Color(red: 0.2, green: 0.2, blue: 0.2), forType: "clockFace")
                        
                        // Стандартные цвета из приложения
                        let standardColors: [Color] = [
                            .coral1, .red1, .Orange1, .Apricot1, .yellow1, .green0, .green1, 
                            .Mint1, .Teal1, .Blue1, .LightBlue1, .BlueJay1, .OceanBlue1, 
                            .StormBlue1, .Indigo1, .Purple1, .Lilac1, .Pink1, .Peony1, .Rose1, .Clover1
                        ]
                        
                        ForEach(0..<standardColors.count, id: \.self) { index in
                            colorButton(color: standardColors[index], forType: "clockFace")
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .frame(height: 50)
            }
            
            // Кнопки для маркеров и внешнего кольца
            HStack(spacing: 10) {
                // Кнопка цвета маркеров
                Button(action: {
                    showColorPickerSheet(for: "markers")
                }) {
                    HStack {
                        Text("Маркеры")
                            .font(.caption)
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(
                                hex: themeManager.isDarkMode
                                    ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Кнопка цвета внешнего кольца
                Button(action: {
                    showColorPickerSheet(for: "outerRing")
                }) {
                    HStack {
                        Text("Внешнее кольцо")
                            .font(.caption)
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(
                                hex: themeManager.isDarkMode
                                    ? darkModeOuterRingColor : lightModeOuterRingColor) ?? .gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
        .sheet(isPresented: $showColorPickerSheet) {
            colorPickerSheetContent
        }
    }

    private func colorButton(color: Color, forType type: String) -> some View {
        let isSelected: Bool
        
        switch type {
        case "clockFace":
            isSelected = themeManager.isDarkMode ? 
                (Color(hex: darkModeClockFaceColor) == color) : 
                (Color(hex: lightModeClockFaceColor) == color)
        case "markers":
            isSelected = themeManager.isDarkMode ? 
                (Color(hex: darkModeMarkersColor) == color) : 
                (Color(hex: lightModeMarkersColor) == color)
        case "outerRing":
            isSelected = themeManager.isDarkMode ? 
                (Color(hex: darkModeOuterRingColor) == color) : 
                (Color(hex: lightModeOuterRingColor) == color)
        default:
            isSelected = false
        }
        
        return Button(action: {
            switch type {
            case "clockFace":
                        if themeManager.isDarkMode {
                    darkModeClockFaceColor = color.toHex()
                        } else {
                    lightModeClockFaceColor = color.toHex()
                }
            case "markers":
                if themeManager.isDarkMode {
                    darkModeMarkersColor = color.toHex()
                    viewModel.darkModeMarkersColor = color.toHex()
                    markersViewModel.darkModeMarkersColor = color.toHex()
                } else {
                    lightModeMarkersColor = color.toHex()
                    viewModel.lightModeMarkersColor = color.toHex()
                    markersViewModel.lightModeMarkersColor = color.toHex()
                }
                markersViewModel.updateCurrentThemeColors()
            case "outerRing":
                        if themeManager.isDarkMode {
                    darkModeOuterRingColor = color.toHex()
                    viewModel.darkModeOuterRingColor = color.toHex()
                        } else {
                    lightModeOuterRingColor = color.toHex()
                    viewModel.lightModeOuterRingColor = color.toHex()
                }
            default:
                break
            }
        }) {
            ZStack {
                // Внешний слой для выделения
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
                
                // Основной круг с цветом
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
                    
                // Маленькая точка или галочка в центре для выбранного цвета
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isLightColor(color) ? .black : .white)
                }
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func isLightColor(_ color: Color) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Формула для определения яркости
        let brightness = (red * 0.299 + green * 0.587 + blue * 0.114)
        return brightness > 0.7
    }

    private func showColorPickerSheet(for type: String) {
        colorPickerType = type
        showColorPickerSheet = true
    }

    private var colorPickerSheetContent: some View {
        NavigationView {
            VStack {
                if colorPickerType == "markers" {
            ColorPicker(
                        "Выберите цвет маркеров",
                selection: Binding(
                    get: {
                        Color(
                            hex: themeManager.isDarkMode
                                ? darkModeMarkersColor : lightModeMarkersColor) ?? .gray
                    },
                    set: { newColor in
                        if themeManager.isDarkMode {
                            darkModeMarkersColor = newColor.toHex()
                            viewModel.darkModeMarkersColor = newColor.toHex()
                            markersViewModel.darkModeMarkersColor = newColor.toHex()
                        } else {
                            lightModeMarkersColor = newColor.toHex()
                            viewModel.lightModeMarkersColor = newColor.toHex()
                            markersViewModel.lightModeMarkersColor = newColor.toHex()
                        }
                        // Принудительно обновляем цвета
                        markersViewModel.updateCurrentThemeColors()
                    }
                )
            )
            .foregroundColor(.white)
        .padding()
                } else if colorPickerType == "outerRing" {
                    ColorPicker(
                        "Выберите цвет кольца",
                        selection: Binding(
                            get: {
                                Color(
                                    hex: themeManager.isDarkMode
                                        ? darkModeOuterRingColor : lightModeOuterRingColor)
                                    ?? .gray.opacity(0.3)
                            },
                            set: { newColor in
                                if themeManager.isDarkMode {
                                    darkModeOuterRingColor = newColor.toHex()
                                    viewModel.darkModeOuterRingColor = newColor.toHex()
                                } else {
                                    lightModeOuterRingColor = newColor.toHex()
                                    viewModel.lightModeOuterRingColor = newColor.toHex()
                                }
                            }
                        )
                    )
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
            }
            .background(Color(red: 0.098, green: 0.098, blue: 0.098))
            .navigationTitle(colorPickerType == "markers" ? "Цвет маркеров" : "Цвет внешнего кольца")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showColorPickerSheet = false
                    }) {
                        Text("Готово")
                            .foregroundColor(.yellow)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .accentColor(.yellow)
    }

    private var outerRingWidthControls: some View {
        VStack(spacing: 16) {
            Text("Толщина внешнего кольца: \(Int(viewModel.outerRingLineWidth)) pt")
                .font(.headline)
                .foregroundColor(.white)
            Slider(
                value: Binding(
                    get: { viewModel.outerRingLineWidth },
                    set: { viewModel.outerRingLineWidth = $0 }
                ),
                in: 20...38,
                step: 1
            )

            if !viewModel.isAnalogArcStyle {
                Divider().background(Color.white.opacity(0.2))
                Text("Толщина дуги задачи: \(Int(viewModel.taskArcLineWidth)) pt")
                    .font(.headline)
                    .foregroundColor(.white)
                Slider(value: $viewModel.taskArcLineWidth, in: 20...26, step: 1)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private var arcAnalogTogglePanel: some View {
        VStack(spacing: 16) {
            Text("Отображения дуги")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Первая строка: Аналоговый вид дуги
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation {
                        viewModel.isAnalogArcStyle = false
                    }
                }) {
                    Text("Стандартный")
                        .modifier(ButtonModifier(isSelected: !viewModel.isAnalogArcStyle))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation {
                        viewModel.isAnalogArcStyle = true
                    }
                }) {
                    Text("Аналоговый")
                        .modifier(ButtonModifier(isSelected: viewModel.isAnalogArcStyle))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            Text("Отображение времени")
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Вторая строка: Отображение времени
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation {
                        viewModel.showTimeOnlyForActiveTask = false
                        showTimeOnlyForActiveTask = false
                    }
                }) {
                    HStack {
                        Text("Всегда")
                            .font(.caption)
                            .foregroundColor(.white)
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    .modifier(ButtonModifier(isSelected: !viewModel.showTimeOnlyForActiveTask))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation {
                        viewModel.showTimeOnlyForActiveTask = true
                        showTimeOnlyForActiveTask = true
                    }
                }) {
                    HStack {
                        Text("Активная задача")
                            .font(.caption)
                            .foregroundColor(.white)
                        Image(systemName: "clock.badge")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    .modifier(ButtonModifier(isSelected: viewModel.showTimeOnlyForActiveTask))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 8)
            
            // Дополнительная информация
            Text("Аналоговый стиль дуги гармонирует с внешним кольцом. Выбор времени влияет на отображение времени начала и конца задач.")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private var markersControls: some View {
        VStack(spacing: 16) {
            Text("Маркеры")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Первая строка с переключателем отображения маркеров
            HStack(spacing: 10) {
                Button(action: {
                    markersViewModel.showMarkers.toggle()
                    showMarkers = markersViewModel.showMarkers
                }) {
                    HStack {
                        Text(markersViewModel.showMarkers ? "Скрыть маркеры" : "Показать маркеры")
                            .font(.caption)
                            .foregroundColor(.white)
                        Image(systemName: markersViewModel.showMarkers ? "eye.slash" : "eye")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.7),
                                        Color.gray.opacity(0.3),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.0
                            )
                    )
                    .shadow(
                        color: markersViewModel.showMarkers ? Color.yellow.opacity(0.2) : Color.black.opacity(0.5),
                        radius: markersViewModel.showMarkers ? 5 : 3,
                        x: 0,
                        y: markersViewModel.showMarkers ? 0 : 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой")
                .opacity(!markersViewModel.showMarkers && viewModel.clockStyle == "Цифровой" ? 0.5 : 1)
            }
            .padding(.bottom, 8)
            
            // Вторая строка с управлением толщиной
            if markersViewModel.showMarkers {
                HStack(spacing: 10) {
                    // Кнопка уменьшения толщины
                    Button(action: {
                        if markersViewModel.markersWidth > 1.0 {
                            markersViewModel.markersWidth -= 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Тоньше")
                                .font(.caption)
                                .foregroundColor(.white)
                            Image(systemName: "minus")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.7),
                                            Color.gray.opacity(0.3),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.0
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth <= 1.0)
                    .opacity(markersViewModel.markersWidth <= 1.0 ? 0.5 : 1)
                    
                    // Значение толщины
                    Text("\(markersViewModel.markersWidth, specifier: "%.1f")")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .frame(width: 40)
                    
                    // Кнопка увеличения толщины
                    Button(action: {
                        if markersViewModel.markersWidth < 8.0 {
                            markersViewModel.markersWidth += 0.5
                            viewModel.markersWidth = markersViewModel.markersWidth
                        }
                    }) {
                        HStack {
                            Text("Толще")
                                .font(.caption)
                                .foregroundColor(.white)
                            Image(systemName: "plus")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.184, green: 0.184, blue: 0.184))
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.gray.opacity(0.7),
                                            Color.gray.opacity(0.3),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.0
                                )
                        )
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(markersViewModel.markersWidth >= 8.0)
                    .opacity(markersViewModel.markersWidth >= 8.0 ? 0.5 : 1)
                }
                .padding(.bottom, 8)
                
                // Дополнительная информация о маркерах
                Text("Толщина маркеров влияет на визуальное отображение циферблата. Более тонкие маркеры создают минималистичный вид, а более толстые обеспечивают лучшую видимость.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
    }

    private func syncMarkersViewModelWithAppStorage() {
        markersViewModel.showHourNumbers = viewModel.showHourNumbers
        markersViewModel.markersWidth = viewModel.markersWidth
        markersViewModel.markersOffset = viewModel.markersOffset
        markersViewModel.numbersSize = viewModel.numbersSize
        markersViewModel.lightModeMarkersColor = lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = darkModeMarkersColor
        markersViewModel.isDarkMode = themeManager.isDarkMode
        markersViewModel.numberInterval = viewModel.numberInterval
        markersViewModel.showMarkers = showMarkers
        markersViewModel.fontName = fontName
        
        // Добавляем синхронизацию новой настройки
        viewModel.showTimeOnlyForActiveTask = showTimeOnlyForActiveTask

        // Добавляем синхронизацию цветов маркеров с локальными переменными
        markersViewModel.lightModeMarkersColor = lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = darkModeMarkersColor

        // Принудительно обновляем цвета
        markersViewModel.updateCurrentThemeColors()
    }

    private func saveMarkersViewModelToAppStorage() {
        viewModel.showHourNumbers = markersViewModel.showHourNumbers
        viewModel.markersWidth = markersViewModel.markersWidth
        viewModel.markersOffset = markersViewModel.markersOffset
        viewModel.numbersSize = markersViewModel.numbersSize
        viewModel.numberInterval = markersViewModel.numberInterval
        viewModel.lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        viewModel.darkModeMarkersColor = markersViewModel.darkModeMarkersColor
        showMarkers = markersViewModel.showMarkers
        fontName = markersViewModel.fontName
        
        // Сохраняем настройку отображения времени только для активной задачи
        showTimeOnlyForActiveTask = viewModel.showTimeOnlyForActiveTask

        // Сохраняем цвета в локальные AppStorage переменные
        lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        darkModeMarkersColor = markersViewModel.darkModeMarkersColor
    }

    // Вспомогательная функция для получения цвета из градиента по позиции
    private func colorFromGradient(at percentage: Double) -> Color {
        let colors: [Color] = [.red1, .orange, .yellow, .green0, .Mint1, .Blue1, .Indigo1, .Purple1, .pink]
        let count = Double(colors.count - 1)
        let adjustedPercentage = min(max(percentage, 0), 1) // Обеспечиваем, что процент в пределах 0-1
        
        let index = min(Int(adjustedPercentage * count), colors.count - 2)
        let remainder = (adjustedPercentage * count) - Double(index)
        
        return interpolateColor(from: colors[index], to: colors[index + 1], with: remainder)
    }

    // Интерполяция между двумя цветами
    private func interpolateColor(from: Color, to: Color, with percentage: Double) -> Color {
        let fromComponents = UIColor(from).cgColor.components ?? [0, 0, 0, 1]
        let toComponents = UIColor(to).cgColor.components ?? [0, 0, 0, 1]
        
        let r = fromComponents[0] + (toComponents[0] - fromComponents[0]) * CGFloat(percentage)
        let g = fromComponents[1] + (toComponents[1] - fromComponents[1]) * CGFloat(percentage)
        let b = fromComponents[2] + (toComponents[2] - fromComponents[2]) * CGFloat(percentage)
        let a = fromComponents[3] + (toComponents[3] - fromComponents[3]) * CGFloat(percentage)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }

    // Функция для изменения яркости цвета
    private func adjustColorBrightness(_ color: Color, byPercentage percentage: Double) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Коэффициент, чтобы яркость менялась от 0.5 до 1.5 от текущей
        let brightnessAdjustment = 0.5 + percentage
        
        // Ограничиваем компоненты цвета, чтобы они были в диапазоне 0...1
        red = min(max(red * CGFloat(brightnessAdjustment), 0), 1)
        green = min(max(green * CGFloat(brightnessAdjustment), 0), 1)
        blue = min(max(blue * CGFloat(brightnessAdjustment), 0), 1)
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }

    // Получает цвет на определенной позиции слайдера с уменьшенным диапазоном
    private func getColorAt(position: CGFloat, baseColor: Color) -> Color {
        // Уменьшаем диапазон изменения яркости (1.3-0.7)
        // Где 0 на слайдере = яркость 1.3 (умеренно светлый)
        // А 1 на слайдере = яркость 0.7 (умеренно темный)
        let brightnessFactor = 1.3 - (position * 0.6)
        
        if position < 0.5 {
            // Левая сторона, светлее базового цвета
            return brightenColor(baseColor, factor: brightnessFactor)
        } else if position > 0.5 {
            // Правая сторона, темнее базового цвета
            return darkenColor(baseColor, factor: brightnessFactor)
        } else {
            // Центр, базовый цвет
            return baseColor
        }
    }

    // Инициализирует положение слайдера на основе текущей яркости цвета
    private func initializeSliderPosition() {
        let currentColor = Color(
            hex: themeManager.isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        ) ?? .red
        
        let baseColor = getBaseColor(forColor: currentColor)
        let brightness = getBrightness(of: currentColor) / getBrightness(of: baseColor)
        
        // Преобразуем яркость в позицию слайдера (от 0 до 1)
        // Где 0.7 - это минимальная яркость (правый край)
        // 1.3 - максимальная яркость (левый край)
        if brightness <= 0.7 {
            sliderBrightnessPosition = 1.0 // правый край (умеренно темный)
        } else if brightness >= 1.3 {
            sliderBrightnessPosition = 0.0 // левый край (умеренно светлый)
        } else {
            // Мапим яркость от 0.7-1.3 на позицию 1.0-0.0
            sliderBrightnessPosition = 1.0 - ((brightness - 0.7) / 0.6)
        }
    }

    // Получает базовый цвет для цвета
    private func getBaseColor(forColor color: Color) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    // Получает яркость цвета
    private func getBrightness(of color: Color) -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red * 0.299 + green * 0.587 + blue * 0.114)
    }

    // Увеличивает яркость цвета
    private func brightenColor(_ color: Color, factor: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        red = min(max(red * factor, 0), 1)
        green = min(max(green * factor, 0), 1)
        blue = min(max(blue * factor, 0), 1)
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    // Уменьшает яркость цвета
    private func darkenColor(_ color: Color, factor: CGFloat) -> Color {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        red = max(min(red * factor, 1), 0)
        green = max(min(green * factor, 1), 0)
        blue = max(min(blue * factor, 1), 0)
        
        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

