//
//  RingTimeCalculator.swift
//  TaskFl0w
//
//  Created by Yan on 2/4/25.
//

import Foundation
import SwiftUI

struct RingTimeCalculator {
    // MARK: - Константы для оптимизации производительности
    private static let calendar = Calendar.current
    private static let currentTimeZone = TimeZone.current
    
    // Математические константы
    private static let radiansToDegreesMultiplier = 180.0 / Double.pi
    private static let degreesToHoursMultiplier = 1.0 / 15.0  // 15 градусов = 1 час
    private static let minutesToDegreesMultiplier = 1.0 / 4.0 // 4 минуты = 1 градус
    private static let degreesToMinutesMultiplier = 4.0      // 1 градус = 4 минуты
    private static let minutesPerHour = 60.0
    private static let hoursPerDay = 24.0
    private static let minutesPerDay = 1440.0
    private static let degreesPerCircle = 360.0
    private static let topClockPosition = 270.0
    private static let defaultFallbackAngle = 15.0
    
    // Кэшированные компоненты для повторного использования
    private static let dateComponentsForExtraction: Set<Calendar.Component> = [.hour, .minute]
    private static let dateComponentsForCreation: Set<Calendar.Component> = [.year, .month, .day]
    private static let fullDateComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
    
    // MARK: - Helper методы для проверки NaN
    @inline(__always)
    private static func safeguardNaN(_ value: Double, fallback: Double = 0.0) -> Double {
        return value.isNaN ? fallback : value
    }
    
    @inline(__always)
    private static func safeguardNaN(_ value: CGFloat, fallback: CGFloat = 0.0) -> CGFloat {
        return value.isNaN ? fallback : value
    }
    
    // MARK: - Оптимизированные методы извлечения времени
    private static func extractTimeComponents(from date: Date) -> (hour: Int, minute: Int) {
        let components = calendar.dateComponents(dateComponentsForExtraction, from: date)
        return (components.hour ?? 0, components.minute ?? 0)
    }
    
    static func timeForLocation(
        _ location: CGPoint,
        center: CGPoint,
        baseDate: Date,
        zeroPosition: Double = 0
    ) -> Date {
        let dx = location.x - center.x
        let dy = location.y - center.y
        
        let safeZeroPosition = safeguardNaN(zeroPosition)
        
        // Проверяем, не является ли вектор нулевым (чтобы избежать NaN)
        if dx == 0 && dy == 0 {
            let defaultAngle = (topClockPosition + safeZeroPosition).truncatingRemainder(dividingBy: degreesPerCircle)
            return angleToTime(defaultAngle, baseDate: baseDate, zeroPosition: safeZeroPosition)
        }
        
        let angle = atan2(dy, dx)
        
        // Переводим в градусы и учитываем zeroPosition - оптимизированная версия
        let degrees = ((angle * radiansToDegreesMultiplier - topClockPosition - safeZeroPosition + degreesPerCircle)
                      .truncatingRemainder(dividingBy: degreesPerCircle))
        
        // Конвертируем в часы и минуты
        let hours = degrees * degreesToHoursMultiplier
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * minutesPerHour)
        
        // Создаем дату более эффективно
        var components = calendar.dateComponents(dateComponentsForCreation, from: baseDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = currentTimeZone
        
        return calendar.date(from: components) ?? baseDate
    }
    
    static func calculateAngles(for task: TaskOnRing) -> (start: Angle, end: Angle) {
        // Извлекаем компоненты времени более эффективно
        let (startHour, startMinute) = extractTimeComponents(from: task.startTime)
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let (endHour, endMinute) = extractTimeComponents(from: endTime)
        
        let startMinutes = Double(startHour * 60 + startMinute)
        var endMinutes = Double(endHour * 60 + endMinute)
        
        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += minutesPerDay
        }
        
        // Оптимизированное вычисление углов
        let startAngle = Angle(degrees: topClockPosition + startMinutes * minutesToDegreesMultiplier)
        let endAngle = Angle(degrees: topClockPosition + endMinutes * minutesToDegreesMultiplier)
        
        return (startAngle, endAngle)
    }
    
    // MARK: - Новый метод для расчета углов с учетом zeroPosition
    static func calculateAnglesWithZeroPosition(for task: TaskOnRing, zeroPosition: Double) -> (start: Angle, end: Angle) {
        let (startHour, startMinute) = extractTimeComponents(from: task.startTime)
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let (endHour, endMinute) = extractTimeComponents(from: endTime)
        
        let startMinutes = Double(startHour * 60 + startMinute)
        var endMinutes = Double(endHour * 60 + endMinute)
        
        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += minutesPerDay
        }
        
        let safeZeroPosition = safeguardNaN(zeroPosition)
        
        // Оптимизированное вычисление углов с zeroPosition
        let baseAngle = topClockPosition + safeZeroPosition
        let startAngle = Angle(degrees: baseAngle + startMinutes * minutesToDegreesMultiplier)
        let endAngle = Angle(degrees: baseAngle + endMinutes * minutesToDegreesMultiplier)
        
        return (startAngle, endAngle)
    }
    
    static func calculateMidAngle(start: Angle, end: Angle) -> Angle {
        let safeStartDegrees = safeguardNaN(start.degrees)
        let safeEndDegrees = safeguardNaN(end.degrees, fallback: safeStartDegrees + defaultFallbackAngle)
        
        var midDegrees: Double
        
        // Если дуга "переходит" через 360
        if safeEndDegrees < safeStartDegrees {
            midDegrees = (safeStartDegrees + safeEndDegrees + degreesPerCircle) * 0.5
            if midDegrees >= degreesPerCircle {
                midDegrees -= degreesPerCircle
            }
        } else {
            midDegrees = (safeStartDegrees + safeEndDegrees) * 0.5
        }
        
        return Angle(degrees: midDegrees)
    }
    
    // MARK: - Методы работы со временем и углами с учетом zeroPosition
    
    /// Корректирует время с учетом смещения нулевой позиции
    static func getTimeWithZeroOffset(_ date: Date, baseDate: Date, zeroPosition: Double, inverse: Bool = false) -> Date {
        var components = calendar.dateComponents(fullDateComponents, from: date)
        
        // Получаем часы и минуты более эффективно
        let totalMinutes = Double((components.hour ?? 0) * 60 + (components.minute ?? 0))
        
        // Вычисляем смещение в минутах
        let safeZeroPosition = safeguardNaN(zeroPosition)
        let offsetDegrees = inverse ? -safeZeroPosition : safeZeroPosition
        let offsetMinutes = offsetDegrees * degreesToHoursMultiplier * minutesPerHour
        
        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + minutesPerDay).truncatingRemainder(dividingBy: minutesPerDay)
        
        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / minutesPerHour)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: minutesPerHour))
        
        // Используем компоненты даты из baseDate более эффективно
        let baseComponents = calendar.dateComponents(dateComponentsForCreation, from: baseDate)
        components.year = baseComponents.year
        components.month = baseComponents.month
        components.day = baseComponents.day
        
        return calendar.date(from: components) ?? date
    }
    
    /// Конвертирует угол в время с учетом zeroPosition
    static func angleToTime(_ angle: Double, baseDate: Date, zeroPosition: Double) -> Date {
        var components = calendar.dateComponents(dateComponentsForCreation, from: baseDate)
        
        // Преобразуем угол в минуты - оптимизированная версия
        let safeZeroPosition = safeguardNaN(zeroPosition)
        let totalMinutes = (angle * degreesToMinutesMultiplier + (topClockPosition - safeZeroPosition) * degreesToMinutesMultiplier + minutesPerDay)
            .truncatingRemainder(dividingBy: minutesPerDay)
        
        components.hour = Int(totalMinutes / minutesPerHour)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: minutesPerHour))
        
        return calendar.date(from: components) ?? baseDate
    }
    
    /// Конвертирует время в угол с учетом zeroPosition
    static func timeToAngle(_ date: Date, zeroPosition: Double) -> Double {
        let (hour, minute) = extractTimeComponents(from: date)
        let totalMinutes = Double(hour * 60 + minute)
        
        let safeZeroPosition = safeguardNaN(zeroPosition)
        
        // Преобразуем минуты в угол - оптимизированная версия
        let angle = (totalMinutes * minutesToDegreesMultiplier - (topClockPosition - safeZeroPosition) + degreesPerCircle)
            .truncatingRemainder(dividingBy: degreesPerCircle)
        
        return angle
    }
}
