import Combine
import SwiftUI
import UIKit

final class ClockStateManager: ObservableObject {
    // MARK: - Published properties
    @Published var selectedDate: Date = Date()
    @Published var currentDate: Date = Date()

    // MARK: - Theme properties
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("lightModeClockFaceColor") var lightModeClockFaceColor: String = Color.white.toHex()
    @AppStorage("darkModeClockFaceColor") var darkModeClockFaceColor: String = Color.black.toHex()

    // MARK: - Zero position
    @Published var zeroPosition: Double {
        didSet {
            UserDefaults.standard.set(zeroPosition, forKey: "zeroPosition")
        }
    }

    // MARK: - Timer for current time updates
    private var timer: Timer?

    // MARK: - Initialization
    init() {
        // Загружаем сохраненное значение zeroPosition
        self.zeroPosition = UserDefaults.standard.double(forKey: "zeroPosition")

        // Запускаем таймер для обновления текущего времени
        startTimeUpdates()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Time management
    private func startTimeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentDate = Date()
        }
    }

    // MARK: - Zero position management
    func updateZeroPosition(_ newPosition: Double) {
        zeroPosition = newPosition
    }

    // MARK: - Time conversion methods
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Получаем часы и минуты
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Вычисляем смещение в минутах
        let offsetDegrees = inverse ? -zeroPosition : zeroPosition
        let offsetHours = offsetDegrees / 15.0  // 15 градусов = 1 час
        let offsetMinutes = offsetHours * 60

        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + 1440).truncatingRemainder(
            dividingBy: 1440)

        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / 60)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? date
    }

    // MARK: - Angle conversion methods
    func angleToTime(_ angle: Double) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // Преобразуем угол в минуты (360 градусов = 24 часа = 1440 минут)
        var totalMinutes = angle * 4  // angle * (1440 / 360)

        // Учитываем zeroPosition и переводим в 24-часовой формат
        totalMinutes = (totalMinutes + (90 - zeroPosition) * 4 + 1440).truncatingRemainder(
            dividingBy: 1440)

        components.hour = Int(totalMinutes / 60)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? selectedDate
    }

    func timeToAngle(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Преобразуем минуты в угол (1440 минут = 360 градусов)
        var angle = totalMinutes / 4  // totalMinutes * (360 / 1440)

        // Учитываем zeroPosition и 90-градусное смещение (12 часов сверху)
        angle = (angle - (90 - zeroPosition) + 360).truncatingRemainder(dividingBy: 360)

        return angle
    }

    // MARK: - Screen position methods
    func timeForLocation(_ location: CGPoint, screenWidth: CGFloat) -> Date {
        let center = CGPoint(
            x: screenWidth * 0.35,
            y: screenWidth * 0.35)
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)

        let angle = atan2(vector.dy, vector.dx)

        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 - zeroPosition + 360).truncatingRemainder(
            dividingBy: 360)

        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)

        // Используем компоненты из selectedDate
        var components = Calendar.current.dateComponents(
            [.year, .month, .day], from: selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current

        return Calendar.current.date(from: components) ?? selectedDate
    }
}
