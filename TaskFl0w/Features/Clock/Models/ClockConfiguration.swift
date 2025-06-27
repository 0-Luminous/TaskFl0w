//
//  ClockConfiguration.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import SwiftUI
import Combine

// MARK: - Clock Configuration

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

struct ClockConfiguration {
    
    // MARK: - Display Settings
    var clockStyle: String
    var showHourNumbers: Bool
    var showMarkers: Bool
    var showIntermediateMarkers: Bool
    var showTimeOnlyForActiveTask: Bool
    
    // MARK: - Dimensions
    var taskArcLineWidth: CGFloat
    var outerRingLineWidth: CGFloat
    var markersWidth: Double
    var markersOffset: Double
    var numbersSize: Double
    var digitalFontSize: Double
    
    // MARK: - Style Settings
    var isAnalogArcStyle: Bool
    var markerStyle: MarkerStyle
    var numberInterval: Int
    var fontName: String
    var digitalFont: String
    
    // MARK: - Position
    var zeroPosition: Double
    
    // MARK: - Default Configuration
    static var `default`: ClockConfiguration {
        ClockConfiguration(
            clockStyle: UserDefaultsDefaults.clockStyle,
            showHourNumbers: true,
            showMarkers: true,
            showIntermediateMarkers: true,
            showTimeOnlyForActiveTask: false,
            taskArcLineWidth: CGFloat(UserDefaultsDefaults.taskArcLineWidth),
            outerRingLineWidth: CGFloat(UserDefaultsDefaults.outerRingLineWidth),
            markersWidth: UserDefaultsDefaults.markersWidth,
            markersOffset: 0.0,
            numbersSize: UserDefaultsDefaults.numbersSize,
            digitalFontSize: UserDefaultsDefaults.digitalFontSize,
            isAnalogArcStyle: false,
            markerStyle: .lines,
            numberInterval: UserDefaultsDefaults.numberInterval,
            fontName: UserDefaultsDefaults.fontName,
            digitalFont: UserDefaultsDefaults.fontName,
            zeroPosition: 0.0
        )
    }
}

// MARK: - Clock Configuration Manager
@MainActor
final class ClockConfigurationManager: ObservableObject {
    
    // MARK: - Published Configuration
    @Published var configuration: ClockConfiguration {
        didSet { saveConfiguration() }
    }
    
    // MARK: - Initialization
    init() {
        self.configuration = ClockConfigurationManager.loadConfiguration()
    }
    
    // MARK: - Private Methods
    private static func loadConfiguration() -> ClockConfiguration {
        return ClockConfiguration(
            clockStyle: UserDefaults.standard.string(for: .clockStyle, defaultValue: UserDefaultsDefaults.clockStyle),
            showHourNumbers: UserDefaults.standard.bool(for: .showHourNumbers, defaultValue: true),
            showMarkers: UserDefaults.standard.bool(for: .showMarkers, defaultValue: true),
            showIntermediateMarkers: UserDefaults.standard.bool(for: .showIntermediateMarkers, defaultValue: true),
            showTimeOnlyForActiveTask: UserDefaults.standard.bool(for: .showTimeOnlyForActiveTask),
            taskArcLineWidth: CGFloat(UserDefaults.standard.double(for: .taskArcLineWidth, defaultValue: UserDefaultsDefaults.taskArcLineWidth)),
            outerRingLineWidth: CGFloat(UserDefaults.standard.double(for: .outerRingLineWidth, defaultValue: UserDefaultsDefaults.outerRingLineWidth)),
            markersWidth: UserDefaults.standard.double(for: .markersWidth, defaultValue: UserDefaultsDefaults.markersWidth),
            markersOffset: UserDefaults.standard.double(for: .markersOffset),
            numbersSize: UserDefaults.standard.double(for: .numbersSize, defaultValue: UserDefaultsDefaults.numbersSize),
            digitalFontSize: UserDefaults.standard.double(for: .digitalFontSize, defaultValue: UserDefaultsDefaults.digitalFontSize),
            isAnalogArcStyle: UserDefaults.standard.bool(for: .isAnalogArcStyle),
            markerStyle: MarkerStyle(rawValue: UserDefaults.standard.string(for: .markerStyle, defaultValue: MarkerStyle.lines.rawValue)) ?? .lines,
            numberInterval: UserDefaults.standard.int(for: .numberInterval, defaultValue: UserDefaultsDefaults.numberInterval),
            fontName: UserDefaults.standard.string(for: .fontName, defaultValue: UserDefaultsDefaults.fontName),
            digitalFont: UserDefaults.standard.string(for: .digitalFont, defaultValue: UserDefaultsDefaults.fontName),
            zeroPosition: UserDefaults.standard.double(for: .zeroPosition)
        )
    }
    
    private func saveConfiguration() {
        UserDefaults.standard.set(configuration.clockStyle, for: .clockStyle)
        UserDefaults.standard.set(configuration.showHourNumbers, for: .showHourNumbers)
        UserDefaults.standard.set(configuration.showMarkers, for: .showMarkers)
        UserDefaults.standard.set(configuration.showIntermediateMarkers, for: .showIntermediateMarkers)
        UserDefaults.standard.set(configuration.showTimeOnlyForActiveTask, for: .showTimeOnlyForActiveTask)
        UserDefaults.standard.set(Double(configuration.taskArcLineWidth), for: .taskArcLineWidth)
        UserDefaults.standard.set(Double(configuration.outerRingLineWidth), for: .outerRingLineWidth)
        UserDefaults.standard.set(configuration.markersWidth, for: .markersWidth)
        UserDefaults.standard.set(configuration.markersOffset, for: .markersOffset)
        UserDefaults.standard.set(configuration.numbersSize, for: .numbersSize)
        UserDefaults.standard.set(configuration.digitalFontSize, for: .digitalFontSize)
        UserDefaults.standard.set(configuration.isAnalogArcStyle, for: .isAnalogArcStyle)
        UserDefaults.standard.set(configuration.markerStyle.rawValue, for: .markerStyle)
        UserDefaults.standard.set(configuration.numberInterval, for: .numberInterval)
        UserDefaults.standard.set(configuration.fontName, for: .fontName)
        UserDefaults.standard.set(configuration.digitalFont, for: .digitalFont)
        UserDefaults.standard.set(configuration.zeroPosition, for: .zeroPosition)
    }
    
    // MARK: - Public Methods
    func resetToDefaults() {
        configuration = .default
    }
    
    func updateZeroPosition(_ position: Double) {
        var updatedConfig = configuration
        updatedConfig.zeroPosition = position
        configuration = updatedConfig
    }
    
    func updateClockStyle(_ style: String) {
        var updatedConfig = configuration
        updatedConfig.clockStyle = style
        configuration = updatedConfig
    }
} 