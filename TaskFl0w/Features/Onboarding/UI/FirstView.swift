//
//  FirstView.swift
//  TaskFl0w
//
//  Created by Yan on 11/5/25.
//

import SwiftUI
import CoreGraphics

struct FirstView: View {
    @State private var navigateToLibrary = false
    @State private var navigateToSelectWatch = false
    @State private var showWelcomeScreen = true
    @State private var showMainClock = false
    @State private var showWelcomeText = false
    @State private var showButton = false
    
    // Создаем изолированный demo ViewModel для демонстрации только в FirstView
    @StateObject private var demoViewModel = DemoClockViewModel()
    @ObservedObject private var themeManager = ThemeManager.shared
    
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

                VStack(spacing: 0) {
                    // Отступ сверху
                    Spacer()
                        .frame(height: 80)
                    
                    // Главный циферблат с задачами
                    if showMainClock {
                        ZStack {
                            let mainWatchFace = watchFaces.first { $0.category == WatchFaceCategory.minimal.rawValue } ?? WatchFaceModel.defaultWatchFaces[0]
                            
                            // Анимированное кольцо планировщика с задачами
                            AnimatedRingPlanner(
                                color: .white.opacity(0.25),
                                viewModel: demoViewModel,
                                zeroPosition: mainWatchFace.zeroPosition,
                                shouldDeleteTask: false,
                                outerRingLineWidth: 20
                            )
                            .frame(width: 350, height: 350)

                            // Циферблат
                            ModifiedLibraryClockFaceView(
                                watchFace: mainWatchFace,
                                scale: 1.0,
                                handScale: 0.92
                            )
                            .frame(width: 300, height: 300)
    
                        }
                        .scaleEffect(showMainClock ? 1.0 : 0.1)
                        .opacity(showMainClock ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showMainClock)
                    }
                    
                    // Промежуточный отступ
                    Spacer()
                        .frame(height: 40)
                    
                    // Приветственный текст
                    if showWelcomeText {
                        VStack(spacing: 16) {
                            Text("firstView.welcome".localized())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.8), .purple.opacity(0.9)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .multilineTextAlignment(.center)
                            
                            Text("firstView.welcomeDescription".localized())
                                .font(.headline)
                                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.9) : .black.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Кнопка продолжения
                    if showButton {
                        Button(action: {
                            navigateToSelectWatch = true
                        }) {
                            Text("firstView.start".localized())
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hue: 0.7, saturation: 0.7, brightness: 0.7), Color(hue: 0.9, saturation: 0.9, brightness: 0.9)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(radius: 10)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 30)
                    }

                    // Отступ снизу
                    Spacer()
                        .frame(height: 80)
                }
            }
            .navigationDestination(isPresented: $navigateToLibrary) {
                LibraryOfWatchFaces()
            }
            .navigationDestination(isPresented: $navigateToSelectWatch) {
                SelectWatch()
            }
            .onAppear {
                // Проверяем, нужно ли показывать демо
                if !UserDefaults.standard.bool(forKey: "isAppSetupCompleted") {
                    setupDemoTasks()
                    startAnimationSequence()
                } else {
                    // Если настройка завершена, сразу переходим дальше
                    navigateToSelectWatch = true
                }
            }
            .onDisappear {
                // Очищаем демонстрационные задачи при уходе с FirstView
                demoViewModel.clearAllTasks()
                
                // Освобождаем память от анимаций
                showMainClock = false
                showWelcomeText = false
                showButton = false
                
                // Останавливаем все таймеры анимаций
                cancelAllAnimations()
            }
        }
    }
    
    // Настройка демонстрационных задач
    private func setupDemoTasks() {
        // Очищаем существующие задачи перед добавлением новых
        demoViewModel.clearAllTasks()
        
        // Создаем демонстрационные категории
        let workCategory = TaskCategoryModel(
            id: UUID(),
            rawValue: "selectCategory.work".localized(),
            iconName: "briefcase.fill",
            color: .blue
        )
        
        let breakCategory = TaskCategoryModel(
            id: UUID(),
            rawValue: "selectCategory.break".localized(),
            iconName: "cup.and.saucer.fill",
            color: .green
        )
        
        let studyCategory = TaskCategoryModel(
            id: UUID(),
            rawValue: "selectCategory.education".localized(),
            iconName: "book.fill",
            color: .purple
        )
        
        // Создаем демонстрационные задачи
        let calendar = Calendar.current
        let now = Date()
        
        // Задача работы (4:00 - 11:00)
        let workStart = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: now) ?? now
        let workEnd = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: now) ?? now
        let workTask = TaskOnRing(
            id: UUID(),
            startTime: workStart,
            endTime: workEnd,
            color: workCategory.color,
            icon: workCategory.iconName,
            category: workCategory,
            isCompleted: false
        )
        
        // Задача перерыва (13:00 - 18:00)
        let breakStart = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let breakEnd = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now) ?? now
        let breakTask = TaskOnRing(
            id: UUID(),
            startTime: breakStart,
            endTime: breakEnd,
            color: breakCategory.color,
            icon: breakCategory.iconName,
            category: breakCategory,
            isCompleted: false
        )
        
        // Задача учёбы (19:00 - 23:00)
        let studyStart = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: now) ?? now
        let studyEnd = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: now) ?? now
        let studyTask = TaskOnRing(
            id: UUID(),
            startTime: studyStart,
            endTime: studyEnd,
            color: studyCategory.color,
            icon: studyCategory.iconName,
            category: studyCategory,
            isCompleted: false
        )
        
        // Добавляем задачи в изолированный demoViewModel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            demoViewModel.taskManagement?.addTask(workTask)
            demoViewModel.taskManagement?.addTask(breakTask)
            demoViewModel.taskManagement?.addTask(studyTask)
        }
    }
    
    // Последовательность анимации
    private func startAnimationSequence() {
        // Показываем циферблат
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showMainClock = true
            }
        }
        
        // Показываем приветственный текст
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.8)) {
                showWelcomeText = true
            }
        }
        
        // Показываем кнопку
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showButton = true
            }
        }
    }
    
    // Добавьте этот метод в FirstView
    private func cancelAllAnimations() {
        // Отменяем все DispatchQueue задачи
        NSObject.cancelPreviousPerformRequests(withTarget: self)
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
    let initialDelay: Double
    let startFromCenter: Bool
    
    // Состояния для анимации из центра
    @State private var currentOffset: CGSize = .zero
    @State private var currentScale: CGFloat = 0.01 // Начинаем с очень маленького размера
    
    init(
        radius: CGFloat, thickness: CGFloat, startAngle: Angle, endAngle: Angle, color: Color,
        animationDuration: Double, maxOffset: CGFloat, initialDelay: Double = 0.0,
        startFromCenter: Bool = false
    ) {
        self.radius = radius
        self.thickness = thickness
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.color = color
        self.animationDuration = animationDuration
        self.maxOffset = maxOffset
        self.initialDelay = initialDelay
        self.startFromCenter = startFromCenter
    }
    
    var body: some View {
        ArcShape(startAngle: startAngle, endAngle: endAngle)
            .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: thickness, lineCap: .round))
            .frame(width: radius * 2, height: radius * 2)
            .rotationEffect(animating ? .degrees(Double.random(in: 0...360)) : .zero)
            .offset(currentOffset)
            .scaleEffect(currentScale)
            .blur(radius: 2)
            .shadow(color: color.opacity(0.4), radius: 8)
            .onAppear {
                // Начальные значения для анимации из центра
                if startFromCenter {
                    currentOffset = .zero
                    currentScale = 0.01 // Начинаем с очень маленького размера
                }
                
                // Добавляем задержку для начала анимации
                DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
                    // Первая анимация - появление из центра
                    if startFromCenter {
                        withAnimation(.easeOut(duration: 1.2)) {
                            currentScale = 0.5 // Сначала вырастаем до среднего размера
                            // Начинаем движение с малого отклонения от центра
                            currentOffset = CGSize(
                                width: CGFloat.random(in: -30...30),
                                height: CGFloat.random(in: -30...30)
                            )
                        }
                        
                        // Вторая фаза - продолжаем рост и движение
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeOut(duration: 1.0)) {
                                currentScale = 1.0 // Вырастаем до полного размера
                                // Увеличиваем отклонение
                                currentOffset = CGSize(
                                    width: CGFloat.random(in: -maxOffset/2...maxOffset/2),
                                    height: CGFloat.random(in: -maxOffset/2...maxOffset/2)
                                )
                            }
                            
                            // Наконец начинаем бесконечную анимацию
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(
                                    Animation.easeInOut(duration: animationDuration).repeatForever(
                                        autoreverses: true)
                                ) {
                                    animating = true
                                    // Полное отклонение
                                    currentOffset = CGSize(
                                        width: CGFloat.random(in: -maxOffset...maxOffset),
                                        height: CGFloat.random(in: -maxOffset...maxOffset)
                                    )
                                }
                            }
                        }
                    } else {
                        // Оригинальная анимация если не startFromCenter
                        withAnimation(
                            Animation.easeInOut(duration: animationDuration).repeatForever(
                                autoreverses: true)
                        ) {
                            animating = true
                        }
                    }
                }
            }
    }
}

struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let radius = min(rect.width, rect.height) / 2 - 50
        path.addArc(
            center: center, radius: radius, startAngle: startAngle - .degrees(90),
            endAngle: endAngle - .degrees(90), clockwise: false)
        return path
    }
}

struct AnimatedFlyingWatchFaceView: View {
    let watchFace: WatchFaceModel
    let index: Int
    let isAnimating: Bool
    let startFromCenter: Bool
    @State private var randomOffset: CGSize = .zero
    @State private var randomRotation: Double = 0
    @State private var randomScale: CGFloat = 0.3
    @State private var handScale: CGFloat = 0.75

    // Обновляем инициализатор для поддержки запуска из центра
    init(watchFace: WatchFaceModel, index: Int, isAnimating: Bool, startFromCenter: Bool = false) {
        self.watchFace = watchFace
        self.index = index
        self.isAnimating = isAnimating
        self.startFromCenter = startFromCenter
    }

    func randomize() {
        // Если должен стартовать из центра, то начальная позиция будет нулевой
        if startFromCenter && !isAnimating {
            randomOffset = .zero
            randomRotation = 0
            randomScale = 0.1  // Начинаем с меньшего размера
        } else {
            randomOffset = CGSize(
                width: CGFloat.random(in: -180...180), height: CGFloat.random(in: -300...300))
            randomRotation = Double.random(in: -60...60)
            randomScale = CGFloat.random(in: 0.2...0.4)
        }
    }

    func animateForever() {
        guard isAnimating else { return }

        let initialDelay = startFromCenter ? Double(index) * 0.1 : 0.0
        let duration = Double.random(in: 7.0...12.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(Animation.easeInOut(duration: duration)) {
                randomize()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                animateForever()
            }
        }
    }

    var body: some View {
        ZStack {
            ModifiedLibraryClockFaceView(
                watchFace: watchFace,
                scale: randomScale,
                handScale: handScale
            )
        }
        .scaleEffect(randomScale)
        .rotationEffect(.degrees(randomRotation))
        .offset(randomOffset)
        .onAppear {
            randomize()
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
    @StateObject private var markersViewModel = ClockMarkersViewModel()
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
                    .id(
                        "marker-hour-\(hour)-\(watchFace.markerStyle)-\(Int(watchFace.markersWidth * 10))"
                    )
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

        init(
            hour: Int, minute: Int, color: Color, fontName: String = "SF Pro",
            fontSize: Double = 40.0
        ) {
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

// Добавляем новый компонент для анимированного кольца планировщика
struct AnimatedRingPlanner: View {
    let color: Color
    @ObservedObject var viewModel: DemoClockViewModel
    let zeroPosition: Double
    let shouldDeleteTask: Bool
    let outerRingLineWidth: CGFloat
    
    @State private var rotationAngle: Double = 0
    
    init(color: Color, viewModel: DemoClockViewModel, zeroPosition: Double, shouldDeleteTask: Bool = true, outerRingLineWidth: CGFloat) {
        self.color = color
        self.viewModel = viewModel
        self.zeroPosition = zeroPosition
        self.shouldDeleteTask = shouldDeleteTask
        self.outerRingLineWidth = outerRingLineWidth
    }

    var body: some View {
        ZStack {
            // Основное кольцо
            Circle()
                .stroke(color, lineWidth: outerRingLineWidth)
                .frame(
                    width: UIScreen.main.bounds.width * 0.8,
                    height: UIScreen.main.bounds.width * 0.8
                )
            
            // Анимированные задачи
            AnimatedTaskArcsView(
                tasks: viewModel.tasks,
                viewModel: viewModel,
                arcLineWidth: viewModel.taskArcLineWidth,
                rotationAngle: rotationAngle
            )
            .rotationEffect(.degrees(rotationAngle))
            .onAppear {
                startRotationAnimation()
            }
        }
    }
    
    private func startRotationAnimation() {
        withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}

// Компонент для анимированных задач
struct AnimatedTaskArcsView: View {
    let tasks: [TaskOnRing]
    @ObservedObject var viewModel: DemoClockViewModel
    let arcLineWidth: CGFloat
    let rotationAngle: Double

    var body: some View {
        ZStack {
            ForEach(tasks) { task in
                AnimatedTaskArc(
                    task: task, 
                    viewModel: viewModel, 
                    arcLineWidth: arcLineWidth,
                    globalRotationAngle: rotationAngle
                )
            }
        }
    }
}

// Отдельная анимированная задача
struct AnimatedTaskArc: View {
    let task: TaskOnRing
    @ObservedObject var viewModel: DemoClockViewModel
    let arcLineWidth: CGFloat
    let globalRotationAngle: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 37
            
            let configuration = TaskArcConfiguration(
                isAnalog: viewModel.isAnalogArcStyle,
                arcLineWidth: arcLineWidth,
                outerRingLineWidth: viewModel.outerRingLineWidth,
                isEditingMode: false,
                showTimeOnlyForActiveTask: viewModel.showTimeOnlyForActiveTask
            )
            
            let taskGeometry = TaskArcGeometry(
                center: center,
                radius: radius,
                configuration: configuration,
                task: task
            )
            
            // Упрощенная версия TaskArcContentView только для демонстрации
            ZStack {
                // Основная дуга
                taskGeometry.createArcPath()
                    .stroke(
                        task.category.color, 
                        lineWidth: configuration.arcLineWidth
                    )
                
                // Круглые маркеры начала и конца задачи
                TaskCircularMarkers(
                    task: task,
                    geometry: taskGeometry,
                    globalRotationAngle: globalRotationAngle
                )
                
                // Иконка с правильным центрированием
                AnimatedTaskIcon(
                    task: task,
                    geometry: taskGeometry,
                    globalRotationAngle: globalRotationAngle
                )
            }
        }
    }
}

// Новый компонент для круглых маркеров задач
struct TaskCircularMarkers: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let globalRotationAngle: Double
    
    // Расстояние маркеров от циферблата
    private let markerOffset: CGFloat = 10
    
    // Вычисляем позиции для начального и конечного маркеров
    private var startMarkerPosition: CGPoint {
        let startAngle = calculateAngle(from: task.startTime)
        let radians = (startAngle - 90) * .pi / 180
        let markerRadius = geometry.radius + markerOffset
        return CGPoint(
            x: geometry.center.x + markerRadius * cos(radians),
            y: geometry.center.y + markerRadius * sin(radians)
        )
    }
    
    private var endMarkerPosition: CGPoint {
        let endAngle = calculateAngle(from: task.endTime)
        let radians = (endAngle - 90) * .pi / 180
        let markerRadius = geometry.radius + markerOffset
        return CGPoint(
            x: geometry.center.x + markerRadius * cos(radians),
            y: geometry.center.y + markerRadius * sin(radians)
        )
    }
    
    var body: some View {
        ZStack {
            // Маркер начала задачи (стиль как TaskDragHandle)
            Circle()
                .fill(task.category.color)
                .frame(width: 20 , height: 20 )
                .overlay(
                    // Внутренняя тень с градиентом
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    Circle().stroke(
                        Color(red: 0.6, green: 0.6, blue: 0.6), 
                        lineWidth: 1.5
                    )
                )
                // Внешняя тень
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 3,
                    x: 1,
                    y: 2
                )
                .position(startMarkerPosition)
            
            // Маркер конца задачи (немного меньше)
            Circle()
                .fill(task.category.color)
                .frame(width: 20 , height: 20 )
                .overlay(
                    // Внутренняя тень с градиентом
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.black.opacity(0.2),
                                    Color.clear,
                                    Color.white.opacity(0.15)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    Circle().stroke(
                        Color(red: 0.6, green: 0.6, blue: 0.6), 
                        lineWidth: 1.2
                    )
                )
                // Внешняя тень
                .shadow(
                    color: Color.black.opacity(0.2),
                    radius: 2,
                    x: 1,
                    y: 1
                )
                .position(endMarkerPosition)
        }
    }
    
    
    // Вычисляем угол для времени (используем 24-часовой формат)
    private func calculateAngle(from date: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let totalMinutes = Double(hour * 60 + minute)
        return (totalMinutes / (24 * 60)) * 360
    }
}

// Анимированная иконка задачи
struct AnimatedTaskIcon: View {
    let task: TaskOnRing
    let geometry: TaskArcGeometry
    let globalRotationAngle: Double
    
    @State private var iconScale: CGFloat = 1.0
    @State private var iconPulse: CGFloat = 1.0
    
    // Упрощенное и стабильное вычисление позиции иконки
    private var iconPosition: CGPoint {
        // Используем стандартный метод из геометрии, но увеличиваем расстояние
        let basePosition = geometry.iconPosition()
        let center = geometry.center
        
        // Вычисляем направление от центра к базовой позиции иконки
        let dx = basePosition.x - center.x
        let dy = basePosition.y - center.y
        let currentDistance = sqrt(dx * dx + dy * dy)
        
        // Если позиция некорректна, используем резервный расчет
        if currentDistance.isNaN || currentDistance < 10 {
            let (startAngle, endAngle) = geometry.angles
            let midAngle = RingTimeCalculator.calculateMidAngle(start: startAngle, end: endAngle)
            let targetRadius = geometry.radius + 35 // Увеличенное расстояние от центра
            
            return CGPoint(
                x: center.x + targetRadius * cos(midAngle.radians),
                y: center.y + targetRadius * sin(midAngle.radians)
            )
        }
        
        // Увеличиваем расстояние от центра на дополнительные 15 пикселей
        let targetDistance = currentDistance + 12
        let ratio = targetDistance / currentDistance
        
        return CGPoint(
            x: center.x + dx * ratio,
            y: center.y + dy * ratio
        )
    }
    
    var body: some View {
        ZStack {
            // Круглый фон иконки с пульсацией
            Circle()
                .fill(task.category.color)
                .frame(width: geometry.iconSize * iconPulse, height: geometry.iconSize * iconPulse)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            
            // Иконка, которая остается вертикально ориентированной
            Image(systemName: task.category.iconName)
                .font(.system(size: geometry.iconFontSize, weight: .medium))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
                // Компенсируем глобальное вращение, чтобы иконка оставалась читаемой
                .rotationEffect(.degrees(-globalRotationAngle))
        }
        .position(iconPosition)
        .scaleEffect(iconScale)
        .onAppear {
            startIconAnimations()
        }
    }
    
    private func startIconAnimations() {
        // Анимация пульсации
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            iconPulse = 1.2
        }
        
        // Анимация масштаба при появлении
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            iconScale = 1.0
        }
    }
}
