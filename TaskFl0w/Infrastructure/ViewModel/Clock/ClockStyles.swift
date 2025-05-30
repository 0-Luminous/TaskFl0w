import SwiftUI

enum ClockStyle: String, CaseIterable {
    case classic  // Классический вид с цифрами
    case minimal  // Минималистичный вид только с черточками
    case modern   // Современный вид с точками
    case digital  // Цифровой вид

    var markerStyle: MarkerStyle {
        switch self {
        case .classic:
            return .standard
        case .minimal:
            return .standard
        case .modern:
            return .dots
        case .digital:
            return .lines
        }
    }
}

public enum MarkerStyle: String {
    case standard    
    case lines       // Линии
    case dots        // Точечные
    case classicWatch    // Классический
    case thinUniform     // Тонкие 
    case hourAccent      // Часовые
    case uniformDense    // Плотные 
}
