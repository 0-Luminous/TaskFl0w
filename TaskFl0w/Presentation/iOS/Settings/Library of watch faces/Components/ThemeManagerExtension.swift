//
//  ThemeManagerExtension.swift
//  TaskFl0w
//
//  Created by Yan on 7/5/25.
//

import SwiftUI

// MARK: - Расширение для ThemeManager
extension ThemeManager {
    // Геттеры для HEX-значений цветов
    var lightModeClockFaceColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.lightModeClockFaceColorKey) ?? Color.white.toHex()
    }
    
    var darkModeClockFaceColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.darkModeClockFaceColorKey) ?? Color.black.toHex()
    }
    
    var lightModeOuterRingColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.lightModeOuterRingColorKey) ?? Color.gray.opacity(0.3).toHex()
    }
    
    var darkModeOuterRingColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.darkModeOuterRingColorKey) ?? Color.gray.opacity(0.3).toHex()
    }
    
    var lightModeMarkersColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.lightModeMarkersColorKey) ?? Color.black.toHex()
    }
    
    var darkModeMarkersColorHex: String {
        return UserDefaults.standard.string(forKey: Constants.darkModeMarkersColorKey) ?? Color.white.toHex()
    }
} 