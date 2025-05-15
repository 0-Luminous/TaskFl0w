//
//  CategoryColorProvider.swift
//  TaskFlowWidgetsExtension
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Класс для получения цветов категорий, общих между основным приложением и виджетами
class CategoryColorProvider {
    // Получаем доступ к общим UserDefaults
    static let sharedUserDefaults = UserDefaults(suiteName: "group.AbstractSoft.TaskFl0w")
    
    // Ключи для цветов категорий в UserDefaults
    private struct UserDefaultsKeys {
        static let categoryColors = "widget_category_colors"
    }
    
    // Получение цвета для категории
    static func getColorFor(category: String) -> Color {
        // По умолчанию используем фиксированное соответствие
        let defaultColor = defaultColorFor(category: category)
        
        // Пытаемся получить цвета из UserDefaults
        guard let defaults = sharedUserDefaults,
              let colorData = defaults.dictionary(forKey: UserDefaultsKeys.categoryColors) as? [String: String] else {
            return defaultColor
        }
        
        // Если есть цвет для этой категории, конвертируем его из hex
        if let hexColor = colorData[category], let color = Color(hex: hexColor) {
            return color
        }
        
        return defaultColor
    }
    
    // Стандартные цвета категорий (если нет в UserDefaults)
    private static func defaultColorFor(category: String) -> Color {
        switch category {
        case "Работа":
            return Color.Blue1
        case "Перерыв":
            return Color.Mint1
        case "Учеба":
            return Color.Purple1
        case "Хобби":
            return Color.Orange1
        case "Отдых":
            return Color.Teal1
        default:
            return Color.Blue1
        }
    }
}

// Добавим расширение для преобразования hex-строки в Color
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}