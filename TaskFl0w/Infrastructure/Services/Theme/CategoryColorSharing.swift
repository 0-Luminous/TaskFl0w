//
//  CategoryColorSharing.swift
//  TaskFl0w
//
//  Created by Yan on 30/4/25.
//

import SwiftUI

// Служба для синхронизации цветов категорий с виджетами
class CategoryColorSharing {
    static let shared = CategoryColorSharing()
    
    // Получаем доступ к общим UserDefaults
    let sharedUserDefaults = UserDefaults(suiteName: "group.AbstractSoft.TaskFl0w")
    
    // Ключи для цветов категорий в UserDefaults
    private struct UserDefaultsKeys {
        static let categoryColors = "widget_category_colors"
    }
    
    // Обновление цветов категорий в общем хранилище
    func updateCategoryColors(categories: [TaskCategoryModel]) {
        guard let defaults = sharedUserDefaults else { return }
        
        // Создаем словарь [название категории: цвет в hex]
        var colorDict: [String: String] = [:]
        
        for category in categories {
            colorDict[category.rawValue] = category.color.toHex()
        }
        
        // Сохраняем в UserDefaults
        defaults.set(colorDict, forKey: UserDefaultsKeys.categoryColors)
    }
}