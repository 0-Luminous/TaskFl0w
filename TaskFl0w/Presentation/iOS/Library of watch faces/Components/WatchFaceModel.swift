//
//  WatchFaceModel.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// MARK: - Модель циферблата
struct WatchFaceModel: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var style: String // Используем String, чтобы легко хранить в UserDefaults
    var isCustom: Bool = false
    var category: String = WatchFaceCategory.classic.rawValue
    
    // Цвета в формате HEX для сохранения
    var lightModeClockFaceColor: String
    var darkModeClockFaceColor: String
    var lightModeOuterRingColor: String
    var darkModeOuterRingColor: String
    var lightModeMarkersColor: String
    var darkModeMarkersColor: String
    
    // Настройки маркеров
    var showMarkers: Bool = true
    var showHourNumbers: Bool = true
    var numberInterval: Int = 1
    var markersOffset: Double = 0.0
    var markersWidth: Double = 2.0
    var numbersSize: Double = 16.0
    var markerStyle: String = "standard" // Добавляем стиль маркеров
    var showIntermediateMarkers: Bool = true // Добавляем промежуточные маркеры
    
    // Дополнительные настройки
    var zeroPosition: Double = 0.0 // Угол поворота 0 часов
    var outerRingLineWidth: CGFloat = 20.0
    var taskArcLineWidth: CGFloat = 20.0
    var isAnalogArcStyle: Bool = false
    var showTimeOnlyForActiveTask: Bool = false
    var fontName: String = "SF Pro"
    
    var lightModeHandColor: String
    var darkModeHandColor: String
    
    static func == (lhs: WatchFaceModel, rhs: WatchFaceModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Получение MarkerStyle из строки
    var markerStyleEnum: MarkerStyle {
        MarkerStyle(rawValue: markerStyle) ?? .standard
    }
    
    // Предустановленные циферблаты
    static var defaultWatchFaces: [WatchFaceModel] {
        [
            // Классический светлый циферблат
            WatchFaceModel(
                name: "Классический",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.85, green: 0.85, blue: 0.85).toHex(),
                darkModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.2).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                fontName: "SF Pro",
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),
            // Добавляем еще один классический циферблат
            WatchFaceModel(
                name: "Капучино",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.95, green: 0.95, blue: 0.87).toHex(),
                darkModeClockFaceColor: Color(red: 1, green: 0.851, blue: 0.4).toHex(), // #ffd966
                lightModeOuterRingColor: Color.brown.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.toHex(),
                lightModeMarkersColor: Color.brown.toHex(),
                darkModeMarkersColor: Color.brown.opacity(0.7).toHex(),
                showHourNumbers: true,
                markerStyle: "classicWatch",
                showIntermediateMarkers: true,
                fontName: "Brillant",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            // Добавляем кастомные циферблаты с разными шрифтами и стилями маркеров
            WatchFaceModel(
                name: "Московский",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.95, green: 0.95, blue: 0.95).toHex(),
                darkModeClockFaceColor: Color(red: 0.15, green: 0.15, blue: 0.15).toHex(),
                lightModeOuterRingColor: Color.red1.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.red1.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                markerStyle: "lines",
                showIntermediateMarkers: true,
                fontName: "MOSCOW2024",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            WatchFaceModel(
                name: "Лесной",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.9, green: 0.95, blue: 0.9).toHex(),
                darkModeClockFaceColor: Color(red: 0.1, green: 0.2, blue: 0.1).toHex(),
                lightModeOuterRingColor: Color.green.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.green.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                fontName: "ForestSmooth",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            WatchFaceModel(
                name: "Бриллиант",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.9, green: 0.9, blue: 0.9).toHex(),
                darkModeClockFaceColor: Color(red: 0.15, green: 0.15, blue: 0.15).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color(red: 0.6, green: 0.976, blue: 0.98).toHex(),
                darkModeMarkersColor: Color(red: 0.6, green: 0.976, blue: 0.98).toHex(),
                showHourNumbers: true,
                markerStyle: "thinUniform",
                showIntermediateMarkers: false,
                fontName: "Brillant",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            WatchFaceModel(
                name: "Цифровой",
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.coral1.toHex(),
                darkModeClockFaceColor: Color.coral1.toHex(), // #ffd966
                lightModeOuterRingColor: Color.brown.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.brown.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.black.opacity(0.7).toHex(),
                showHourNumbers: false,
                markerStyle: "dots",
                showIntermediateMarkers: false,
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            // Цифровой циферблат
            WatchFaceModel(
                name: "Стандартный",
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color.black.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.8).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.8).toHex(),
                lightModeMarkersColor: Color.gray.toHex(),
                darkModeMarkersColor: Color.gray.toHex(),
                showHourNumbers: true, 
                numberInterval: 2,
                markerStyle: "uniformDense",
                showIntermediateMarkers: true,
                fontName: "ForestSmooth",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            // Необычные стили
            WatchFaceModel(
                name: "Ретро",
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.98, green: 0.94, blue: 0.85).toHex(), 
                darkModeClockFaceColor: Color(red: 0.2, green: 0.12, blue: 0.05).toHex(),
                lightModeOuterRingColor: Color.brown.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.brown.opacity(0.4).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.opacity(0.9).toHex(),
                showHourNumbers: true,
                markerStyle: "classicWatch",
                showIntermediateMarkers: false,
                fontName: "Tsarevich old",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            WatchFaceModel(
                name: "Футуристический",
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.25).toHex(),
                darkModeClockFaceColor: Color(red: 0.1, green: 0.1, blue: 0.2).toHex(),
                lightModeOuterRingColor: Color.blue.opacity(0.7).toHex(),
                darkModeOuterRingColor: Color.blue.opacity(0.9).toHex(),
                lightModeMarkersColor: Color.white.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: false,
                markerStyle: "dots",
                showIntermediateMarkers: true,
                fontName: "Menlo-Bold",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            ),
            // Минималистичный стиль с необычными маркерами
            WatchFaceModel(
                name: "Тонкий",
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color(red: 0.98, green: 0.98, blue: 0.98).toHex(),
                darkModeClockFaceColor: Color(red: 0.1, green: 0.1, blue: 0.1).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.2).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                lightModeMarkersColor: Color.black.opacity(0.7).toHex(),
                darkModeMarkersColor: Color.white.opacity(0.7).toHex(),
                showHourNumbers: true,
                numberInterval: 3,
                markerStyle: "thinUniform",
                showIntermediateMarkers: true,
                fontName: "Gill Sans",
                lightModeHandColor: Color.blue.toHex(),
                darkModeHandColor: Color.blue.toHex()
            )
        ]
    }
    
    // Метод для применения циферблата
    func apply(to themeManager: ThemeManager, markersViewModel: ClockMarkersViewModel? = nil) {
        // Применяем цвета через метод ThemeManager
        let lightFaceColor = Color(hex: lightModeClockFaceColor) ?? .white
        themeManager.updateColor(lightFaceColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
        
        let darkFaceColor = Color(hex: darkModeClockFaceColor) ?? .black
        themeManager.updateColor(darkFaceColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
        
        let lightRingColor = Color(hex: lightModeOuterRingColor) ?? .gray.opacity(0.3)
        themeManager.updateColor(lightRingColor, for: ThemeManager.Constants.lightModeOuterRingColorKey)
        
        let darkRingColor = Color(hex: darkModeOuterRingColor) ?? .gray.opacity(0.3)
        themeManager.updateColor(darkRingColor, for: ThemeManager.Constants.darkModeOuterRingColorKey)
        
        let lightMarkersColor = Color(hex: lightModeMarkersColor) ?? .black
        themeManager.updateColor(lightMarkersColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
        
        let darkMarkersColor = Color(hex: darkModeMarkersColor) ?? .white
        themeManager.updateColor(darkMarkersColor, for: ThemeManager.Constants.darkModeMarkersColorKey)

        // Получаем отображаемое имя стиля для сохранения и уведомлений
        let displayStyleName = WatchFaceModel.displayStyleName(for: style)
        
        // Сохраняем другие настройки в UserDefaults как раньше
        UserDefaults.standard.set(displayStyleName, forKey: "clockStyle")
        UserDefaults.standard.set(showMarkers, forKey: "showMarkers")
        UserDefaults.standard.set(showHourNumbers, forKey: "showHourNumbers")
        UserDefaults.standard.set(numberInterval, forKey: "numberInterval")
        UserDefaults.standard.set(markersOffset, forKey: "markersOffset")
        UserDefaults.standard.set(markersWidth, forKey: "markersWidth")
        UserDefaults.standard.set(numbersSize, forKey: "numbersSize")
        UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
        UserDefaults.standard.set(outerRingLineWidth, forKey: "outerRingLineWidth")
        UserDefaults.standard.set(taskArcLineWidth, forKey: "taskArcLineWidth")
        UserDefaults.standard.set(isAnalogArcStyle, forKey: "isAnalogArcStyle")
        UserDefaults.standard.set(showTimeOnlyForActiveTask, forKey: "showTimeOnlyForActiveTask")
        UserDefaults.standard.set(fontName, forKey: "fontName")
        UserDefaults.standard.set(markerStyle, forKey: "markerStyle")
        UserDefaults.standard.set(showIntermediateMarkers, forKey: "showIntermediateMarkers")
        
        // Принудительно обновляем представление ThemeManager
        // Вызываем публичные методы вместо приватного updateColorsForCurrentTheme()
        let _ = themeManager.currentClockFaceColor
        let _ = themeManager.currentOuterRingColor
        let _ = themeManager.currentMarkersColor
        
        // Отправляем уведомление для обновления clockStyle во всех активных экземплярах ClockViewModel
        NotificationCenter.default.post(
            name: NSNotification.Name("ClockStyleDidChange"),
            object: nil,
            userInfo: ["clockStyle": displayStyleName]
        )
        
        DispatchQueue.main.async {
            themeManager.objectWillChange.send()
        }
        
        // Дополнительно обновляем ViewModel для маркеров
        if let markersViewModel = markersViewModel {
            markersViewModel.showHourNumbers = showHourNumbers
            markersViewModel.fontName = fontName
            markersViewModel.markerStyle = markerStyleEnum // Устанавливаем стиль маркеров
            markersViewModel.showIntermediateMarkers = showIntermediateMarkers // Добавляем промежуточные маркеры
            markersViewModel.objectWillChange.send()
        }
    }
    
    // Метод для преобразования внутреннего значения в отображаемое
    static func displayStyleName(for internalStyle: String) -> String {
        switch internalStyle {
        case "classic": return "Классический"
        case "minimal": return "Минимализм"
        case "digital": return "Цифровой"
        case "modern": return "Контур"
        default: return "Классический"
        }
    }
    
    // Функция для преобразования отображаемого имени в внутреннее значение
    static func internalStyleName(for displayStyle: String) -> String {
        switch displayStyle {
        case "Классический": return "classic"
        case "Минимализм": return "minimal" 
        case "Цифровой": return "digital"
        case "Контур": return "modern"
        default: return "classic"
        }
    }
    
    // Получение отображаемого имени стиля
    var displayStyleName: String {
        WatchFaceModel.displayStyleName(for: style)
    }
    
    // Получить отображаемое имя стиля маркеров
    func getMarkerStyleDisplayName() -> String {
        let styleEnum = markerStyleEnum
        switch styleEnum {
        case .lines: return "Линии"
        case .dots: return "Точки"
        case .standard: return "Стандартные"
        case .classicWatch: return "Классические"
        case .thinUniform: return "Тонкие"
        case .hourAccent: return "Часовые"
        case .uniformDense: return "Плотные"
        }
    }
} 
