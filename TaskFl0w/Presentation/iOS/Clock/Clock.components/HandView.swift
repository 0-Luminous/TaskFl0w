//
//  MainClockHandView.swift
//  TaskFl0w
//
//  Created by Yan on 24/12/24.
//
import SwiftUI

struct ClockHandViewIOS: View {
    
    let currentDate: Date
    let outerRingLineWidth: CGFloat
    @AppStorage("useManualTime") private var useManualTime = false
    @ObservedObject private var themeManager = ThemeManager.shared
    
    // Добавляем свойства для цвета стрелки
    @AppStorage("lightModeHandColor") private var lightModeHandColor: String = Color.blue.toHex()
    @AppStorage("darkModeHandColor") private var darkModeHandColor: String = Color.blue.toHex()
    
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
        let angle = 270 + (Double(hour) * 15 + Double(minute) * 0.25)
        return angle * .pi / 180
    }
    
    private var handColor: Color {
        themeManager.isDarkMode 
            ? Color(hex: darkModeHandColor) ?? .blue 
            : Color(hex: lightModeHandColor) ?? .blue
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2,
                                     y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                let hourHandLength = radius + (outerRingLineWidth / 2) + 20
                let angle = hourAngle
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle)),
                    y: center.y + hourHandLength * CGFloat(sin(angle))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(handColor, lineWidth: 3)
            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
        }
    }
}
