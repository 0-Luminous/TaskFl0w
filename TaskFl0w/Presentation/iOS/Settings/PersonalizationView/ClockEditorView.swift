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
            // Внешнее кольцо
            ColorPicker(
                "Внешнее кольцо",
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
            // Цвет циферблата
            ColorPicker(
                "Циферблат",
                selection: Binding(
                    get: {
                        Color(
                            hex: themeManager.isDarkMode
                                ? darkModeClockFaceColor : lightModeClockFaceColor)
                            ?? (themeManager.isDarkMode ? .black : .white)
                    },
                    set: { newColor in
                        if themeManager.isDarkMode {
                            darkModeClockFaceColor = newColor.toHex()
                        } else {
                            lightModeClockFaceColor = newColor.toHex()
                        }
                    }
                )
            )
            .foregroundColor(.white)
            // Цвет маркеров
            ColorPicker(
                "Маркеры",
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.98))
                .shadow(radius: 8)
        )
        .padding(.horizontal, 24)
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
            Toggle("Аналоговый вид дуги", isOn: $viewModel.isAnalogArcStyle)
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .foregroundColor(.white)
                
            Divider().background(Color.white.opacity(0.2))
            
            // Первая опция для показа времени вообще
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Показывать время")
                        .foregroundColor(.white)
                    Text("Отображение времени начала и конца задач")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { !viewModel.showTimeOnlyForActiveTask },
                    set: { 
                        viewModel.showTimeOnlyForActiveTask = !$0
                        showTimeOnlyForActiveTask = !$0
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .labelsHidden()
            }
            
            // Вторая опция для показа времени только активной задачи
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Только у активной задачи")
                        .foregroundColor(.white)
                    Text("Время будет отображаться только у выбранной задачи")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { viewModel.showTimeOnlyForActiveTask },
                    set: { 
                        viewModel.showTimeOnlyForActiveTask = $0
                        showTimeOnlyForActiveTask = $0
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .yellow))
                .labelsHidden()
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
}

