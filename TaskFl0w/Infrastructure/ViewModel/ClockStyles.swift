import SwiftUI

enum ClockStyle: String, CaseIterable {
    case classic    // Классический вид с цифрами
    case minimal    // Минималистичный вид только с черточками
    case modern     // Современный вид с точками
    
    var markerStyle: MarkerStyle {
        switch self {
        case .classic:
            return .numbers
        case .minimal:
            return .lines
        case .modern:
            return .dots
        }
    }
}

enum MarkerStyle {
    case numbers
    case lines
    case dots
} 