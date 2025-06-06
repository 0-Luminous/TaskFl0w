import Foundation

final class LocalizationManager {
    // MARK: - Singleton
    static let shared = LocalizationManager()
    
    private init() {}
    
    // MARK: - Properties
    private let bundle = Bundle.main
    
    // MARK: - Public Methods
    
    /// Получение локализованной строки по ключу
    /// - Parameters:
    ///   - key: Ключ локализации
    ///   - comment: Комментарий для переводчика
    /// - Returns: Локализованная строка
    func localizedString(for key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    /// Получение локализованной строки с параметрами
    /// - Parameters:
    ///   - key: Ключ локализации
    ///   - arguments: Аргументы для подстановки в строку
    /// - Returns: Локализованная строка с подставленными параметрами
    func localizedString(for key: String, arguments: CVarArg...) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String(format: format, arguments: arguments)
    }
    
    /// Получение локализованной строки с именованными параметрами
    /// - Parameters:
    ///   - key: Ключ локализации
    ///   - arguments: Словарь с именованными параметрами
    /// - Returns: Локализованная строка с подставленными параметрами
    func localizedString(for key: String, namedArguments: [String: Any]) -> String {
        var result = NSLocalizedString(key, comment: "")
        for (name, value) in namedArguments {
            result = result.replacingOccurrences(of: "{\(name)}", with: "\(value)")
        }
        return result
    }
    
    /// Получение локализованной строки с форматированием даты
    /// - Parameters:
    ///   - key: Ключ локализации
    ///   - date: Дата для форматирования
    ///   - dateStyle: Стиль форматирования даты
    ///   - timeStyle: Стиль форматирования времени
    /// - Returns: Локализованная строка с отформатированной датой
    func localizedString(for key: String, date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = dateStyle
        dateFormatter.timeStyle = timeStyle
        dateFormatter.locale = Locale.current
        
        let formattedDate = dateFormatter.string(from: date)
        return String(format: NSLocalizedString(key, comment: ""), formattedDate)
    }
    
    /// Получение локализованной строки с форматированием числа
    /// - Parameters:
    ///   - key: Ключ локализации
    ///   - number: Число для форматирования
    ///   - style: Стиль форматирования числа
    /// - Returns: Локализованная строка с отформатированным числом
    func localizedString(for key: String, number: NSNumber, style: NumberFormatter.Style = .decimal) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = style
        numberFormatter.locale = Locale.current
        
        guard let formattedNumber = numberFormatter.string(from: number) else {
            return NSLocalizedString(key, comment: "")
        }
        
        return String(format: NSLocalizedString(key, comment: ""), formattedNumber)
    }
    
    /// Получение локализованной строки с множественным числом
    /// - Parameters:
    ///   - key: Базовый ключ локализации
    ///   - count: Количество для определения формы множественного числа
    /// - Returns: Локализованная строка с правильной формой множественного числа
    func localizedString(for key: String, pluralCount: Int) -> String {
        let format = NSLocalizedString(key, comment: "")
        return String.localizedStringWithFormat(format, pluralCount)
    }
    
    // MARK: - Language Management
    func setLanguage(_ languageCode: String) {
        guard let languageBundle = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: languageBundle) else {
            return
        }
        
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    func currentLanguage() -> String {
        return Locale.current.languageCode ?? "en"
    }
    
    /// Получение списка поддерживаемых языков
    func supportedLanguages() -> [String] {
        return ["en", "ru", "zh-Hans"]
    }
    
    /// Проверка поддерживается ли язык
    func isLanguageSupported(_ languageCode: String) -> Bool {
        return supportedLanguages().contains(languageCode)
    }
    
    /// Установка китайского языка (упрощенный)
    func setChineseSimplified() {
        setLanguage("zh-Hans")
    }
}

// MARK: - Convenience Extensions
extension String {
    /// Локализованная версия строки
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }
    
    /// Локализованная версия строки с параметрами
    func localized(with arguments: CVarArg...) -> String {
        return LocalizationManager.shared.localizedString(for: self, arguments: arguments)
    }
    
    /// Локализованная версия строки с именованными параметрами
    func localized(with namedArguments: [String: Any]) -> String {
        return LocalizationManager.shared.localizedString(for: self, namedArguments: namedArguments)
    }
    
    /// Локализованная версия строки с датой
    func localized(date: Date, dateStyle: DateFormatter.Style = .medium, timeStyle: DateFormatter.Style = .none) -> String {
        return LocalizationManager.shared.localizedString(for: self, date: date, dateStyle: dateStyle, timeStyle: timeStyle)
    }
    
    /// Локализованная версия строки с числом
    func localized(number: NSNumber, style: NumberFormatter.Style = .decimal) -> String {
        return LocalizationManager.shared.localizedString(for: self, number: number, style: style)
    }
    
    /// Локализованная версия строки с множественным числом
    func localized(pluralCount: Int) -> String {
        return LocalizationManager.shared.localizedString(for: self, pluralCount: pluralCount)
    }
} 