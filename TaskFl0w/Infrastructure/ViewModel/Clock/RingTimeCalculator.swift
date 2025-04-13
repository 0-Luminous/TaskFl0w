//
//  RingTimeCalculator.swift
//  TaskFl0w
//
//  Created by Yan on 2/4/25.
//

import Foundation
import SwiftUI

struct RingTimeCalculator {
    static func timeForLocation(
        _ location: CGPoint,
        center: CGPoint,
        baseDate: Date,
        zeroPosition: Double = 0
    ) -> Date {
        let vector = CGVector(dx: location.x - center.x, dy: location.y - center.y)
        
        // Убедимся, что zeroPosition - корректное число
        let safeZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition
        
        // Проверяем, не является ли вектор нулевым (чтобы избежать NaN)
        if vector.dx == 0 && vector.dy == 0 {
            // Если вектор нулевой, возвращаем время, соответствующее верху часов
            // В соответствии с zeroPosition
            let defaultAngle = 270 + safeZeroPosition  // Верх часов
            return angleToTime(defaultAngle.truncatingRemainder(dividingBy: 360), baseDate: baseDate, zeroPosition: safeZeroPosition)
        }
        
        let angle = atan2(vector.dy, vector.dx)

        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 270 - safeZeroPosition + 360).truncatingRemainder(dividingBy: 360)

        // 24 часа = 360 градусов => 1 час = 15 градусов
        let hours = degrees / 15
        let hourComponent = Int(hours)
        let minuteComponent = Int((hours - Double(hourComponent)) * 60)

        var components = Calendar.current.dateComponents([.year, .month, .day], from: baseDate)
        components.hour = hourComponent
        components.minute = minuteComponent
        components.timeZone = TimeZone.current

        return Calendar.current.date(from: components) ?? baseDate
    }

    static func calculateAngles(for task: TaskOnRing) -> (start: Angle, end: Angle) {
        let calendar = Calendar.current

        let startHour = CGFloat(calendar.component(.hour, from: task.startTime))
        let startMinute = CGFloat(calendar.component(.minute, from: task.startTime))
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let endHour = CGFloat(calendar.component(.hour, from: endTime))
        let endMinute = CGFloat(calendar.component(.minute, from: endTime))

        // Проверка на NaN
        let safeStartHour = startHour.isNaN ? 0 : startHour
        let safeStartMinute = startMinute.isNaN ? 0 : startMinute
        let safeEndHour = endHour.isNaN ? safeStartHour + 1 : endHour
        let safeEndMinute = endMinute.isNaN ? 0 : endMinute

        let startMinutes = safeStartHour * 60 + safeStartMinute
        var endMinutes = safeEndHour * 60 + safeEndMinute

        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }

        // 24 часа = 1440 минут => 360 градусов
        // Здесь метод НЕ учитывает zeroPosition потому что весь циферблат поворачивается
        // в родительском компоненте. 270 означает, что 12 часов снизу, а 00 сверху
        let startAngle = Angle(degrees: 270 + Double(startMinutes) / 4)
        let endAngle = Angle(degrees: 270 + Double(endMinutes) / 4)

        return (startAngle, endAngle)
    }

    // MARK: - Новый метод для расчета углов с учетом zeroPosition
    static func calculateAnglesWithZeroPosition(for task: TaskOnRing, zeroPosition: Double) -> (start: Angle, end: Angle) {
        let calendar = Calendar.current

        let startHour = CGFloat(calendar.component(.hour, from: task.startTime))
        let startMinute = CGFloat(calendar.component(.minute, from: task.startTime))
        let endTime = task.startTime.addingTimeInterval(task.duration)
        let endHour = CGFloat(calendar.component(.hour, from: endTime))
        let endMinute = CGFloat(calendar.component(.minute, from: endTime))

        // Проверка на NaN
        let safeStartHour = startHour.isNaN ? 0 : startHour
        let safeStartMinute = startMinute.isNaN ? 0 : startMinute
        let safeEndHour = endHour.isNaN ? safeStartHour + 1 : endHour
        let safeEndMinute = endMinute.isNaN ? 0 : endMinute

        let startMinutes = safeStartHour * 60 + safeStartMinute
        var endMinutes = safeEndHour * 60 + safeEndMinute

        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }

        // Убедимся, что zeroPosition - корректное число
        let safeZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition

        // 24 часа = 1440 минут => 360 градусов
        // Применяем zeroPosition к углам, 270 означает, что 12 часов снизу, а 00 сверху
        let startAngle = Angle(degrees: 270 + Double(startMinutes) / 4 + safeZeroPosition)
        let endAngle = Angle(degrees: 270 + Double(endMinutes) / 4 + safeZeroPosition)

        return (startAngle, endAngle)
    }

    static func calculateMidAngle(start: Angle, end: Angle) -> Angle {
        // Защита от NaN
        let safeStartDegrees = start.degrees.isNaN ? 0.0 : start.degrees
        let safeEndDegrees = end.degrees.isNaN ? safeStartDegrees + 15.0 : end.degrees
        
        var midDegrees = (safeStartDegrees + safeEndDegrees) / 2
        // Если дуга "переходит" через 360
        if safeEndDegrees < safeStartDegrees {
            midDegrees = (safeStartDegrees + (safeEndDegrees + 360)) / 2
            if midDegrees >= 360 {
                midDegrees -= 360
            }
        }
        return Angle(degrees: midDegrees)
    }
    
    // MARK: - Методы работы со временем и углами с учетом zeroPosition
    
    /// Корректирует время с учетом смещения нулевой позиции
    static func getTimeWithZeroOffset(_ date: Date, baseDate: Date, zeroPosition: Double, inverse: Bool = false) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)

        // Получаем часы и минуты
        let totalMinutes = Double(components.hour! * 60 + components.minute!)

        // Вычисляем смещение в минутах
        let safeZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition
        let offsetDegrees = inverse ? -safeZeroPosition : safeZeroPosition
        let offsetHours = offsetDegrees / 15.0  // 15 градусов = 1 час
        let offsetMinutes = offsetHours * 60

        // Применяем смещение с учетом 24-часового цикла
        let adjustedMinutes = (totalMinutes - offsetMinutes + 1440).truncatingRemainder(
            dividingBy: 1440)

        // Конвертируем обратно в часы и минуты
        components.hour = Int(adjustedMinutes / 60)
        components.minute = Int(adjustedMinutes.truncatingRemainder(dividingBy: 60))
        
        // Используем компоненты даты из baseDate
        let baseComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        components.year = baseComponents.year
        components.month = baseComponents.month
        components.day = baseComponents.day

        return calendar.date(from: components) ?? date
    }

    /// Конвертирует угол в время с учетом zeroPosition
    static func angleToTime(_ angle: Double, baseDate: Date, zeroPosition: Double) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        // Преобразуем угол в минуты (360 градусов = 24 часа = 1440 минут)
        var totalMinutes = angle * 4  // angle * (1440 / 360)

        // Учитываем zeroPosition и переводим в 24-часовой формат
        let safeZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition
        totalMinutes = (totalMinutes + (270 - safeZeroPosition) * 4 + 1440).truncatingRemainder(
            dividingBy: 1440)

        components.hour = Int(totalMinutes / 60)
        components.minute = Int(totalMinutes.truncatingRemainder(dividingBy: 60))

        return calendar.date(from: components) ?? baseDate
    }

    /// Конвертирует время в угол с учетом zeroPosition
    static func timeToAngle(_ date: Date, zeroPosition: Double) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        // Защита от некорректных значений
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let totalMinutes = Double(hour * 60 + minute)
        
        // Убедимся, что zeroPosition - корректное число
        let safeZeroPosition = zeroPosition.isNaN ? 0.0 : zeroPosition

        // Преобразуем минуты в угол (1440 минут = 360 градусов)
        var angle = totalMinutes / 4  // totalMinutes * (360 / 1440)

        // Учитываем zeroPosition и 270-градусное смещение (12 часов снизу, 00 сверху)
        angle = (angle - (270 - safeZeroPosition) + 360).truncatingRemainder(dividingBy: 360)

        return angle
    }
}
