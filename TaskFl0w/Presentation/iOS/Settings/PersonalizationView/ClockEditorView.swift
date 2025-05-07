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
    @AppStorage("clockStyle") private var clockStyle: String = "Классический"

    @Environment(\.presentationMode) var presentationMode
    @State private var showClockControls = false
    @State private var showColorControls = false
    @State private var showOuterRingWidthControls = false
    @State private var showArcAnalogToggle = false
    @State private var showMarkersControls = false
    @State private var showFontPicker = false

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

    private var dockBar: some View {
        HStack(spacing: 20) {
            Button(action: {
                // Открыть clockControls, закрыть остальные
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
                    .font(.system(size: 20))
                    .foregroundColor(showClockControls ? .yellow : .white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

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
                    .font(.system(size: 20))
                    .foregroundColor(showMarkersControls ? .yellow : .white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

            Button(action: {
                // Открыть colorControls, закрыть остальные
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
                    .font(.system(size: 20))
                    .foregroundColor(showColorControls ? .yellow : .white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

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
                    .font(.system(size: 20))
                    .foregroundColor(showOuterRingWidthControls ? .yellow : .white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

            Button(action: {
                // Действие 4
            }) {
                Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)

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
                    .font(.system(size: 20))
                    .foregroundColor(showArcAnalogToggle ? .yellow : .white)
                    .padding(6)
            }
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
            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
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
            } else {
                // Показываем переключатель "Показывать цифры" только для стиля "Минимализм"
                if clockStyle == "Минимализм" {
                    Toggle(
                        "Показывать цифры",
                        isOn: Binding(
                            get: { markersViewModel.showHourNumbers },
                            set: {
                                markersViewModel.showHourNumbers = $0
                                viewModel.showHourNumbers = $0
                            }
                        )
                    )
                    .toggleStyle(SwitchToggleStyle(tint: .yellow))
                    .foregroundColor(.white)
                    
                    Stepper(
                        "Размер цифр: \(markersViewModel.numbersSize, specifier: "%.0f")",
                        value: Binding(
                            get: { markersViewModel.numbersSize },
                            set: {
                                markersViewModel.numbersSize = $0
                                viewModel.numbersSize = $0
                            }
                        ), in: 14...21, step: 1
                    )
                    .foregroundColor(.white)
                    
                    // Добавляем кнопку "Изменить шрифт цифр" для стиля "Минимализм"
                    Button(action: {
                        withAnimation {
                            showFontPicker = true
                        }
                    }) {
                        HStack {
                            Text("Изменить шрифт цифр")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Отображаем кнопку "Изменить шрифт цифр" только для стиля "Классический"
                if clockStyle == "Классический" {
                    Stepper(
                        "Размер цифр: \(markersViewModel.numbersSize, specifier: "%.0f")",
                        value: Binding(
                            get: { markersViewModel.numbersSize },
                            set: {
                                markersViewModel.numbersSize = $0
                                viewModel.numbersSize = $0
                            }
                        ), in: 14...21, step: 1
                    )
                    .foregroundColor(.white)
                    
                    Button(action: {
                        withAnimation {
                            showFontPicker = true
                        }
                    }) {
                        HStack {
                            Text("Изменить шрифт цифр")
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }

                Text("Стиль")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button(action: {
                            clockStyle = "Классический"
                        }) {
                            Text("Классический")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .foregroundColor(clockStyle == "Классический" ? .yellow : .white)
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
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            clockStyle = "Контур"
                        }) {
                            Text("Контур")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .foregroundColor(clockStyle == "Контур" ? .yellow : .white)
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
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    HStack(spacing: 10) {
                        Button(action: {
                            clockStyle = "Цифровой"
                        }) {
                            Text("Цифровой")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .foregroundColor(clockStyle == "Цифровой" ? .yellow : .white)
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
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            clockStyle = "Минимализм"
                        }) {
                            Text("Минимализм")
                                .font(.caption)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .foregroundColor(clockStyle == "Минимализм" ? .yellow : .white)
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
                                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
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
            Toggle(
                "Показывать маркеры",
                isOn: Binding(
                    get: { markersViewModel.showMarkers },
                    set: {
                        markersViewModel.showMarkers = $0
                        showMarkers = $0
                    }
                )
            )
            .toggleStyle(SwitchToggleStyle(tint: .yellow))
            .foregroundColor(.white)
            Stepper(
                "Толщина маркеров: \(markersViewModel.markersWidth, specifier: "%.1f")",
                value: Binding(
                    get: { markersViewModel.markersWidth },
                    set: {
                        markersViewModel.markersWidth = $0
                        viewModel.markersWidth = $0
                    }
                ), in: 1...8, step: 0.5
            )
            .foregroundColor(.white)
            .disabled(!markersViewModel.showMarkers)
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

        // Сохраняем цвета в локальные AppStorage переменные
        lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        darkModeMarkersColor = markersViewModel.darkModeMarkersColor
    }
}
