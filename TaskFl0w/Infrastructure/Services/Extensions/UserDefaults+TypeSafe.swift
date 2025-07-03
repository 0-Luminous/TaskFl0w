//
//  UserDefaults+TypeSafe.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//

import Foundation

// MARK: - UserDefaults Keys
enum UserDefaultsKey: String, CaseIterable {
    // Theme & Colors
    case themeMode = "themeMode"
    case isDarkMode = "isDarkMode"
    case lightModeClockFaceColor = "lightModeClockFaceColor"
    case darkModeClockFaceColor = "darkModeClockFaceColor"
    case lightModeOuterRingColor = "lightModeOuterRingColor"
    case darkModeOuterRingColor = "darkModeOuterRingColor"
    case lightModeMarkersColor = "lightModeMarkersColor"
    case darkModeMarkersColor = "darkModeMarkersColor"
    case lightModeHandColor = "lightModeHandColor"
    case darkModeHandColor = "darkModeHandColor"
    case lightModeDigitalFontColor = "lightModeDigitalFontColor"
    case darkModeDigitalFontColor = "darkModeDigitalFontColor"
    
    // Clock Settings
    case clockStyle = "clockStyle"
    case zeroPosition = "zeroPosition"
    case taskArcLineWidth = "taskArcLineWidth"
    case outerRingLineWidth = "outerRingLineWidth"
    case isAnalogArcStyle = "isAnalogArcStyle"
    
    // Markers & Numbers
    case showHourNumbers = "showHourNumbers"
    case markersWidth = "markersWidth"
    case markersOffset = "markersOffset"
    case numbersSize = "numbersSize"
    case numberInterval = "numberInterval"
    case showMarkers = "showMarkers"
    case markerStyle = "markerStyle"
    case showIntermediateMarkers = "showIntermediateMarkers"
    
    // Fonts
    case fontName = "fontName"
    case digitalFont = "digitalFont"
    case digitalFontSize = "digitalFontSize"
    
    // App Settings
    case notificationsEnabled = "notificationsEnabled"
    case isAppAlreadyLaunchedOnce = "isAppAlreadyLaunchedOnce"
    case isAppSetupCompleted = "isAppSetupCompleted"
    case showTimeOnlyForActiveTask = "showTimeOnlyForActiveTask"
    case reminderTime = "reminderTime"
}

// MARK: - Type-Safe UserDefaults Extension
extension UserDefaults {
    
    // MARK: - Generic Subscript
    subscript<T>(key: UserDefaultsKey) -> T? {
        get { object(forKey: key.rawValue) as? T }
        set { set(newValue, forKey: key.rawValue) }
    }
    
    // MARK: - Convenience Methods
    func set<T>(_ value: T?, for key: UserDefaultsKey) {
        set(value, forKey: key.rawValue)
    }
    
    func value<T>(for key: UserDefaultsKey, defaultValue: T) -> T {
        return object(forKey: key.rawValue) as? T ?? defaultValue
    }
    
    func bool(for key: UserDefaultsKey, defaultValue: Bool = false) -> Bool {
        return object(forKey: key.rawValue) as? Bool ?? defaultValue
    }
    
    func int(for key: UserDefaultsKey, defaultValue: Int = 0) -> Int {
        return object(forKey: key.rawValue) as? Int ?? defaultValue
    }
    
    func double(for key: UserDefaultsKey, defaultValue: Double = 0.0) -> Double {
        return object(forKey: key.rawValue) as? Double ?? defaultValue
    }
    
    func string(for key: UserDefaultsKey, defaultValue: String = "") -> String {
        return string(forKey: key.rawValue) ?? defaultValue
    }
    
    // MARK: - Batch Operations
    func removeAll(keys: [UserDefaultsKey]) {
        keys.forEach { removeObject(forKey: $0.rawValue) }
    }
    
    func reset() {
        UserDefaultsKey.allCases.forEach { removeObject(forKey: $0.rawValue) }
    }
}

// MARK: - Default Values Provider
struct UserDefaultsDefaults {
    static let themeMode = "auto"
    static let clockStyle = "Классический"
    static let fontName = "Nunito"
    static let digitalFontSize: Double = 42.0
    static let markersWidth: Double = 2.0
    static let numbersSize: Double = 16.0
    static let numberInterval: Int = 2
    static let taskArcLineWidth: Double = 20.0
    static let outerRingLineWidth: Double = 20.0
    static let reminderTime: Int = 5 // minutes
} 