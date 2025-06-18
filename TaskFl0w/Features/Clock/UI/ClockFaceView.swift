//
//  MainClockFaceViewIOS.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct GlobleClockFaceViewIOS: View {
    // MARK: - Properties
    let currentDate: Date
    let tasks: [TaskOnRing]
    @ObservedObject var viewModel: ClockViewModel
    @ObservedObject var markersViewModel: ClockMarkersViewModel
    @ObservedObject private var themeManager = ThemeManager.shared
    @Binding var draggedCategory: TaskCategoryModel?
    
    // MARK: - Constants
    let zeroPosition: Double
    let taskArcLineWidth: CGFloat
    let outerRingLineWidth: CGFloat
    var isNavigationOverlayVisible: Bool = false
    
    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - AppStorage Properties
    @AppStorage("markersOffset") private var markersOffset: Double = 0.0
    @AppStorage("numberInterval") private var numberInterval: Int = 1
    @AppStorage("markersWidth") private var markersWidth: Double = 2.0
    @AppStorage("numbersSize") private var numbersSize: Double = 16.0
    
    // MARK: - Computed Properties
    private var clockStyleEnum: ClockStyle {
        switch viewModel.clockStyle {
        case "Классический": return .classic
        case "Минимализм": return .minimal
        case "Цифровой": return .digital
        case "Контур": return .modern
        default: return .classic
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Circle()
                .fill(themeManager.currentClockFaceColor)
                .stroke(Color.gray, lineWidth: 2)

            // Добавляем цифровое отображение времени для стиля "Цифровой"
            if viewModel.clockStyle == "Цифровой" {
                // Извлекаем компоненты времени
                let hour = calendar.component(.hour, from: viewModel.currentDate)
                let minute = calendar.component(.minute, from: viewModel.currentDate)
                
                // Отображаем сначала круглый фон
                Circle()
                    .fill(themeManager.currentClockFaceColor)
                    .frame(width: UIScreen.main.bounds.width * 0.3)
                
                // Отображаем цифровое время
                DigitalTimeDisplay(
                    hour: hour, 
                    minute: minute, 
                    color: themeManager.currentMarkersColor,
                    markersViewModel: markersViewModel
                )
            }

            // Маркеры часов (24 шт.) и промежуточные маркеры
            if markersViewModel.showMarkers {
                // Основные часовые маркеры (24 шт.)
                ForEach(0..<24, id: \.self) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    ClockMarker(
                        hour: hour,
                        style: markersViewModel.markerStyle,
                        viewModel: markersViewModel,
                        MarkersColor: themeManager.currentMarkersColor,
                        zeroPosition: zeroPosition,
                        showNumbers: false,
                        isMainMarker: true
                    )
                    .rotationEffect(.degrees(angle))
                    .frame(
                        width: UIScreen.main.bounds.width * 0.7,
                        height: UIScreen.main.bounds.width * 0.7)
                    .id("marker-\(hour)-\(Int(zeroPosition))-\(markersViewModel.markerStyle)-main")
                }
                
                // Промежуточные маркеры (4 маркера между каждой парой часов)
                if markersViewModel.showIntermediateMarkers {
                    ForEach(0..<96, id: \.self) { minuteMarker in
                        let angle = Double(minuteMarker) * (360.0 / 96.0)
                        // Пропускаем позиции, где уже есть часовые маркеры
                        if minuteMarker % 4 != 0 {
                            ClockMarker(
                                hour: minuteMarker / 4, // Сопоставляем с ближайшим часом
                                minuteIndex: minuteMarker % 4, // Индекс минутного маркера (1, 2, 3)
                                style: markersViewModel.markerStyle,
                                viewModel: markersViewModel,
                                MarkersColor: themeManager.currentMarkersColor,
                                zeroPosition: zeroPosition,
                                showNumbers: false,
                                isMainMarker: false
                            )
                            .rotationEffect(.degrees(angle))
                            .frame(
                                width: UIScreen.main.bounds.width * 0.7,
                                height: UIScreen.main.bounds.width * 0.7)
                            .id("marker-minute-\(minuteMarker)-\(Int(zeroPosition))-\(markersViewModel.markerStyle)")
                        }
                    }
                }
            }
            
            // Слой с цифрами (отдельно) - показываем независимо от маркеров
            if markersViewModel.showHourNumbers && viewModel.clockStyle != "Цифровой" {
                ForEach(0..<24, id: \.self) { hour in
                    let angle = Double(hour) * (360.0 / 24.0)
                    // Проверяем, нужно ли отображать число в соответствии с интервалом
                    if shouldShowHourNumber(hour: hour) {
                        HourNumberView(
                            hour: hour,
                            viewModel: markersViewModel,
                            color: themeManager.currentMarkersColor,
                            zeroPosition: zeroPosition
                        )
                        .rotationEffect(.degrees(angle))
                        .frame(
                            width: UIScreen.main.bounds.width * 0.7,
                            height: UIScreen.main.bounds.width * 0.7)
                        // Добавляем идентификатор для принудительной переотрисовки
                        .id("hour-number-\(hour)-\(Int(zeroPosition))")
                    }
                }
            }

            TaskArcsViewIOS(
                tasks: viewModel.tasksForSelectedDate(tasks),
                viewModel: viewModel,
                arcLineWidth: taskArcLineWidth
            )

            ClockHandViewIOS(currentDate: viewModel.currentDate, outerRingLineWidth: outerRingLineWidth)
                .rotationEffect(.degrees(zeroPosition))

            // Показ точки, куда «кидаем» категорию
            if let location = viewModel.dropLocation {
                Circle()
                    .fill(viewModel.draggedCategory?.color ?? .clear)
                    .frame(width: 20, height: 20)
                    .position(location)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(height: UIScreen.main.bounds.width * 0.7)
        .padding()
        // .animation(.spring(), value: viewModel.tasksForSelectedDate(tasks))
        .animation(.spring(), value: markersViewModel.showMarkers)
        .animation(.spring(), value: markersViewModel.showHourNumbers)
        .onAppear {
            markersViewModel.zeroPosition = zeroPosition
            markersViewModel.isDarkMode = themeManager.isDarkMode
            markersViewModel.numberInterval = numberInterval
            markersViewModel.markersOffset = markersOffset
            markersViewModel.markersWidth = markersWidth
            markersViewModel.numbersSize = numbersSize
            markersViewModel.markerStyle = viewModel.markerStyle
            // Принудительно обновляем View
            updateMarkersViewModel()
        }
        .onChange(of: zeroPosition) { oldValue, newValue in
            markersViewModel.zeroPosition = newValue
        }
        .onChange(of: themeManager.isDarkMode) { oldValue, newValue in
            markersViewModel.isDarkMode = newValue
        }
        .onChange(of: numberInterval) { oldValue, newValue in
            markersViewModel.numberInterval = newValue
        }
        .onChange(of: markersOffset) { oldValue, newValue in
            markersViewModel.markersOffset = newValue
            updateMarkersViewModel()
        }
        .onChange(of: markersWidth) { oldValue, newValue in
            markersViewModel.markersWidth = newValue
            updateMarkersViewModel()
        }
        .onChange(of: numbersSize) { oldValue, newValue in
            markersViewModel.numbersSize = newValue
            updateMarkersViewModel()
        }
        .onChange(of: markersViewModel.markerStyle) { oldValue, newValue in
            // Принудительно обновляем View
            updateMarkersViewModel()
        }
        .onChange(of: markersViewModel.showIntermediateMarkers) { oldValue, newValue in
            // Принудительно обновляем View
            updateMarkersViewModel()
        }
    }

    // MARK: - Private Methods
    private func updateMarkersViewModel() {
        let tempWidth = markersViewModel.markersWidth
        DispatchQueue.main.async {
            markersViewModel.markersWidth = tempWidth + 0.01
            DispatchQueue.main.async {
                markersViewModel.markersWidth = tempWidth
            }
        }
    }
    
    private func shouldShowHourNumber(hour: Int) -> Bool {
        let hourShift = Int(zeroPosition / 15.0)
        let adjustedHour = (hour - hourShift + 24) % 24
        return adjustedHour % numberInterval == 0
    }
}

// MARK: - Supporting Views
private struct DigitalTimeDisplay: View {
    let hour: Int
    let minute: Int
    let color: Color
    @ObservedObject private var markersViewModel: ClockMarkersViewModel
    
    init(hour: Int, minute: Int, color: Color, markersViewModel: ClockMarkersViewModel = ClockMarkersViewModel.shared) {
        self.hour = hour
        self.minute = minute
        self.color = color
        self.markersViewModel = markersViewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("\(hour, specifier: "%02d")")
                .font(digitalFont)
                .foregroundColor(markersViewModel.currentDigitalFontColor)
            
            Text("\(minute, specifier: "%02d")")
                .font(digitalFont)
                .foregroundColor(markersViewModel.currentDigitalFontColor)
        }
    }
    
    // Создаем шрифт на основе настроек
    private var digitalFont: Font {
        // Получаем размер шрифта из настроек
        let fontSize: CGFloat = CGFloat(markersViewModel.digitalFontSize)
        
        // Для цифрового циферблата используем digitalFont, если он доступен в UserDefaults
        let digitalFontName = UserDefaults.standard.string(forKey: "digitalFont") ?? markersViewModel.fontName
        
        // Сначала пробуем использовать кастомный шрифт
        if digitalFontName != "SF Pro" {
            return Font.custom(digitalFontName, size: fontSize)
                .weight(.bold)
        }
        
        // По умолчанию используем системный моноширинный шрифт
        return .system(size: fontSize, weight: .bold, design: .monospaced)
    }
}

// MARK: - Calendar Extension
private extension GlobleClockFaceViewIOS {
    var calendar: Calendar {
        Calendar.current
    }
}
