import SwiftUI

final class ClockMarkersViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var showHourNumbers: Bool = true
    @Published var lightModeMarkersColor: String = Color.gray.toHex()
    @Published var darkModeMarkersColor: String = Color.gray.toHex()
    @Published var markersWidth: Double = 2.0
    @Published var markersOffset: Double = 0.0
    @Published var numbersSize: Double = 16.0 {
        didSet {
            // Добавляем обработчик для немедленного обновления интерфейса при изменении размера шрифта
            objectWillChange.send()
        }
    }
    @Published var zeroPosition: Double = 0.0
    @Published var numberInterval: Int = 1 // 1, 2, 3 или 6 - интервал отображения цифр
    @Published var isDarkMode: Bool = false {
        didSet {
            // Отправляем уведомление для обновления currentMarkersColor
            updateCurrentThemeColors()
            objectWillChange.send()
        }
    }
    @Published var showMarkers: Bool = true
    @Published var showIntermediateMarkers: Bool = true // Новое свойство для промежуточных маркеров
    @Published var fontName: String = "SF Pro" // или любой дефолтный шрифт
    @Published var markerStyle: MarkerStyle = .lines // Добавляем стиль маркеров
    @Published var digitalFontSize: Double = 42.0 {
        didSet {
            // Принудительно обновляем UI при изменении размера шрифта
            objectWillChange.send()
        }
    }
    @Published var lightModeDigitalFontColor: String = Color.gray.toHex()
    @Published var darkModeDigitalFontColor: String = Color.white.toHex()
    @Published var digitalFont: String = "SF Pro" // Добавляем шрифт для цифрового циферблата
    
    // Список доступных шрифтов с PostScript именами
    let customFonts: [String] = [


 
        "SF Pro",
        "MOSCOW2024",
        "ForestSmooth",
        "Brillant",
        "TDAText",
        "Hussar3dTwo",
        "Minstrels",
        "Letterblocks",
        "cellblocknbp",
        "catstack",
        "Chokokutai-Regular",
        "ElfarNormalG98",
        "Brunothg",
        "pershotravneva55-regular",
        "Daneehand Regular Cyr",
        "NovaCut",
        "UnifrakturCook-Bold",
        "Banana Brick",
        "Cakra-Normal",
        "EternalLent",
        "Vetka",

        "Georgia",
        "Georgia-Bold",

        "Verdana",
        "Verdana-Bold",

        "Trebuchet MS",
        "TrebuchetMS-Bold",
        
        "Futura",
        "Futura-Bold",

        "Gill Sans",
        "GillSans-Bold",

        "Palatino",
        "Palatino-Bold",

        "Menlo",
        "Menlo-Bold",
    ]

    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Computed properties
    var currentMarkersColor: Color {
        let hexColor = isDarkMode ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }

    var currentDigitalFontColor: Color {
        let hexColor = isDarkMode ? darkModeDigitalFontColor : lightModeDigitalFontColor
        return Color(hex: hexColor) ?? (isDarkMode ? .white : .gray)
    }

    // Названия стилей маркеров для отображения в интерфейсе
    var markerStyleNames: [MarkerStyle: String] = [
        .lines: "Линии",
        .dots: "Точки",
        .standard: "Стандартные",
        .classicWatch: "Классические",
        .thinUniform: "Тонкие",
        .hourAccent: "Часовые",
        .uniformDense: "Плотные"
    ]

    // MARK: - Methods
    func startPoint(angle: CGFloat, length: CGFloat, geometry: GeometryProxy) -> CGPoint {
        // Используем angle напрямую, так как сам clockFace будет повернут на zeroPosition
        // (zeroPosition учитывается при отрисовке всего циферблата)
        return CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2 - length) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2 - length) * sin(angle)
        )
    }

    func endPoint(angle: CGFloat, geometry: GeometryProxy) -> CGPoint {
        // Используем angle напрямую, так как сам clockFace будет повернут на zeroPosition
        // (zeroPosition учитывается при отрисовке всего циферблата)
        return CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2) * sin(angle)
        )
    }

    func textPosition(hour: Int, geometry: GeometryProxy) -> (x: CGFloat, y: CGFloat) {
        // Переводим час в угол в радианах (24-часовой циферблат)
        // В 24-часовом циферблате: 1 час = 15 градусов = π/12 радиан
        let hourAngle = CGFloat(hour) * .pi / 12

        // В нормальном циферблате 0 часов наверху, но в системе координат
        // 0 градусов - справа. Поэтому отнимаем π/2 (90 градусов), чтобы 0 было сверху
        let angle = hourAngle - .pi / 2

        let radius = geometry.size.width / 2 - 15
        let xPosition = geometry.size.width / 2 + radius * cos(angle)
        let yPosition = geometry.size.height / 2 + radius * sin(angle)

        return (xPosition, yPosition)
    }

    func markerHeight(for hour: Int) -> CGFloat {
        hour % 6 == 0 ? 16 : 12
    }

    func markerWidth(for hour: Int) -> CGFloat {
        hour % 6 == 0 ? 6 : 4
    }

    func markerOffset() -> CGFloat {
        // Используем относительное значение вместо UIScreen
        -((350 * 0.35) - markersOffset) // 350 как примерный размер экрана
    }

    // Отдельный метод для отступа цифр, не зависящий от толщины маркеров
    func numberOffset() -> CGFloat {
        // Если маркеры скрыты, цифры должны быть дальше от центра
        if !showMarkers {
            // Например, увеличим смещение на 30 (можно подобрать опытным путем)
            return markerOffset() + 5
        }
        // Отступ только на основе markersOffset, без учета толщины
        return markerOffset() + 21
    }

    // Добавляем метод для принудительного обновления представлений при смене темы
    func updateCurrentThemeColors() {
        // Принудительно вызываем обновление вычисляемых свойств и представлений
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // В начале класса ClockMarkersViewModel добавим статический экземпляр
    static let shared = ClockMarkersViewModel()
}
