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
    
    // Дополнительные настройки
    var zeroPosition: Double = 0.0 // Угол поворота 0 часов
    var outerRingLineWidth: CGFloat = 20.0
    var taskArcLineWidth: CGFloat = 20.0
    var isAnalogArcStyle: Bool = false
    var showTimeOnlyForActiveTask: Bool = false
    var fontName: String = "SF Pro"
    
    static func == (lhs: WatchFaceModel, rhs: WatchFaceModel) -> Bool {
        return lhs.id == rhs.id
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
                lightModeClockFaceColor: Color.green.toHex(),
                darkModeClockFaceColor: Color.green.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex()
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
                darkModeOuterRingColor: Color.brown.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.brown.toHex(),
                darkModeMarkersColor: Color.brown.opacity(0.7).toHex()
            ),
            WatchFaceModel(
                name: "Капучино",
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.coral1.toHex(),
                darkModeClockFaceColor: Color.coral1.toHex(), // #ffd966
                lightModeOuterRingColor: Color.brown.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.brown.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.black.opacity(0.7).toHex(),
                showHourNumbers: false
            ),
            // Минималистичный циферблат
            WatchFaceModel(
                name: "Чистый",
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color.white.toHex(),
                darkModeClockFaceColor: Color.black.toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.2).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.2).toHex(),
                lightModeMarkersColor: Color.gray.toHex(),
                darkModeMarkersColor: Color.gray.toHex(),
                showHourNumbers: false
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
                numberInterval: 2
            )
        ]
    }
    
    // Метод для применения циферблата
    func apply(to themeManager: ThemeManager) {
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

        // Сохраняем другие настройки в UserDefaults как раньше
        UserDefaults.standard.set(WatchFaceModel.displayStyleName(for: style), forKey: "clockStyle")
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
        
        // Принудительно обновляем представление ThemeManager
        // Вызываем публичные методы вместо приватного updateColorsForCurrentTheme()
        let _ = themeManager.currentClockFaceColor
        let _ = themeManager.currentOuterRingColor
        let _ = themeManager.currentMarkersColor
        
        DispatchQueue.main.async {
            themeManager.objectWillChange.send()
        }
    }
    
    // Метод для преобразования внутреннего значения в отображаемое
    static func displayStyleName(for internalStyle: String) -> String {
        switch internalStyle {
        case "classic": return "Классический"
        case "minimal": return "Минимализм"
        case "digital": return "Мегаполис"
        case "modern": return "Контур"
        default: return "Классический"
        }
    }
    
    // Функция для преобразования отображаемого имени в внутреннее значение
    static func internalStyleName(for displayStyle: String) -> String {
        switch displayStyle {
        case "Классический": return "classic"
        case "Минимализм": return "minimal" 
        case "Мегаполис": return "digital"
        case "Контур": return "modern"
        default: return "classic"
        }
    }
    
    // Получение отображаемого имени стиля
    var displayStyleName: String {
        WatchFaceModel.displayStyleName(for: style)
    }
} 
