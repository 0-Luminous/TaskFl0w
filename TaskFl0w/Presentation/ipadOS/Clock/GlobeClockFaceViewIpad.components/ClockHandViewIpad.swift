//
//  MainClockHandView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockHandViewIpad: View {
    
    let currentDate: Date
    @AppStorage("useManualTime") private var useManualTime = false
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    private var displayDate: Date {
        if useManualTime,
           let manualTime = UserDefaults.standard.object(forKey: "manualTime") as? Date {
            return manualTime
        }
        return currentDate
    }
    
    private var timeComponents: (hour: Int, minute: Int) {
        (
            calendar.component(.hour, from: displayDate),
            calendar.component(.minute, from: displayDate)
        )
    }
    
    private var hourAngle: Double {
        let (hour, minute) = timeComponents
        // hour * 15 градусов на час + minute * 0.25 градуса на минуту
        // При этом 0° — вверх, а у нас 0 часов = слева (90°).
        let angle = 90 + (Double(hour) * 15 + Double(minute) * 0.25)
        return angle * .pi / 180
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2,
                                     y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let hourHandLength = radius * 1.22 // Увеличиваем длину как в iOS версии
                let angle = hourAngle
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle)),
                    y: center.y + hourHandLength * CGFloat(sin(angle))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(Color.blue, lineWidth: 3) // Используем стандартный синий цвет как в iOS
        }
    }
} 