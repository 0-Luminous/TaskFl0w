//
//  ClockThemeModels.swift
//  TaskFl0w
//
//  Created by Refactoring on 19/01/25.
//

import SwiftUI
import Foundation

// MARK: - Configuration Structs

/// Настройки циферблата часов
struct ClockSettings {
    let defaultFontName = "SF Pro"
    let defaultDigitalFontSize: Double = 42.0
    let defaultMarkersWidth: Double = 2.0
    let defaultNumbersSize: Double = 16.0
    let defaultNumberInterval: Int = 1
}

/// Настройки маркеров циферблата
struct MarkerSettings {
    let width: Double
    let offset: Double
    let numbersSize: Double
    let numberInterval: Int
    let fontName: String
    let style: MarkerStyle
    let showHourNumbers: Bool
    let showMarkers: Bool
    let showIntermediateMarkers: Bool
}

/// Кастомные цвета темы для ClockViewModel
struct ClockThemeColors {
    let lightModeHandColor: String
    let darkModeHandColor: String
    let lightModeDigitalFontColor: String
    let darkModeDigitalFontColor: String
    let lightModeClockFaceColor: String
    let darkModeClockFaceColor: String
    let lightModeOuterRingColor: String
    let darkModeOuterRingColor: String
    let lightModeMarkersColor: String
    let darkModeMarkersColor: String
} 