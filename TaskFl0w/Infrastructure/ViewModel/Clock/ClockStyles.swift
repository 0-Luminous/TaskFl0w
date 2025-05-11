import SwiftUI

enum ClockStyle: String, CaseIterable {
    case classic  // Классический вид с цифрами
    case minimal  // Минималистичный вид только с черточками
    case modern   // Современный вид с точками
    case digital  // Цифровой вид

    var markerStyle: MarkerStyle {
        switch self {
        case .classic:
            return .numbers
        case .minimal:
            return .numbers
        case .modern:
            return .dots
        case .digital:
            return .lines
        }
    }
}

public enum MarkerStyle: String {
    case numbers    // Числовые маркеры
    case lines      // Обычные линии
    case dots       // Точечные маркеры
    
    // Новые стили, соответствующие изображению
    case classicWatch    // Верхний левый - классический стиль часов
    case thinUniform     // Верхний правый - тонкие линии одинаковой длины
    case hourAccent      // Нижний левый - акцент только на часовых отметках
    case uniformDense    // Нижний правый - плотные линии одинаковой длины
}
