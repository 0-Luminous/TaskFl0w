//
//  WatchFaceCategory.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// Перечисление для категорий циферблатов
enum WatchFaceCategory: String, CaseIterable, Identifiable {
    case minimal = "minimal"
    case classic = "classics"
    case digital = "digital"
    
    var id: String { rawValue }
    
    // Локализованное отображаемое название
    var localizedName: String {
        switch self {
        case .classic:
            return String(localized: "libraryOfWatchFaces.category.classics")
        case .digital:
            return String(localized: "libraryOfWatchFaces.category.digital")
        case .minimal:
            return String(localized: "libraryOfWatchFaces.category.minimal")
        }
    }
    
    var systemImage: String {
        switch self {
        case .classic: return "circle.dotted.circle"
        case .digital: return "numbers.rectangle"
        case .minimal: return "circle"
        }
    }
} 