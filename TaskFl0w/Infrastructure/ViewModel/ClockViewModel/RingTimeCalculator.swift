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
        let angle = atan2(vector.dy, vector.dx)

        // Переводим в градусы и учитываем zeroPosition
        var degrees = angle * 180 / .pi
        degrees = (degrees - 90 - zeroPosition + 360).truncatingRemainder(dividingBy: 360)

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

        let startMinutes = startHour * 60 + startMinute
        var endMinutes = endHour * 60 + endMinute

        // Если задача идёт за полночь
        if endMinutes < startMinutes {
            endMinutes += 24 * 60
        }

        // 24 часа = 1440 минут => 360 градусов
        let startAngle = Angle(degrees: 90 + Double(startMinutes) / 4)
        let endAngle = Angle(degrees: 90 + Double(endMinutes) / 4)

        return (startAngle, endAngle)
    }

    static func calculateMidAngle(start: Angle, end: Angle) -> Angle {
        var midDegrees = (start.degrees + end.degrees) / 2
        // Если дуга "переходит" через 360
        if end.degrees < start.degrees {
            midDegrees = (start.degrees + (end.degrees + 360)) / 2
            if midDegrees >= 360 {
                midDegrees -= 360
            }
        }
        return Angle(degrees: midDegrees)
    }
}
