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
    @StateObject private var themeConfigurationViewModel = ThemeConfigurationViewModel()
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
    @AppStorage("lightModeHandColor") private var lightModeHandColor: String = Color.blue.toHex()
    @AppStorage("darkModeHandColor") private var darkModeHandColor: String = Color.blue.toHex()
    // Добавляем новые @AppStorage свойства для цвета цифр цифрового стиля
    @AppStorage("lightModeDigitalFontColor") private var lightModeDigitalFontColor: String = Color.gray.toHex()
    @AppStorage("darkModeDigitalFontColor") private var darkModeDigitalFontColor: String = Color.white.toHex()

    @AppStorage("showMarkers") private var showMarkers: Bool = true
    @AppStorage("fontName") private var fontName: String = "Nunito"
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
    @State private var currentBaseColor: Color = .white
    @State private var selectedColorType: String = "clockFace"
    @State private var selectedColorHex: String = ""
    @State private var selectedColorIndex: Int? = nil

    @State private var watchFace: WatchFaceModel
    @State private var showZeroPositionControls = false
    @State private var showHandColorSettings = false

    init(viewModel: ClockViewModel, markersViewModel: ClockMarkersViewModel, taskArcLineWidth: CGFloat) {
        self.viewModel = viewModel
        self.markersViewModel = markersViewModel
        self.taskArcLineWidth = taskArcLineWidth
        
        _watchFace = State(initialValue: WatchFaceModel(
            name: "Текущий",
            style: "classic",
            lightModeClockFaceColor: Color.white.toHex(),
            darkModeClockFaceColor: Color.black.toHex(),
            lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
            darkModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
            lightModeMarkersColor: Color.black.toHex(),
            darkModeMarkersColor: Color.white.toHex(),
            lightModeHandColor: Color.blue.toHex(),
            darkModeHandColor: Color.blue.toHex()
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    clockPreviewSection
                        .padding(
                            .bottom,
                            {
                                if showClockControls {
                                    return 300  // Больше места для настроек циферблата
                                } else if showColorControls {
                                    return 300  // Еще больше места для палитры цветов
                                } else if showOuterRingWidthControls {
                                    return 400  // Меньше места для настроек ширины кольца
                                } else if showArcAnalogToggle {
                                    return 300  // Минимальное поднятие для переключения стиля
                                } else if showMarkersControls {
                                    return 300  // Среднее поднятие для настроек маркеров
                                } else if showZeroPositionControls {
                                    return 300  // Среднее поднятие для настроек нуля
                                }
                                return 0
                            }()
                        )
                        .animation(.spring(), value: showClockControls)
                        .animation(.spring(), value: showColorControls)
                        .animation(.spring(), value: showOuterRingWidthControls)
                        .animation(.spring(), value: showArcAnalogToggle)
                        .animation(.spring(), value: showMarkersControls)
                        .animation(.spring(), value: showZeroPositionControls)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.98, green: 0.98, blue: 0.98))
                .ignoresSafeArea()

                VStack(spacing: 0) {
                   if showClockControls {
                       ClockControlsView(
                           viewModel: viewModel,
                           markersViewModel: markersViewModel,
                           showFontPicker: $showFontPicker,
                           showSizeSettings: $showSizeSettings,
                           showIntervalSettings: $showIntervalSettings,
                           fontName: $fontName
                       )
                       .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                       .padding(.bottom, 8)
                   }
                    if showColorControls {
                        ColorControlsView(
                            viewModel: themeConfigurationViewModel,
                            markersViewModel: markersViewModel,
                            themeManager: themeManager,
                            lightModeOuterRingColor: $lightModeOuterRingColor,
                            darkModeOuterRingColor: $darkModeOuterRingColor,
                            lightModeClockFaceColor: $lightModeClockFaceColor,
                            darkModeClockFaceColor: $darkModeClockFaceColor,
                            lightModeMarkersColor: $lightModeMarkersColor,
                            darkModeMarkersColor: $darkModeMarkersColor,
                            lightModeHandColor: $lightModeHandColor,
                            darkModeHandColor: $darkModeHandColor,
                            showColorPickerSheet: $showColorPickerSheet,
                            colorPickerType: $colorPickerType,
                            sliderBrightnessPosition: $sliderBrightnessPosition,
                            currentBaseColor: $currentBaseColor,
                            selectedColorType: $selectedColorType,
                            selectedColorHex: $selectedColorHex,
                            selectedColorIndex: $selectedColorIndex,
                            lightModeDigitalFontColor: $lightModeDigitalFontColor,
                            darkModeDigitalFontColor: $darkModeDigitalFontColor
                        )
                        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    if showOuterRingWidthControls {
                        RingWidthControlsView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 8)
                    }
                    if showArcAnalogToggle {
                        ArcStyleControlsView(
                            viewModel: viewModel,
                            showTimeOnlyForActiveTask: $showTimeOnlyForActiveTask
                        )
                        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    if showMarkersControls {
                        MarkersControlsView(
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            showMarkers: $showMarkers
                        )
                        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    // Временно закомментируем ZeroPositionControlView, так как он не работает
                    // if showZeroPositionControls {
                    //     ZeroPositionControlView(viewModel: viewModel)
                    //         .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                    //         .padding(.bottom, 8)
                    // }
                    
                    DockBarView(
                        showClockControls: $showClockControls,
                        showColorControls: $showColorControls,
                        showOuterRingWidthControls: $showOuterRingWidthControls,
                        showArcAnalogToggle: $showArcAnalogToggle,
                        showMarkersControls: $showMarkersControls,
                        showZeroPositionControls: $showZeroPositionControls
                    )
                }
                .animation(.spring(), value: showClockControls)
                .animation(.spring(), value: showColorControls)
                .animation(.spring(), value: showZeroPositionControls)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.red1)
                        Text("Назад")
                            .foregroundColor(.red1)
                    }
                }
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
                .stroke(currentOuterRingColor, lineWidth: viewModel.themeConfig.outerRingLineWidth)
                .frame(
                    width: UIScreen.main.bounds.width * 0.8,
                    height: UIScreen.main.bounds.width * 0.8
                )

            // Сам циферблат
            ClockFaceView(
                currentDate: viewModel.selectedDate,
                tasks: viewModel.tasks,
                viewModel: viewModel,
                markersViewModel: viewModel.markersViewModel,
                draggedCategory: Binding.constant(nil as TaskCategoryModel?),
                zeroPosition: viewModel.timeManager.zeroPosition,
                taskArcLineWidth: viewModel.themeConfig.isAnalogArcStyle
                    ? viewModel.themeConfig.outerRingLineWidth : viewModel.themeConfig.taskArcLineWidth,
                outerRingLineWidth: viewModel.themeConfig.outerRingLineWidth
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

    private func syncMarkersViewModelWithAppStorage() {
        markersViewModel.showHourNumbers = viewModel.themeConfig.showHourNumbers
        markersViewModel.markersWidth = viewModel.themeConfig.markersWidth
        markersViewModel.markersOffset = viewModel.themeConfig.markersOffset
        markersViewModel.numbersSize = viewModel.themeConfig.numbersSize
        markersViewModel.lightModeMarkersColor = lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = darkModeMarkersColor
        markersViewModel.isDarkMode = themeManager.isDarkMode
        markersViewModel.numberInterval = viewModel.themeConfig.numberInterval
        markersViewModel.showMarkers = showMarkers
        markersViewModel.fontName = fontName
        
        // Добавляем синхронизацию новых параметров
        markersViewModel.lightModeDigitalFontColor = lightModeDigitalFontColor
        markersViewModel.darkModeDigitalFontColor = darkModeDigitalFontColor
        
        // Обновляем свойства ViewModel
        viewModel.themeConfig.lightModeDigitalFontColor = lightModeDigitalFontColor
        viewModel.themeConfig.darkModeDigitalFontColor = darkModeDigitalFontColor
        
        // Добавляем синхронизацию настройки
        viewModel.themeConfig.showTimeOnlyForActiveTask = showTimeOnlyForActiveTask

        // Принудительно обновляем цвета
        markersViewModel.updateCurrentThemeColors()

        // Обновляем watchFace при синхронизации
        watchFace = WatchFaceModel(
            name: "Текущий",
            style: viewModel.themeConfig.clockStyle == "Классический" ? "classic" : 
                  viewModel.themeConfig.clockStyle == "Минимализм" ? "minimal" :
                  viewModel.themeConfig.clockStyle == "Цифровой" ? "digital" : "modern",
            lightModeClockFaceColor: lightModeClockFaceColor,
            darkModeClockFaceColor: darkModeClockFaceColor,
            lightModeOuterRingColor: lightModeOuterRingColor,
            darkModeOuterRingColor: darkModeOuterRingColor,
            lightModeMarkersColor: lightModeMarkersColor,
            darkModeMarkersColor: darkModeMarkersColor,
            showMarkers: showMarkers,
            showHourNumbers: markersViewModel.showHourNumbers,
            numberInterval: markersViewModel.numberInterval,
            markersOffset: markersViewModel.markersOffset,
            markersWidth: markersViewModel.markersWidth,
            numbersSize: markersViewModel.numbersSize,
            zeroPosition: viewModel.timeManager.zeroPosition,
            outerRingLineWidth: viewModel.themeConfig.outerRingLineWidth,
            taskArcLineWidth: viewModel.themeConfig.taskArcLineWidth,
            isAnalogArcStyle: viewModel.themeConfig.isAnalogArcStyle,
            showTimeOnlyForActiveTask: showTimeOnlyForActiveTask,
            fontName: fontName,
            lightModeHandColor: lightModeHandColor,
            darkModeHandColor: darkModeHandColor
        )

        // Добавляем синхронизацию цвета стрелки
        if viewModel.themeConfig.lightModeHandColor != lightModeHandColor {
            viewModel.themeConfig.lightModeHandColor = lightModeHandColor
        }
        if viewModel.themeConfig.darkModeHandColor != darkModeHandColor {
            viewModel.themeConfig.darkModeHandColor = darkModeHandColor
        }
    }

    private func saveMarkersViewModelToAppStorage() {
        viewModel.themeConfig.showHourNumbers = markersViewModel.showHourNumbers
        viewModel.themeConfig.markersWidth = markersViewModel.markersWidth
        viewModel.themeConfig.markersOffset = markersViewModel.markersOffset
        viewModel.themeConfig.numbersSize = markersViewModel.numbersSize
        viewModel.themeConfig.numberInterval = markersViewModel.numberInterval
        viewModel.themeConfig.lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        viewModel.themeConfig.darkModeMarkersColor = markersViewModel.darkModeMarkersColor
        showMarkers = markersViewModel.showMarkers
        fontName = markersViewModel.fontName
        
        // Сохраняем новые настройки
        lightModeDigitalFontColor = markersViewModel.lightModeDigitalFontColor
        darkModeDigitalFontColor = markersViewModel.darkModeDigitalFontColor
        viewModel.themeConfig.lightModeDigitalFontColor = markersViewModel.lightModeDigitalFontColor
        viewModel.themeConfig.darkModeDigitalFontColor = markersViewModel.darkModeDigitalFontColor
        
        // Сохраняем настройку отображения времени только для активной задачи
        showTimeOnlyForActiveTask = viewModel.themeConfig.showTimeOnlyForActiveTask

        // Сохраняем цвета в локальные AppStorage переменные
        lightModeMarkersColor = markersViewModel.lightModeMarkersColor
        darkModeMarkersColor = markersViewModel.darkModeMarkersColor
    }

    private func resetZeroPosition() {
        // Сбрасываем позицию нуля на 0
        viewModel.updateZeroPosition(0)
        
        // Обновляем данные в watchFace
        watchFace.zeroPosition = 0
        
        // Обновляем UI
        viewModel.objectWillChange.send()
    }
}

