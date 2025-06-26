//
//  ThemeConfigurationViewModel.swift
//  TaskFl0w
//
//  Created by Yan on 16/06/24.
//

import SwiftUI
import Foundation
import Combine

/// ViewModel для управления темой и конфигурацией UI
@MainActor
final class ThemeConfigurationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isDarkMode = false
    @Published var clockStyle = "Классический" {
        didSet { saveClockStyle() }
    }
    
    // MARK: - AppStorage Properties
    
    @AppStorage("notificationsEnabled") 
    var notificationsEnabled = true
    
    @AppStorage("showTimeOnlyForActiveTask") 
    var showTimeOnlyForActiveTask = false
    
    @AppStorage("isAnalogArcStyle") 
    var isAnalogArcStyle = false
    
    // Colors
    @AppStorage("lightModeHandColor") 
    var lightModeHandColor = "#007AFF" // Color.blue.toHex()
    
    @AppStorage("darkModeHandColor") 
    var darkModeHandColor = "#007AFF" // Color.blue.toHex()
    
    @AppStorage("lightModeDigitalFontColor") 
    var lightModeDigitalFontColor = "#8E8E93" // Color.gray.toHex()
    
    @AppStorage("darkModeDigitalFontColor") 
    var darkModeDigitalFontColor = "#FFFFFF" // Color.white.toHex()
    
    @AppStorage("lightModeClockFaceColor") 
    var lightModeClockFaceColor = "#FFFFFF" // Color.white.toHex()
    
    @AppStorage("darkModeClockFaceColor") 
    var darkModeClockFaceColor = "#000000" // Color.black.toHex()
    
    @AppStorage("lightModeOuterRingColor") 
    var lightModeOuterRingColor = "#8E8E934D" // Color.gray.opacity(0.3).toHex()
    
    @AppStorage("darkModeOuterRingColor") 
    var darkModeOuterRingColor = "#8E8E934D" // Color.gray.opacity(0.3).toHex()
    
    @AppStorage("lightModeMarkersColor") 
    var lightModeMarkersColor = "#8E8E93" // Color.gray.toHex()
        
    @AppStorage("darkModeMarkersColor") 
    var darkModeMarkersColor = "#8E8E93" // Color.gray.toHex()
    
    // Dimensions
    @AppStorage("taskArcLineWidth") 
    private var taskArcLineWidthRaw: Double = 20
    
    @AppStorage("outerRingLineWidth") 
    private var outerRingLineWidthRaw: Double = 20
    
    // Markers
    @AppStorage("showHourNumbers") 
    var showHourNumbers = true
    
    @AppStorage("markersWidth") 
    var markersWidth: Double = 2.0
    
    @AppStorage("markersOffset") 
    var markersOffset: Double = 0.0
    
    @AppStorage("numbersSize") 
    var numbersSize: Double = 16.0
    
    @AppStorage("numberInterval") 
    var numberInterval = 1
    
    @AppStorage("showMarkers") 
    var showMarkers = true
    
    @AppStorage("showIntermediateMarkers") 
    var showIntermediateMarkers = true
    
    // Fonts
    @AppStorage("digitalFont") 
    var digitalFont = "SF Pro"
    
    @AppStorage("fontName") 
    var fontName = "SF Pro"
    
    @AppStorage("digitalFontSize") 
    var digitalFontSizeRaw: Double = 42.0
    
    @AppStorage("markerStyle") 
    private var markerStyleRaw = "lines"
    
    // MARK: - Computed Properties
    
    var taskArcLineWidth: CGFloat {
        get { CGFloat(taskArcLineWidthRaw) }
        set { taskArcLineWidthRaw = Double(newValue) }
    }
    
    var outerRingLineWidth: CGFloat {
        get { CGFloat(outerRingLineWidthRaw) }
        set { outerRingLineWidthRaw = Double(newValue) }
    }
    
    var digitalFontSize: Double {
        get { digitalFontSizeRaw }
        set { digitalFontSizeRaw = newValue }
    }
    
    var markerStyle: MarkerStyle {
        get { MarkerStyle(rawValue: markerStyleRaw) ?? .lines }
        set { markerStyleRaw = newValue.rawValue }
    }
    
    var currentThemeColors: ClockThemeColors {
        ClockThemeColors(
            lightModeHandColor: lightModeHandColor,
            darkModeHandColor: darkModeHandColor,
            lightModeDigitalFontColor: lightModeDigitalFontColor,
            darkModeDigitalFontColor: darkModeDigitalFontColor,
            lightModeClockFaceColor: lightModeClockFaceColor,
            darkModeClockFaceColor: darkModeClockFaceColor,
            lightModeOuterRingColor: lightModeOuterRingColor,
            darkModeOuterRingColor: darkModeOuterRingColor,
            lightModeMarkersColor: lightModeMarkersColor,
            darkModeMarkersColor: darkModeMarkersColor
        )
    }
    
    var currentMarkerSettings: MarkerSettings {
        MarkerSettings(
            width: markersWidth,
            offset: markersOffset,
            numbersSize: numbersSize,
            numberInterval: numberInterval,
            fontName: fontName,
            style: MarkerStyle(rawValue: markerStyleRaw) ?? .lines,
            showHourNumbers: showHourNumbers,
            showMarkers: showMarkers,
            showIntermediateMarkers: showIntermediateMarkers
        )
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.clockStyle = UserDefaults.standard.string(forKey: "clockStyle") ?? "Классический"
        
        setupThemeBindings()
        setupNotifications()
    }
    
    // MARK: - Public Methods
    
    /// Обновляет состояние темы
    func updateThemeState() async {
        let currentThemeIsDark = await getCurrentSystemTheme()
        
        if isDarkMode != currentThemeIsDark {
            isDarkMode = currentThemeIsDark
        }
        
        objectWillChange.send()
    }
    
    /// Применяет настройки циферблата
    func applyWatchFaceSettings() async {
        await refreshAllSettings()
    }
    
    /// Обновляет UI для изменения темы
    func updateUIForThemeChange() {
        Task {
            await updateThemeState()
        }
    }
    
    /// Устанавливает тему
    func setTheme(_ isDark: Bool) {
        isDarkMode = isDark
        UserDefaults.standard.set(isDark, forKey: "isDarkMode")
        objectWillChange.send()
    }
    
    /// Переключает тему
    func toggleTheme() {
        setTheme(!isDarkMode)
    }
    
    /// Обновляет цвет для указанного ключа
    func updateColor(_ color: Color, for key: String) {
        let hexColor = color.toHex()
        
        switch key {
        case "lightModeHandColor":
            lightModeHandColor = hexColor
        case "darkModeHandColor":
            darkModeHandColor = hexColor
        case "lightModeDigitalFontColor":
            lightModeDigitalFontColor = hexColor
        case "darkModeDigitalFontColor":
            darkModeDigitalFontColor = hexColor
        case "lightModeClockFaceColor":
            lightModeClockFaceColor = hexColor
        case "darkModeClockFaceColor":
            darkModeClockFaceColor = hexColor
        case "lightModeOuterRingColor":
            lightModeOuterRingColor = hexColor
        case "darkModeOuterRingColor":
            darkModeOuterRingColor = hexColor
        case "lightModeMarkersColor":
            lightModeMarkersColor = hexColor
        case "darkModeMarkersColor":
            darkModeMarkersColor = hexColor
        default:
            break
        }
        
        objectWillChange.send()
    }
    
    /// Сбрасывает настройки к значениям по умолчанию
    func resetToDefaults() {
        lightModeHandColor = "#007AFF"
        darkModeHandColor = "#007AFF"
        lightModeDigitalFontColor = "#8E8E93"
        darkModeDigitalFontColor = "#FFFFFF"
        lightModeClockFaceColor = "#FFFFFF"
        darkModeClockFaceColor = "#000000"
        lightModeOuterRingColor = "#8E8E934D"
        darkModeOuterRingColor = "#8E8E934D"
        lightModeMarkersColor = "#8E8E93"
        darkModeMarkersColor = "#8E8E93"
        
        taskArcLineWidthRaw = 20
        outerRingLineWidthRaw = 20
        digitalFontSizeRaw = 42.0
        markersWidth = 2.0
        markersOffset = 0.0
        numbersSize = 16.0
        
        digitalFont = "SF Pro"
        fontName = "SF Pro"
        markerStyleRaw = "lines"
        
        showHourNumbers = true
        showMarkers = true
        showIntermediateMarkers = true
        numberInterval = 1
        
        notificationsEnabled = true
        showTimeOnlyForActiveTask = false
        isAnalogArcStyle = false
        
        objectWillChange.send()
    }
    
    /// Обновляет ThemeManager цвета (новый метод)
    func updateThemeManagerColors() async {
        let themeManager = ThemeManager.shared
        let colors = currentThemeColors
        
        guard let lightFaceColor = Color(hex: colors.lightModeClockFaceColor),
              let darkFaceColor = Color(hex: colors.darkModeClockFaceColor),
              let lightRingColor = Color(hex: colors.lightModeOuterRingColor),
              let darkRingColor = Color(hex: colors.darkModeOuterRingColor),
              let lightMarkersColor = Color(hex: colors.lightModeMarkersColor),
              let darkMarkersColor = Color(hex: colors.darkModeMarkersColor) else { return }
        
        themeManager.updateColor(lightFaceColor, for: ThemeManager.Constants.lightModeClockFaceColorKey)
        themeManager.updateColor(darkFaceColor, for: ThemeManager.Constants.darkModeClockFaceColorKey)
        themeManager.updateColor(lightRingColor, for: ThemeManager.Constants.lightModeOuterRingColorKey)
        themeManager.updateColor(darkRingColor, for: ThemeManager.Constants.darkModeOuterRingColorKey)
        themeManager.updateColor(lightMarkersColor, for: ThemeManager.Constants.lightModeMarkersColorKey)
        themeManager.updateColor(darkMarkersColor, for: ThemeManager.Constants.darkModeMarkersColorKey)
        
        await MainActor.run {
            themeManager.objectWillChange.send()
        }
    }
    
    // MARK: - Private Methods
    
    private func setupThemeBindings() {
        $isDarkMode
            .removeDuplicates()
            .sink { [weak self] isDark in
                guard let self = self else { return }
                UserDefaults.standard.set(isDark, forKey: "isDarkMode")
            }
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleClockStyleChange),
            name: NSNotification.Name("ClockStyleDidChange"),
            object: nil
        )
    }
    
    @objc private func handleClockStyleChange(_ notification: Notification) {
        guard let newStyle = notification.userInfo?["clockStyle"] as? String,
              clockStyle != newStyle else { return }
        
        clockStyle = newStyle
    }
    
    private func saveClockStyle() {
        UserDefaults.standard.set(clockStyle, forKey: "clockStyle")
        objectWillChange.send()
    }
    
    private func getCurrentSystemTheme() async -> Bool {
        // Возвращаем текущую тему из UserDefaults
        return UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    private func refreshAllSettings() async {
        await updateThemeManagerColors()
        objectWillChange.send()
        
        NotificationCenter.default.post(
            name: .themeConfigurationUpdated,
            object: self,
            userInfo: ["colors": currentThemeColors, "markerSettings": currentMarkerSettings]
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - ThemeConfigurationProtocol

protocol ThemeConfigurationProtocol: ObservableObject {
    var isDarkMode: Bool { get set }
    var clockStyle: String { get set }
    var currentThemeColors: ClockThemeColors { get }
    var currentMarkerSettings: MarkerSettings { get }
    
    func updateThemeState() async
    func setTheme(_ isDark: Bool)
    func updateColor(_ color: Color, for key: String)
    func resetToDefaults()
}

extension ThemeConfigurationViewModel: ThemeConfigurationProtocol {}

// MARK: - Notification Extensions

extension Notification.Name {
    static let themeConfigurationUpdated = Notification.Name("ThemeConfigurationUpdated")
}