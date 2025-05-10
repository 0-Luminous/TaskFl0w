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
    @State private var currentBaseColor: Color = .white
    @State private var selectedColorType: String = ""
    @State private var selectedColorHex: String = ""
    @State private var selectedColorIndex: Int? = nil

    @State private var watchFace: WatchFaceModel

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
            darkModeMarkersColor: Color.white.toHex()
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
                                }
                                return 0
                            }()
                        )
                        .animation(.spring(), value: showClockControls)
                        .animation(.spring(), value: showColorControls)
                        .animation(.spring(), value: showOuterRingWidthControls)
                        .animation(.spring(), value: showArcAnalogToggle)
                        .animation(.spring(), value: showMarkersControls)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.isDarkMode ? Color(red: 0.098, green: 0.098, blue: 0.098) : Color(red: 0.98, green: 0.98, blue: 0.98))
                .ignoresSafeArea()
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    if showColorControls {
                        ColorControlsView(
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            themeManager: themeManager,
                            lightModeOuterRingColor: $lightModeOuterRingColor,
                            darkModeOuterRingColor: $darkModeOuterRingColor,
                            lightModeClockFaceColor: $lightModeClockFaceColor,
                            darkModeClockFaceColor: $darkModeClockFaceColor,
                            lightModeMarkersColor: $lightModeMarkersColor,
                            darkModeMarkersColor: $darkModeMarkersColor,
                            showColorPickerSheet: $showColorPickerSheet,
                            colorPickerType: $colorPickerType,
                            sliderBrightnessPosition: $sliderBrightnessPosition,
                            currentBaseColor: $currentBaseColor, 
                            selectedColorType: $selectedColorType,
                            selectedColorHex: $selectedColorHex,
                            selectedColorIndex: $selectedColorIndex
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    if showMarkersControls {
                        MarkersControlsView(
                            viewModel: viewModel,
                            markersViewModel: markersViewModel,
                            showMarkers: $showMarkers
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                    }
                    
                    DockBarView(
                        showClockControls: $showClockControls,
                        showColorControls: $showColorControls,
                        showOuterRingWidthControls: $showOuterRingWidthControls,
                        showArcAnalogToggle: $showArcAnalogToggle,
                        showMarkersControls: $showMarkersControls
                    )
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
                draggedCategory: Binding.constant(nil as TaskCategoryModel?),
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

        // Принудительно обновляем цвета
        markersViewModel.updateCurrentThemeColors()

        // Обновляем watchFace при синхронизации
        watchFace = WatchFaceModel(
            name: "Текущий",
            style: viewModel.clockStyle == "Классический" ? "classic" : 
                  viewModel.clockStyle == "Минимализм" ? "minimal" :
                  viewModel.clockStyle == "Цифровой" ? "digital" : "modern",
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
            zeroPosition: viewModel.zeroPosition,
            outerRingLineWidth: viewModel.outerRingLineWidth,
            taskArcLineWidth: viewModel.taskArcLineWidth,
            isAnalogArcStyle: viewModel.isAnalogArcStyle,
            showTimeOnlyForActiveTask: showTimeOnlyForActiveTask,
            fontName: fontName
        )
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

