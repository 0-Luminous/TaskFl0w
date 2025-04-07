import SwiftUI

/// Компонент для отображения числовых значений часов на циферблате
struct HourNumberView: View {
    let hour: Int
    @ObservedObject var viewModel: ClockMarkersViewModel
    let color: Color
    let zeroPosition: Double
    
    // Вычисляемое свойство для получения скорректированного часа с учетом zeroPosition
    private var adjustedHour: Int {
        // Вычисляем сдвиг в часах на основе zeroPosition
        // zeroPosition в градусах, переводим в часы (15 градусов = 1 час)
        let hourShift = Int(zeroPosition / 15.0)

        // Сдвигаем час с учетом hourShift и обеспечиваем корректность (0-23)
        let adjustedHour = (hour - hourShift + 24) % 24

        return adjustedHour
    }
    
    var body: some View {
        Text("\(adjustedHour)")
            .font(.system(size: viewModel.numbersSize))
            .foregroundColor(color)
            .rotationEffect(.degrees(-Double(hour) * (360.0 / 24.0) - zeroPosition))
            .offset(y: viewModel.numberOffset()) // Используем специальный метод для отступа цифр
    }
} 