import Combine
import SwiftUI

@MainActor
final class ClockStateManager: ObservableObject {
    // MARK: - Published properties
    @Published var selectedDate: Date = Date()
    @Published var currentDate: Date = Date()

    // MARK: - Services
    private let themeManager = ThemeManager.shared
    private let zeroPositionManager = ZeroPositionManager.shared

    // MARK: - Timer for current time updates
    private var timerCancellable: AnyCancellable?

    // Кэшируем calendar для переиспользования
    private let calendar = Calendar.current

    // Добавьте контроль активности таймера
    private var isActive: Bool = true {
        didSet {
            if isActive {
                startTimeUpdates()
            } else {
                stopTimeUpdates()
            }
        }
    }

    // Кэшируем часто используемые значения
    private var cachedZeroPosition: Double = 0
    private var lastZeroPositionUpdate: Date = Date()

    // Предвычисленные константы
    private let minutesIn24Hours: Double = 1440.0
    private let degreesIn24Hours: Double = 360.0
    private let minutesPerDegree: Double = 4.0  // 1440 / 360
    private let degreesPerHour: Double = 15.0   // 360 / 24

    // Добавьте флаг для пропуска обновлений когда не нужно
    private var needsTimeUpdate: Bool = true

    private let computationQueue = DispatchQueue(label: "clock.computation", qos: .userInitiated)

    // MARK: - Initialization
    init() {
        startTimeUpdates()
    }

    deinit {
        timerCancellable?.cancel()
    }

    // MARK: - Time management
    private func startTimeUpdates() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.needsTimeUpdate else { return }
                self.currentDate = Date()
            }
    }

    private func stopTimeUpdates() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // Методы для паузы/возобновления когда view неактивен
    func pauseUpdates() {
        isActive = false
    }

    func resumeUpdates() {
        isActive = true
    }

    // MARK: - Time conversion methods
    func getTimeWithZeroOffset(_ date: Date, inverse: Bool = false) -> Date {
        // Используем кэшированный calendar вместо Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Получаем часы и минуты
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Вычисляем смещение в минутах, используя предвычисленные константы
        let offsetDegrees = inverse ? -getCurrentZeroPosition() : getCurrentZeroPosition()
        let offsetHours = offsetDegrees / degreesPerHour  // Используем константу
        let offsetMinutes = offsetHours * 60

        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + minutesIn24Hours).truncatingRemainder(
            dividingBy: minutesIn24Hours)

        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / 60)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? date
    }

    // MARK: - Angle conversion methods
    func angleToTime(_ angle: Double) -> Date {
        // Используем кэшированный calendar
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        // Преобразуем угол в минуты, используя предвычисленные константы
        var totalMinutes = angle * minutesPerDegree

        // Учитываем zeroPosition и переводим в 24-часовой формат
        totalMinutes = (totalMinutes + (270 - getCurrentZeroPosition()) * minutesPerDegree + minutesIn24Hours).truncatingRemainder(
            dividingBy: minutesIn24Hours)

        components.hour = Int(totalMinutes / 60)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? selectedDate
    }

    func timeToAngle(_ date: Date) -> Double {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let totalMinutes = Double(components.hour! * 60 + components.minute!)
        
        // Используем предвычисленные константы
        var angle = totalMinutes / minutesPerDegree
        let zeroOffset = 270.0 - getCurrentZeroPosition()
        
        angle = (angle - zeroOffset + degreesIn24Hours).truncatingRemainder(dividingBy: degreesIn24Hours)
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
        degrees = (degrees - 270 - getCurrentZeroPosition() + degreesIn24Hours).truncatingRemainder(
            dividingBy: degreesIn24Hours)

        // Используем предвычисленную константу
        let hours = degrees / degreesPerHour
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)

        // Используем кэшированный calendar
        var components = calendar.dateComponents(
            [.year, .month, .day], from: selectedDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current

        return calendar.date(from: components) ?? selectedDate
    }

    private func getCurrentZeroPosition() -> Double {
        let now = Date()
        // Обновляем кэш только если прошло время или значение изменилось
        if now.timeIntervalSince(lastZeroPositionUpdate) > 1.0 {
            cachedZeroPosition = zeroPositionManager.zeroPosition
            lastZeroPositionUpdate = now
        }
        return cachedZeroPosition
    }

    // Метод для получения всех временных данных за один раз
    struct TimeData {
        let angle: Double
        let adjustedTime: Date
        let components: DateComponents
    }

    func getTimeData(for date: Date) -> TimeData {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let totalMinutes = Double(components.hour! * 60 + components.minute!)
        let angle = totalMinutes / minutesPerDegree
        let adjustedTime = getTimeWithZeroOffset(date)
        
        return TimeData(angle: angle, adjustedTime: adjustedTime, components: components)
    }

    // Убираем проблемный метод complexTimeCalculation
    // Если нужны асинхронные вычисления, добавим конкретные методы:
    
    // MARK: - Utility methods
    func setNeedsTimeUpdate(_ needs: Bool) {
        needsTimeUpdate = needs
    }
    
    // Метод для оптимизированного пакетного обновления
    func batchTimeCalculations(for dates: [Date]) -> [TimeData] {
        return dates.map { getTimeData(for: $0) }
    }
}
