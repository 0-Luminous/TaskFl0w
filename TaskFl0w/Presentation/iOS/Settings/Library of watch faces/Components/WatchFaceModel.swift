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
    var digitalFont: String = "SF Pro" // Шрифт для цифровых циферблатов
    var digitalFontSize: Double = 32.0 // Размер шрифта для цифровых циферблатов
    var lightModeDigitalFontColor: String = Color.black.toHex() // Цвет шрифта в светлой теме
    var darkModeDigitalFontColor: String = Color.white.toHex() // Цвет шрифта в темной теме
    
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
                name: "libraryOfWatchFaces.model.classic".localized,
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
                name: "libraryOfWatchFaces.model.grafitti".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.596, green: 0.596, blue: 0.596).toHex(),
                darkModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.2).toHex(), // #ffd966
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color(red: 1, green: 1, blue: 0.329).toHex(),
                darkModeMarkersColor: Color(red: 1, green: 1, blue: 0.329).toHex(),
                showHourNumbers: true,
                markerStyle: "classicWatch",
                showIntermediateMarkers: true,
                fontName: "pershotravneva55-regular",
                lightModeHandColor: Color(red: 1, green: 1, blue: 0.329).toHex(),
                darkModeHandColor: Color(red: 1, green: 1, blue: 0.329).toHex()
            ),
            // Добавляем кастомные циферблаты с разными шрифтами и стилями маркеров
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.crimsonCore".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.851, green: 0.851, blue: 0.851).toHex(),
                darkModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.2).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color(red: 0.918, green: 0.302, blue: 0.435).toHex(),
                darkModeMarkersColor: Color(red: 0.918, green: 0.302, blue: 0.435).toHex(),
                showHourNumbers: true,
                markerStyle: "lines",
                showIntermediateMarkers: true,
                fontName: "Banana Brick",
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.red1.toHex()
            ),
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.forest".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.212, green: 0.486, blue: 0.325).toHex(),
                darkModeClockFaceColor: Color(red: 0.1, green: 0.2, blue: 0.1).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color(red: 0.557, green: 0.949, blue: 0.557).toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                fontName: "ForestSmooth",
                lightModeHandColor: Color(red: 0.557, green: 0.949, blue: 0.557).toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.inferno".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.922, green: 0.267, blue: 0.353).toHex(),
                darkModeClockFaceColor: Color(red: 0.922, green: 0.267, blue: 0.353).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.white.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                markerStyle: "thinUniform",
                showIntermediateMarkers: false,
                fontName: "cellblocknbp",
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),       
            // Необычные стили
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.bluePixel".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.classic.rawValue,
                lightModeClockFaceColor: Color(red: 0.471, green: 0.776, blue: 0.961).toHex(), 
                darkModeClockFaceColor: Color(red: 0.231, green: 0.322, blue: 0.463).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color(red: 0.208, green: 0.384, blue: 0.498).toHex(),
                darkModeMarkersColor: Color(red: 0.631, green: 0.988, blue: 1).toHex(),
                showHourNumbers: true,
                markerStyle: "classicWatch",
                showIntermediateMarkers: false,
                fontName: "TDAText",
                lightModeHandColor: Color(red: 0.361, green: 0.686, blue: 0.773).toHex(),
                darkModeHandColor: Color(red: 0.361, green: 0.686, blue: 0.773).toHex()
            ),
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.lines".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color(red: 0.85, green: 0.85, blue: 0.85).toHex(),
                darkModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.2).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: false,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                digitalFont: "catstack",
                digitalFontSize: 60.0,
                lightModeDigitalFontColor: Color.black.toHex(),
                darkModeDigitalFontColor: Color.white.toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ), 
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.coral".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.coral1.toHex(),
                darkModeClockFaceColor: Color.coral1.toHex(), // #ffd966
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.black.opacity(0.7).toHex(),
                showHourNumbers: false,
                markerStyle: "thinUniform",
                showIntermediateMarkers: true,
                digitalFont: "SF Pro",
                digitalFontSize: 55.0,
                lightModeDigitalFontColor: Color.black.toHex(),
                darkModeDigitalFontColor: Color.black.opacity(0.7).toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ), 
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.happyBeat".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.Pink1.toHex(),
                darkModeClockFaceColor: Color.Pink1.toHex(), // #ffd966
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.black.toHex(),
                showHourNumbers: false,
                markerStyle: "uniformDense",
                showIntermediateMarkers: true,
                digitalFont: "pershotravneva55-regular",
                digitalFontSize: 60.0,
                lightModeDigitalFontColor: Color(red: 0.969, green: 0.808, blue: 0.275).toHex(),
                darkModeDigitalFontColor: Color(red: 0.969, green: 0.808, blue: 0.275).toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ), 
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.technoRhythm".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color(red: 0.969, green: 0.808, blue: 0.275).toHex(),
                darkModeClockFaceColor: Color(red: 0.596, green: 0.596, blue: 0.596).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.gray.toHex(),
                darkModeMarkersColor: Color.black.toHex(),
                showHourNumbers: false,
                markerStyle: "lines",
                showIntermediateMarkers: true,
                digitalFont: "Minstrels",
                digitalFontSize: 60.0,
                lightModeDigitalFontColor: Color.black.toHex(),
                darkModeDigitalFontColor: Color(red: 0.969, green: 0.808, blue: 0.275).toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.redPixel".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color(red: 0.851, green: 0.851, blue: 0.851).toHex(),
                darkModeClockFaceColor: Color(red: 0.098, green: 0.098, blue: 0.098).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: false,
                markerStyle: "lines",
                showIntermediateMarkers: true,
                digitalFont: "TDAText",
                digitalFontSize: 60.0,
                lightModeDigitalFontColor: Color(red: 0.922, green: 0.267, blue: 0.353).toHex(),
                darkModeDigitalFontColor: Color(red: 0.922, green: 0.267, blue: 0.353).toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.green".localized,
                style: "digital",
                isCustom: false,
                category: WatchFaceCategory.digital.rawValue,
                lightModeClockFaceColor: Color.green0.toHex(),
                darkModeClockFaceColor: Color(red: 0.098, green: 0.098, blue: 0.098).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.green0.toHex(),
                showHourNumbers: false,
                markerStyle: "lines",
                showIntermediateMarkers: true,
                digitalFont: "Letterblocks",
                digitalFontSize: 60.0,
                lightModeDigitalFontColor: Color.black.toHex(),
                darkModeDigitalFontColor: Color.green0.toHex(),
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.green0.toHex()
            ),     
            // Классический светлый циферблат
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.classic".localized,
                style: "classic",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color(red: 0.85, green: 0.85, blue: 0.85).toHex(),
                darkModeClockFaceColor: Color(red: 0.2, green: 0.2, blue: 0.2).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color.white.toHex(),
                showHourNumbers: true,
                numberInterval: 2,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                fontName: "Futura",
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color.gray.toHex()
            ),
            // Минималистичный стиль с необычными маркерами
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.yellowBits".localized,
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color(red: 0.965, green: 0.808, blue: 0.275).toHex(),
                darkModeClockFaceColor: Color(red: 0.678, green: 0.565, blue: 0.18).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color(red: 1, green: 0.965, blue: 0.392).toHex(),
                showHourNumbers: true,
                numberInterval: 3,
                markerStyle: "thinUniform",
                showIntermediateMarkers: true,
                fontName: "MOSCOW2024",
                lightModeHandColor: Color(red: 0.969, green: 0.847, blue: 0.286).toHex(),
                darkModeHandColor: Color(red: 0.969, green: 0.847, blue: 0.286).toHex()
            ),
            // Минималистичный стиль с необычными маркерами
            WatchFaceModel(
                name: "libraryOfWatchFaces.model.diamond".localized,
                style: "minimal",
                isCustom: false,
                category: WatchFaceCategory.minimal.rawValue,
                lightModeClockFaceColor: Color(red: 0.604, green: 0.988, blue: 0.992).toHex(),
                darkModeClockFaceColor: Color(red: 0.243, green: 0.475, blue: 0.537).toHex(),
                lightModeOuterRingColor: Color.gray.opacity(0.3).toHex(),
                darkModeOuterRingColor: Color.gray.opacity(0.5).toHex(),
                lightModeMarkersColor: Color.black.toHex(),
                darkModeMarkersColor: Color(red: 0.608, green: 0.941, blue: 0.965).toHex(), // #9bf0f6
                showHourNumbers: true,
                numberInterval: 2,
                markerStyle: "hourAccent",
                showIntermediateMarkers: true,
                fontName: "Brillant",
                lightModeHandColor: Color.gray.toHex(),
                darkModeHandColor: Color(red: 0.608, green: 0.941, blue: 0.965).toHex()
            ),
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
        UserDefaults.standard.set(digitalFont, forKey: "digitalFont")
        UserDefaults.standard.set(lightModeDigitalFontColor, forKey: "lightModeDigitalFontColor")
        UserDefaults.standard.set(darkModeDigitalFontColor, forKey: "darkModeDigitalFontColor")
        UserDefaults.standard.set(markerStyle, forKey: "markerStyle")
        UserDefaults.standard.set(showIntermediateMarkers, forKey: "showIntermediateMarkers")
        UserDefaults.standard.set(digitalFontSize, forKey: "digitalFontSize")
        
        // Добавляем сохранение цветов стрелки перед отправкой уведомления
        UserDefaults.standard.set(lightModeHandColor, forKey: "lightModeHandColor")
        UserDefaults.standard.set(darkModeHandColor, forKey: "darkModeHandColor")
        
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
            
            // Обновляем настройки для цифровых циферблатов
            // Закомментируем строки, так как свойства еще не добавлены в ClockMarkersViewModel
            /*
            if style == "digital" {
                markersViewModel.digitalFont = digitalFont
                markersViewModel.digitalFontSize = digitalFontSize
                markersViewModel.lightModeDigitalFontColor = lightModeDigitalFontColor
                markersViewModel.darkModeDigitalFontColor = darkModeDigitalFontColor
            }
            */
            
            markersViewModel.objectWillChange.send()
        }
        
        // После всех сохранений и обновлений отправляем дополнительное уведомление
        // для полной синхронизации экрана часов
        NotificationCenter.default.post(
            name: NSNotification.Name("WatchFaceApplied"),
            object: nil,
            userInfo: ["watchFaceID": id.uuidString]
        )
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
