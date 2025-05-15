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
    
    // Добавляем параметры для кастомного цвета стрелки
    var lightModeCustomHandColor: String?
    var darkModeCustomHandColor: String?
    
    // Добавляем параметр масштаба для адаптации длины стрелки
    var scale: CGFloat = 1.0
    
    // Существующие параметры для цвета стрелки
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
        let hexColor: String
        
        if themeManager.isDarkMode {
            hexColor = darkModeCustomHandColor ?? darkModeHandColor
        } else {
            hexColor = lightModeCustomHandColor ?? lightModeHandColor
        }
        
        return Color(hex: hexColor) ?? .blue
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2,
                                     y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                // Используем параметр scale для адаптации длины стрелки
                let hourHandLength = (radius + (outerRingLineWidth / 2) + 20) * scale
                let angle = hourAngle
                let endpoint = CGPoint(
                    x: center.x + hourHandLength * CGFloat(cos(angle)),
                    y: center.y + hourHandLength * CGFloat(sin(angle))
                )
                
                path.move(to: center)
                path.addLine(to: endpoint)
            }
            .stroke(handColor, lineWidth: max(1.5, 3 * scale)) // Также адаптируем толщину стрелки
            .shadow(color: .black.opacity(0.5), radius: max(1, 2 * scale), x: 1, y: 1)
        }
    }
}
