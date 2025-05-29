//
//  WatchFaceCategory.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Перечисление для категорий циферблатов
enum WatchFaceCategory: String, CaseIterable, Identifiable {
    case classic = "Классический"
    case digital = "Цифровой"
    case minimal = "Минимализм"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .classic: return ""
        case .digital: return ""
        case .minimal: return ""
        }
    }
} 