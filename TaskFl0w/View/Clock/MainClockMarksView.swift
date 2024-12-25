import SwiftUI

struct MainClockMarksView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<24) { hour in
                MainClockMarkView(hour: hour,
                                  geometry: geometry,
                                  colorScheme: colorScheme)
            }
        }
    }
}

struct MainClockMarkView: View {
    let hour: Int
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    
    var body: some View {
        Group {
            clockMarkLine
            clockMarkText
        }
    }
    
    private var clockMarkLine: some View {
        Path { path in
            // hour идёт в диапазоне 0...23
            // 0 часов = 0 * π/12 = 0, но по сути 0 здесь = самый верх,
            // а вам нужно поворот относительно "12 часов" и т.д.
            let angle = CGFloat(hour) * .pi / 12
            let length: CGFloat = hour % 3 == 0 ? 15 : 10
            let start = startPoint(angle: angle, length: length)
            let end = endPoint(angle: angle)
            
            path.move(to: start)
            path.addLine(to: end)
        }
        .stroke(
            colorScheme == .dark ? Color.white : Color.black,
            lineWidth: hour % 3 == 0 ? 2 : 1
        )
    }
    
    private func startPoint(angle: CGFloat, length: CGFloat) -> CGPoint {
        CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2 - length) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2 - length) * sin(angle)
        )
    }
    
    private func endPoint(angle: CGFloat) -> CGPoint {
        CGPoint(
            x: geometry.size.width / 2 + (geometry.size.width / 2) * cos(angle),
            y: geometry.size.height / 2 + (geometry.size.width / 2) * sin(angle)
        )
    }
    
    private var clockMarkText: some View {
        // Текст "часов"
        let angle = CGFloat(hour) * .pi / 12 + .pi / 2
        let radius = geometry.size.width / 2 - 30
        let xPosition = geometry.size.width / 2 + radius * cos(angle)
        let yPosition = geometry.size.height / 2 + radius * sin(angle)
        
        return Text("\(hour)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .position(x: xPosition, y: yPosition)
    }
}
