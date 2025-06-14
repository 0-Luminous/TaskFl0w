import SwiftUI
import Combine
import OSLog
import UIKit

// MARK: - Theme Mode
enum ThemeMode: String, CaseIterable {
    case light = "light"
    case auto = "auto"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .light: return "Светлая"
        case .auto: return "Авто"
        case .dark: return "Темная"
        }
    }
}

// MARK: - Theme Color Scheme
struct ThemeColorScheme {
    let clockFace: Color
    let outerRing: Color
    let markers: Color
    let hand: Color
    let digitalFont: Color
    
    static let light = ThemeColorScheme(
        clockFace: .white,
        outerRing: .gray.opacity(0.3),
        markers: .black,
        hand: .blue,
        digitalFont: .gray
    )
    
    static let dark = ThemeColorScheme(
        clockFace: .black,
        outerRing: .gray.opacity(0.3),
        markers: .white,
        hand: .blue,
        digitalFont: .white
    )
}

// MARK: - Theme Color Type
enum ThemeColorType: String, CaseIterable {
    case clockFace = "clockFace"
    case outerRing = "outerRing"
    case markers = "markers"
    case hand = "hand"
    case digitalFont = "digitalFont"
    
    var lightModeKey: String {
        switch self {
        case .clockFace: return "lightModeClockFaceColor"
        case .outerRing: return "lightModeOuterRingColor"
        case .markers: return "lightModeMarkersColor"
        case .hand: return "lightModeHandColor"
        case .digitalFont: return "lightModeDigitalFontColor"
        }
    }
    
    var darkModeKey: String {
        switch self {
        case .clockFace: return "darkModeClockFaceColor"
        case .outerRing: return "darkModeOuterRingColor"
        case .markers: return "darkModeMarkersColor"
        case .hand: return "darkModeHandColor"
        case .digitalFont: return "darkModeDigitalFontColor"
        }
    }
    
    var defaultLightColor: Color {
        switch self {
        case .clockFace: return .white
        case .outerRing: return .gray.opacity(0.3)
        case .markers: return .black
        case .hand: return .blue
        case .digitalFont: return .gray
        }
    }
    
    var defaultDarkColor: Color {
        switch self {
        case .clockFace: return .black
        case .outerRing: return .gray.opacity(0.3)
        case .markers: return .white
        case .hand: return .blue
        case .digitalFont: return .white
        }
    }
}

// MARK: - Theme Manager Protocol
@MainActor
protocol ThemeManagerProtocol: ObservableObject {
    var currentThemeMode: ThemeMode { get set }
    var isDarkMode: Bool { get }
    var currentColorScheme: ThemeColorScheme { get }
    
    func updateColor(_ color: Color, for type: ThemeColorType, in mode: ThemeMode)
    func getColor(for type: ThemeColorType, in mode: ThemeMode) -> Color
    func resetToDefaults()
}

// MARK: - Theme Manager Implementation
@MainActor
final class ThemeManager: ThemeManagerProtocol {
    // MARK: - Constants
    struct Constants {
        static let lightModeClockFaceColorKey = "lightModeClockFaceColor"
        static let darkModeClockFaceColorKey = "darkModeClockFaceColor"
        static let lightModeOuterRingColorKey = "lightModeOuterRingColor"
        static let darkModeOuterRingColorKey = "darkModeOuterRingColor"
        static let lightModeMarkersColorKey = "lightModeMarkersColor"
        static let darkModeMarkersColorKey = "darkModeMarkersColor"
        static let lightModeHandColorKey = "lightModeHandColor"
        static let darkModeHandColorKey = "darkModeHandColor"
        static let lightModeDigitalFontColorKey = "lightModeDigitalFontColor"
        static let darkModeDigitalFontColorKey = "darkModeDigitalFontColor"
    }
    
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "TaskFl0w", category: "Theme")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var currentThemeMode: ThemeMode {
        didSet {
            guard self.currentThemeMode != oldValue else { return }
            persistThemeMode()
            logger.info("Тема изменена на: \(self.currentThemeMode.displayName)")
        }
    }
    
    // MARK: - Computed Properties
    var isDarkMode: Bool {
        switch currentThemeMode {
        case .light: return false
        case .dark: return true
        case .auto: return UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    var currentColorScheme: ThemeColorScheme {
        return ThemeColorScheme(
            clockFace: getCurrentColor(for: .clockFace),
            outerRing: getCurrentColor(for: .outerRing),
            markers: getCurrentColor(for: .markers),
            hand: getCurrentColor(for: .hand),
            digitalFont: getCurrentColor(for: .digitalFont)
        )
    }
    
    // Legacy computed properties for backward compatibility
    var currentClockFaceColor: Color { getCurrentColor(for: .clockFace) }
    var currentOuterRingColor: Color { getCurrentColor(for: .outerRing) }
    var currentMarkersColor: Color { getCurrentColor(for: .markers) }
    var currentHandColor: Color { getCurrentColor(for: .hand) }
    var currentDigitalFontColor: Color { getCurrentColor(for: .digitalFont) }

    // MARK: - Initialization
    private init() {
        let savedThemeMode = UserDefaults.standard.string(forKey: "themeMode") ?? ThemeMode.auto.rawValue
        self.currentThemeMode = ThemeMode(rawValue: savedThemeMode) ?? .auto
        
        setupSystemThemeObserver()
        logger.info("ThemeManager инициализирован с темой: \(self.currentThemeMode.displayName)")
    }
    
    // MARK: - Private Methods
    private func setupSystemThemeObserver() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleSystemThemeChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleSystemThemeChange() {
        guard self.currentThemeMode == .auto else { return }
        objectWillChange.send()
        logger.info("Системная тема изменилась, обновляем UI")
    }
    
    private func persistThemeMode() {
        UserDefaults.standard.set(currentThemeMode.rawValue, forKey: "themeMode")
    }
    
    private func getCurrentColor(for type: ThemeColorType) -> Color {
        let key = isDarkMode ? type.darkModeKey : type.lightModeKey
        let defaultColor = isDarkMode ? type.defaultDarkColor : type.defaultLightColor
        
        let hexString = UserDefaults.standard.string(forKey: key) ?? defaultColor.toHex()
        return Color(hex: hexString) ?? defaultColor
    }
    
    // MARK: - Protocol Implementation
    func updateColor(_ color: Color, for type: ThemeColorType, in mode: ThemeMode) {
        let key = (mode == .dark) ? type.darkModeKey : type.lightModeKey
        UserDefaults.standard.set(color.toHex(), forKey: key)
        
        // Сразу обновляем представления если это текущий режим
        if (mode == .dark && isDarkMode) || (mode == .light && !isDarkMode) {
            objectWillChange.send()
        }
        
        logger.info("Цвет обновлен: \(type.rawValue) в режиме \(mode.displayName)")
    }
    
    func getColor(for type: ThemeColorType, in mode: ThemeMode) -> Color {
        let key = (mode == .dark) ? type.darkModeKey : type.lightModeKey
        let defaultColor = (mode == .dark) ? type.defaultDarkColor : type.defaultLightColor
        
        let hexString = UserDefaults.standard.string(forKey: key) ?? defaultColor.toHex()
        return Color(hex: hexString) ?? defaultColor
    }
    
    func resetToDefaults() {
        ThemeColorType.allCases.forEach { type in
            UserDefaults.standard.set(type.defaultLightColor.toHex(), forKey: type.lightModeKey)
            UserDefaults.standard.set(type.defaultDarkColor.toHex(), forKey: type.darkModeKey)
        }
        
        currentThemeMode = .auto
        objectWillChange.send()
        logger.info("Настройки темы сброшены к значениям по умолчанию")
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func updateColor(_ color: Color, for key: String) {
        // Мапим старые ключи на новые типы
        switch key {
        case "lightModeClockFaceColor":
            updateColor(color, for: .clockFace, in: .light)
        case "darkModeClockFaceColor":
            updateColor(color, for: .clockFace, in: .dark)
        case "lightModeOuterRingColor":
            updateColor(color, for: .outerRing, in: .light)
        case "darkModeOuterRingColor":
            updateColor(color, for: .outerRing, in: .dark)
        case "lightModeMarkersColor":
            updateColor(color, for: .markers, in: .light)
        case "darkModeMarkersColor":
            updateColor(color, for: .markers, in: .dark)
        case "lightModeHandColor":
            updateColor(color, for: .hand, in: .light)
        case "darkModeHandColor":
            updateColor(color, for: .hand, in: .dark)
        case "lightModeDigitalFontColor":
            updateColor(color, for: .digitalFont, in: .light)
        case "darkModeDigitalFontColor":
            updateColor(color, for: .digitalFont, in: .dark)
        default:
            logger.warning("Неизвестный ключ цвета: \(key)")
        }
    }
    
    func setTheme(_ isDark: Bool) {
        currentThemeMode = isDark ? .dark : .light
    }
    
    func toggleDarkMode() {
        switch currentThemeMode {
        case .light: currentThemeMode = .dark
        case .auto: currentThemeMode = .dark
        case .dark: currentThemeMode = .light
        }
    }
    
    func toggleTheme() {
        switch currentThemeMode {
        case .light: currentThemeMode = .auto
        case .auto: currentThemeMode = .dark
        case .dark: currentThemeMode = .light
        }
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        currentThemeMode = mode
    }
} 

