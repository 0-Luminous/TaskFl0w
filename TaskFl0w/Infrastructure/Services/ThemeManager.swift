import SwiftUI

enum ThemeMode: String, CaseIterable {
    case light = "light"
    case auto = "auto"
    case dark = "dark"
}

final class ThemeManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Constants
    enum Constants {
        static let themeModeKey = "themeMode"
        static let lightModeClockFaceColorKey = "lightModeClockFaceColor"
        static let darkModeClockFaceColorKey = "darkModeClockFaceColor"
        static let lightModeOuterRingColorKey = "lightModeOuterRingColor"
        static let darkModeOuterRingColorKey = "darkModeOuterRingColor"
        static let lightModeMarkersColorKey = "lightModeMarkersColor"
        static let darkModeMarkersColorKey = "darkModeMarkersColor"
    }
    
    // MARK: - Theme Properties
    @Published var currentThemeMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentThemeMode.rawValue, forKey: Constants.themeModeKey)
            updateColorsForCurrentTheme()
            objectWillChange.send()
        }
    }
    
    // Computed property для совместимости с существующим кодом
    var isDarkMode: Bool {
        switch currentThemeMode {
        case .light:
            return false
        case .auto:
            // Автоматически определяем по системной теме
            return UITraitCollection.current.userInterfaceStyle == .dark
        case .dark:
            return true
        }
    }
    
    // MARK: - Clock Colors
    @AppStorage(Constants.lightModeClockFaceColorKey) 
    private var lightModeClockFaceColor: String = Color.white.toHex()
    
    @AppStorage(Constants.darkModeClockFaceColorKey) 
    private var darkModeClockFaceColor: String = Color.white.toHex()
    
    @AppStorage(Constants.lightModeOuterRingColorKey) 
    private var lightModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    
    @AppStorage(Constants.darkModeOuterRingColorKey) 
    private var darkModeOuterRingColor: String = Color.gray.opacity(0.3).toHex()
    
    @AppStorage(Constants.lightModeMarkersColorKey) 
    private var lightModeMarkersColor: String = Color.black.toHex()
    
    @AppStorage(Constants.darkModeMarkersColorKey) 
    private var darkModeMarkersColor: String = Color.white.toHex()
    
    // MARK: - Computed Properties
    var currentClockFaceColor: Color {
        let hexColor = isDarkMode ? darkModeClockFaceColor : lightModeClockFaceColor
        return Color(hex: hexColor) ?? (isDarkMode ? .black : .white)
    }
    
    var currentOuterRingColor: Color {
        let hexColor = isDarkMode ? darkModeOuterRingColor : lightModeOuterRingColor
        return Color(hex: hexColor) ?? .gray.opacity(0.3)
    }
    
    var currentMarkersColor: Color {
        let hexColor = isDarkMode ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }
    
    // MARK: - Initialization
    private init() {
        let savedThemeMode = UserDefaults.standard.string(forKey: Constants.themeModeKey) ?? ThemeMode.auto.rawValue
        self.currentThemeMode = ThemeMode(rawValue: savedThemeMode) ?? .auto
        
        // Подписываемся на изменения системной темы для автоматического режима
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    func updateColor(_ color: Color, for key: String) {
        switch key {
        case Constants.lightModeClockFaceColorKey:
            lightModeClockFaceColor = color.toHex()
        case Constants.darkModeClockFaceColorKey:
            darkModeClockFaceColor = color.toHex()
        case Constants.lightModeOuterRingColorKey:
            lightModeOuterRingColor = color.toHex()
        case Constants.darkModeOuterRingColorKey:
            darkModeOuterRingColor = color.toHex()
        case Constants.lightModeMarkersColorKey:
            lightModeMarkersColor = color.toHex()
        case Constants.darkModeMarkersColorKey:
            darkModeMarkersColor = color.toHex()
        default:
            break
        }
        // Сразу обновляем представления
        objectWillChange.send()
    }
    
    // Методы для обратной совместимости
    func setTheme(_ isDark: Bool) {
        currentThemeMode = isDark ? .dark : .light
    }
    
    func toggleDarkMode() {
        switch currentThemeMode {
        case .light:
            currentThemeMode = .dark
        case .auto:
            currentThemeMode = .dark
        case .dark:
            currentThemeMode = .light
        }
    }
    
    func toggleTheme() {
        switch currentThemeMode {
        case .light:
            currentThemeMode = .auto
        case .auto:
            currentThemeMode = .dark
        case .dark:
            currentThemeMode = .light
        }
    }
    
    func setThemeMode(_ mode: ThemeMode) {
        currentThemeMode = mode
    }
    
    @objc private func systemThemeChanged() {
        if currentThemeMode == .auto {
            objectWillChange.send()
        }
    }
    
    // MARK: - Private Methods
    private func updateColorsForCurrentTheme() {
        // Этот метод гарантирует, что цвета соответствуют текущей теме
        // и все подписчики получат правильные вычисляемые свойства
        let _ = currentClockFaceColor
        let _ = currentOuterRingColor
        let _ = currentMarkersColor
    }
} 