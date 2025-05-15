//
//  FirstView.swift
//  TaskFl0w
//
//  Created by Yan on 11/5/25.
//

import SwiftUI

struct FirstView: View {
    @State private var isAnimating = false
    @State private var showButton = false
    @State private var selectedWatchFace: WatchFaceModel?
    @State private var navigateToLibrary = false
    @State private var navigateToSelectCategory = false
    
    // Массив предустановленных циферблатов
    private let watchFaces = WatchFaceModel.defaultWatchFaces
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Фон
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // Удаляем Spacer() отсюда
                    
                    // Кнопка выбора циферблата размещается внизу экрана
                    Spacer()
                    
                    if showButton {
                        Button(action: {
                            navigateToSelectCategory = true
                        }) {
                            Text("Выбрать стартовые категории")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(radius: 5)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(10) // Чтобы кнопка была поверх циферблатов
                    }
                    
                    Spacer().frame(height: 20)
                }
                
                // Анимированные дуги категорий (вынесены из VStack)
                ZStack {
                    ForEach(0..<5, id: \.self) { i in
                        CategoryArcView(
                            radius: CGFloat.random(in: 80...180),
                            thickness: CGFloat.random(in: 8...18),
                            startAngle: .degrees(Double.random(in: 0...180)),
                            endAngle: .degrees(Double.random(in: 200...360)),
                            color: [Color.pink, Color.blue, Color.purple, Color.green, Color.orange][i % 5],
                            animationDuration: Double.random(in: 3.5...6.5),
                            maxOffset: 120
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Анимированные циферблаты (вынесены из VStack)
                ZStack {
                    ForEach(Array(watchFaces.enumerated()), id: \.1.id) { (idx, face) in
                        AnimatedFlyingWatchFaceView(
                            watchFace: face,
                            index: idx,
                            isAnimating: isAnimating
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $navigateToLibrary) {
                LibraryOfWatchFaces()
            }
            .navigationDestination(isPresented: $navigateToSelectCategory) {
                SelectCategory()
            }
            .onAppear {
                // Запускаем анимацию при появлении
                withAnimation {
                    isAnimating = true
                }
                
                // Показываем кнопку с задержкой
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        showButton = true
                    }
                }
            }
        }
    }
}

struct CategoryArcView: View {
    @State private var animating = false
    let radius: CGFloat
    let thickness: CGFloat
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let animationDuration: Double
    let maxOffset: CGFloat
    
    var body: some View {
        ArcShape(startAngle: startAngle, endAngle: endAngle)
            .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(animating ? .degrees(Double.random(in: 0...360)) : .zero)
            .offset(x: animating ? CGFloat.random(in: -maxOffset...maxOffset) : 0,
                    y: animating ? CGFloat.random(in: -maxOffset...maxOffset) : 0)
            .blur(radius: 2)
            .shadow(color: color.opacity(0.4), radius: 8)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                    animating = true
                }
            }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        path.addArc(center: center, radius: radius, startAngle: startAngle - .degrees(90), endAngle: endAngle - .degrees(90), clockwise: false)
        return path
    }
}

struct AnimatedFlyingWatchFaceView: View {
    let watchFace: WatchFaceModel
    let index: Int
    let isAnimating: Bool
    @State private var randomOffset: CGSize = .zero
    @State private var randomRotation: Double = 0
    @State private var randomScale: CGFloat = 0.3
    @State private var handScale: CGFloat = 0.75  // Отдельный масштаб для стрелки

    func randomize() {
        randomOffset = CGSize(width: CGFloat.random(in: -180...180), height: CGFloat.random(in: -300...300))
        randomRotation = Double.random(in: -60...60)
        randomScale = CGFloat.random(in: 0.2...0.4)
        // handScale = CGFloat.random(in: 0.2...0.4)  // Случайные значения для стрелки
    }

    func animateForever() {
        guard isAnimating else { return }
        let duration = Double.random(in: 7.0...12.0)
        withAnimation(Animation.easeInOut(duration: duration)) {
            randomize()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            animateForever()
        }
    }

    var body: some View {
        ZStack {
            ModifiedLibraryClockFaceView(
                watchFace: watchFace, 
                scale: randomScale,
                handScale: handScale  // Передаем отдельный масштаб для стрелки
            )
            RingPlanner(
                color: .white.opacity(0.25),
                viewModel: ClockViewModel(),
                zeroPosition: 0,
                shouldDeleteTask: false,
                outerRingLineWidth: 20
            )
        }
        .scaleEffect(randomScale)
        .rotationEffect(.degrees(randomRotation))
        .offset(randomOffset)
        .onAppear {
            randomize()
            if isAnimating {
                animateForever()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                animateForever()
            }
        }
    }
}

// Обновленная версия LibraryClockFaceView с отдельным масштабом для стрелки
struct ModifiedLibraryClockFaceView: View {
    let watchFace: WatchFaceModel
    let scale: CGFloat
    let handScale: CGFloat  // Новый параметр для масштаба стрелки
    let currentDate: Date = Date()
    @StateObject private var viewModel = ClockViewModel()
    @StateObject private var markersViewModel = ClockMarkersViewModel()
    @State private var draggedCategory: TaskCategoryModel? = nil
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Для обратной совместимости с существующими вызовами
    init(watchFace: WatchFaceModel, scale: CGFloat, handScale: CGFloat? = nil) {
        self.watchFace = watchFace
        self.scale = scale
        self.handScale = handScale ?? scale * 2.0  // По умолчанию стрелка в 2 раза длиннее масштаба циферблата
    }
    
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
                
                // Цифровое время с использованием настроек шрифта
                DigitalTimeDisplay(
                    hour: hour,
                    minute: minute,
                    color: digitalFontColor,
                    fontName: watchFace.digitalFont,
                    fontSize: watchFace.digitalFontSize
                )
            }
            
            // Маркеры часов (если включены)
            if watchFace.showMarkers {
                // Основные часовые маркеры
                ForEach(0..<24) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    ClockMarker(
                        hour: hour,
                        style: markerStyle,
                        viewModel: markersViewModel,
                        MarkersColor: markersColor,
                        zeroPosition: watchFace.zeroPosition,
                        showNumbers: false,
                        isMainMarker: true
                    )
                    .rotationEffect(.degrees(angle))
                    .frame(width: 100, height: 100)
                    .id("marker-hour-\(hour)-\(watchFace.markerStyle)-\(Int(watchFace.markersWidth * 10))")
                }
                
                // Промежуточные маркеры
                if watchFace.showIntermediateMarkers {
                    ForEach(0..<96) { minuteMarker in
                        let angle = Double(minuteMarker) * (360.0 / 96.0)
                        // Пропускаем позиции, где уже есть часовые маркеры
                        if minuteMarker % 4 != 0 {
                            ClockMarker(
                                hour: minuteMarker / 4,
                                minuteIndex: minuteMarker % 4,
                                style: markerStyle,
                                viewModel: markersViewModel,
                                MarkersColor: markersColor,
                                zeroPosition: watchFace.zeroPosition,
                                showNumbers: false,
                                isMainMarker: false
                            )
                            .rotationEffect(.degrees(angle))
                            .frame(width: 100, height: 100)
                            .id("marker-minute-\(minuteMarker)-\(watchFace.markerStyle)")
                        }
                    }
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
            
            // Стрелка часов с отдельным масштабом
            ClockHandViewIOS(
                currentDate: currentDate, 
                outerRingLineWidth: watchFace.outerRingLineWidth,
                lightModeCustomHandColor: watchFace.lightModeHandColor,
                darkModeCustomHandColor: watchFace.darkModeHandColor,
                scale: handScale  // Используем отдельный масштаб для стрелки
            )
            .rotationEffect(.degrees(watchFace.zeroPosition))
        }
        .onAppear {
           setupViewModels()
        }
    }
    
    // Остальные методы и свойства такие же, как в оригинальном LibraryClockFaceView
    // ...
    
    // Цифровое отображение времени
    private struct DigitalTimeDisplay: View {
        let hour: Int
        let minute: Int
        let color: Color
        let fontName: String
        let fontSize: Double
        
        init(hour: Int, minute: Int, color: Color, fontName: String = "SF Pro", fontSize: Double = 40.0) {
            self.hour = hour
            self.minute = minute
            self.color = color
            self.fontName = fontName
            self.fontSize = fontSize
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Text("\(hour, specifier: "%02d")")
                    .font(customFont)
                    .foregroundColor(color)
                
                Text("\(minute, specifier: "%02d")")
                    .font(customFont)
                    .foregroundColor(color)
            }
        }
        
        // Создаем шрифт на основе переданных параметров
        private var customFont: Font {
            if fontName != "SF Pro" {
                return Font.custom(fontName, size: fontSize)
            } else {
                return .system(size: fontSize, weight: .bold, design: .monospaced)
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
        markersViewModel.markerStyle = watchFace.markerStyleEnum
        markersViewModel.showIntermediateMarkers = watchFace.showIntermediateMarkers
        markersViewModel.digitalFont = watchFace.digitalFont
        markersViewModel.digitalFontSize = watchFace.digitalFontSize
        markersViewModel.lightModeDigitalFontColor = watchFace.lightModeDigitalFontColor
        markersViewModel.darkModeDigitalFontColor = watchFace.darkModeDigitalFontColor
        
        // Настройка viewModel
        viewModel.clockStyle = WatchFaceModel.displayStyleName(for: watchFace.style)
        viewModel.zeroPosition = watchFace.zeroPosition
        viewModel.outerRingLineWidth = watchFace.outerRingLineWidth
        viewModel.taskArcLineWidth = watchFace.taskArcLineWidth
        viewModel.isAnalogArcStyle = watchFace.isAnalogArcStyle
        viewModel.showTimeOnlyForActiveTask = watchFace.showTimeOnlyForActiveTask
        viewModel.lightModeHandColor = watchFace.lightModeHandColor  
        viewModel.darkModeHandColor = watchFace.darkModeHandColor
        
        // Добавляем эти строки в SetupViewModels()
        if watchFace.style == "digital" {
            UserDefaults.standard.set(watchFace.digitalFont, forKey: "digitalFont")  
            UserDefaults.standard.set(watchFace.digitalFontSize, forKey: "digitalFontSize")
        }
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
    
    // Получаем стиль маркеров из модели циферблата
    private var markerStyle: MarkerStyle {
        watchFace.markerStyleEnum
    }
    
    // Добавьте новое вычисляемое свойство для цвета цифрового шрифта
    private var digitalFontColor: Color {
        themeManager.isDarkMode
            ? Color(hex: watchFace.darkModeDigitalFontColor) ?? .white
            : Color(hex: watchFace.lightModeDigitalFontColor) ?? .black
    }
}


