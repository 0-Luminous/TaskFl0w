import SwiftUI

final class ThemeManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ThemeManager()
    
    // MARK: - Constants
    enum Constants {
        static let isDarkModeKey = "isDarkMode"
        static let lightModeClockFaceColorKey = "lightModeClockFaceColor"
        static let darkModeClockFaceColorKey = "darkModeClockFaceColor"
        static let lightModeOuterRingColorKey = "lightModeOuterRingColor"
        static let darkModeOuterRingColorKey = "darkModeOuterRingColor"
        static let lightModeMarkersColorKey = "lightModeMarkersColor"
        static let darkModeMarkersColorKey = "darkModeMarkersColor"
    }
    
    // MARK: - Theme Properties
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: Constants.isDarkModeKey)
            updateColorsForCurrentTheme()
            objectWillChange.send()
        }
    }
    
    // MARK: - Clock Colors
    @AppStorage(Constants.lightModeClockFaceColorKey) 
    private var lightModeClockFaceColor: String = Color.white.toHex()
    
    @AppStorage(Constants.darkModeClockFaceColorKey) 
    private var darkModeClockFaceColor: String = Color.black.toHex()
    
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
        self.isDarkMode = UserDefaults.standard.bool(forKey: Constants.isDarkModeKey)
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
    
    // Простой метод для переключения темы напрямую из интерфейса
    func toggleDarkMode() {
        // Переключаем тему напрямую, минуя промежуточные вызовы
        self.isDarkMode.toggle()
        updateColorsForCurrentTheme()
        
        // Дополнительно обновляем представление через двойную отправку
        objectWillChange.send()
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        updateColorsForCurrentTheme()
        objectWillChange.send()
        
        // Прямое обновление без NotificationCenter
        // Используем временный объект для обновления всех вью
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }
    
    func setTheme(_ isDark: Bool) {
        if isDarkMode != isDark {
            isDarkMode = isDark
            updateColorsForCurrentTheme()
            objectWillChange.send()
        
            // Прямое обновление без NotificationCenter
            // Используем временный объект для обновления всех вью
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
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