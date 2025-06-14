//
//  ClockStyles.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI

// MARK: - Clock Style Enum
enum ClockStyle: String, CaseIterable, RawRepresentable {
    case classic  = "classic"   // Классический вид с цифрами
    case minimal  = "minimal"   // Минималистичный вид только с черточками
    case modern   = "modern"    // Современный вид с точками
    case digital  = "digital"   // Цифровой вид

    var markerStyle: MarkerStyle {
        switch self {
        case .classic:
            return .standard
        case .minimal:
            return .thinUniform
        case .modern:
            return .dots
        case .digital:
            return .lines
        }
    }
    
    var displayName: String {
        switch self {
        case .classic:
            return "Классический"
        case .minimal:
            return "Минимализм"
        case .modern:
            return "Контур"
        case .digital:
            return "Цифровой"
        }
    }
}

// MARK: - Marker Style Enum
enum MarkerStyle: String, CaseIterable, RawRepresentable {
    case standard    = "standard"       // Стандартные маркеры
    case lines       = "lines"          // Линии
    case dots        = "dots"           // Точечные
    case classicWatch = "classicWatch"  // Классический часовой стиль
    case thinUniform = "thinUniform"    // Тонкие равномерные
    case hourAccent  = "hourAccent"     // Акцент на часовых маркерах
    case uniformDense = "uniformDense"  // Плотные равномерные
    
    var displayName: String {
        switch self {
        case .standard:
            return "Стандартные"
        case .lines:
            return "Линии"
        case .dots:
            return "Точки" 
        case .classicWatch:
            return "Классические"
        case .thinUniform:
            return "Тонкие"
        case .hourAccent:
            return "Часовые"
        case .uniformDense:
            return "Плотные"
        }
    }
}

// MARK: - Extensions for Compatibility
extension ClockStyle {
    init?(displayName: String) {
        switch displayName {
        case "Классический":
            self = .classic
        case "Минимализм":
            self = .minimal
        case "Контур":
            self = .modern
        case "Цифровой":
            self = .digital
        default:
            return nil
        }
    }
}

extension MarkerStyle {
    init?(displayName: String) {
        switch displayName {
        case "Стандартные":
            self = .standard
        case "Линии":
            self = .lines
        case "Точки":
            self = .dots
        case "Классические":
            self = .classicWatch
        case "Тонкие":
            self = .thinUniform
        case "Часовые":
            self = .hourAccent
        case "Плотные":
            self = .uniformDense
        default:
            return nil
        }
    }
} 