import SwiftUI

final class ClockMarkersViewModel: ObservableObject {
    // MARK: - Published properties
    @Published var showHourNumbers: Bool = true
    @Published var lightModeMarkersColor: String = Color.gray.toHex()
    @Published var darkModeMarkersColor: String = Color.gray.toHex()
    @Published var markersWidth: Double = 2.0
    @Published var markersOffset: Double = 40.0
    @Published var numbersSize: Double = 12.0
    @Published var zeroPosition: Double = 0.0
    @Published var isDarkMode: Bool = false

    // MARK: - Environment
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Computed properties
    var currentMarkersColor: Color {
        let hexColor = isDarkMode ? darkModeMarkersColor : lightModeMarkersColor
        return Color(hex: hexColor) ?? .gray
    }

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

        let radius = geometry.size.width / 2 - 30
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
        -(UIScreen.main.bounds.width * 0.35 - markersOffset)
    }
}
