//
//  LibraryClockFaceView.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Кастомный компонент для отображения циферблата в библиотеке
struct LibraryClockFaceView: View {
    let watchFace: WatchFaceModel
    let currentDate: Date = Date()
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @State private var draggedCategory: TaskCategoryModel? = nil
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        ZStack {
            // Фон циферблата
            Circle()
                .fill(clockFaceColor)
                .stroke(Color.gray, lineWidth: 1)
                .frame(width: 275, height: 275)
            
            // Для цифрового стиля добавляем цифровое отображение
            if watchFace.style == "digital" {
                // Извлекаем компоненты времени
                let hour = Calendar.current.component(.hour, from: currentDate)
                let minute = Calendar.current.component(.minute, from: currentDate)
                
                // Отображаем фон для цифр
                Circle()
                    .fill(clockFaceColor)
                    .frame(width: 200, height: 200)
                
                // Цифровое время
                DigitalTimeDisplay(hour: hour, minute: minute, color: markersColor)
            }
            
            // Маркеры часов (если включены)
            if watchFace.showMarkers {
                ForEach(0..<24) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    ClockMarker(
                        hour: hour,
                        style: markerStyle,
                        viewModel: markersViewModel,
                        MarkersColor: markersColor,
                        zeroPosition: watchFace.zeroPosition,
                        showNumbers: false
                    )
                    .rotationEffect(.degrees(angle))
                    .frame(width: 100, height: 100)
                }
            }
            
            // Цифры на часах (если включены)
            if watchFace.showHourNumbers {
                ForEach(0..<24) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    if hour % watchFace.numberInterval == 0 {
                        HourNumberView(
                            hour: hour,
                            viewModel: markersViewModel,
                            color: markersColor,
                            zeroPosition: watchFace.zeroPosition
                        )
                        .rotationEffect(.degrees(angle))
                        .frame(width: 100, height: 100)
                    }
                }
            }
            
            // Стрелка часов
            ClockHandViewIOS(currentDate: currentDate, outerRingLineWidth: watchFace.outerRingLineWidth)
                .rotationEffect(.degrees(watchFace.zeroPosition))
        }
        .onAppear {
           setupViewModels()
        }
    }
    
    // Цифровое отображение времени
    private struct DigitalTimeDisplay: View {
        let hour: Int
        let minute: Int
        let color: Color
        
        var body: some View {
            VStack(spacing: 0) {
                Text("\(hour, specifier: "%02d")")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                Text("\(minute, specifier: "%02d")")
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
        }
    }
    
    // Устанавливаем настройки для ViewModels
    private func setupViewModels() {
        // Настройка markersViewModel
        markersViewModel.showMarkers = watchFace.showMarkers
        markersViewModel.showHourNumbers = watchFace.showHourNumbers
        markersViewModel.numberInterval = watchFace.numberInterval
        markersViewModel.markersOffset = watchFace.markersOffset
        markersViewModel.markersWidth = watchFace.markersWidth
        markersViewModel.numbersSize = watchFace.numbersSize
        markersViewModel.lightModeMarkersColor = watchFace.lightModeMarkersColor
        markersViewModel.darkModeMarkersColor = watchFace.darkModeMarkersColor
        markersViewModel.isDarkMode = themeManager.isDarkMode
        markersViewModel.fontName = watchFace.fontName
        markersViewModel.zeroPosition = watchFace.zeroPosition
        
        // Настройка viewModel
        viewModel.clockStyle = WatchFaceModel.displayStyleName(for: watchFace.style)
        viewModel.zeroPosition = watchFace.zeroPosition
        viewModel.outerRingLineWidth = watchFace.outerRingLineWidth
        viewModel.taskArcLineWidth = watchFace.taskArcLineWidth
        viewModel.isAnalogArcStyle = watchFace.isAnalogArcStyle
        viewModel.showTimeOnlyForActiveTask = watchFace.showTimeOnlyForActiveTask
    }
    
    // Вычисляемые свойства для цветов на основе ThemeManager
    private var clockFaceColor: Color {
        themeManager.isDarkMode 
            ? Color(hex: watchFace.darkModeClockFaceColor) ?? .black
            : Color(hex: watchFace.lightModeClockFaceColor) ?? .white
    }
    
    private var markersColor: Color {
        themeManager.isDarkMode
            ? Color(hex: watchFace.darkModeMarkersColor) ?? .white
            : Color(hex: watchFace.lightModeMarkersColor) ?? .black
    }
    
    private var markerStyle: MarkerStyle {
        switch watchFace.style {
        case "classic": return .standard
        case "minimal": return .lines
        case "digital": return .lines
        case "modern": return .dots
        default: return .standard
        }
    }
} 
